#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
CONFIGURATION_REFERENCE_DEFAULT="unassigned"
REQUEST_REFERENCE_DEFAULT="unassigned"

function usage() {
  cat <<EOF

Create a CloudFormation (CF) template

Usage: $(basename $0) -l LEVEL -u DEPLOYMENT_UNIT -b BUILD_DEPLOYMENT_UNIT -c CONFIGURATION_REFERENCE -q REQUEST_REFERENCE -r REGION

where

(m) -b BUILD_DEPLOYMENT_UNIT   is the deployment unit defining the build reference
(m) -c CONFIGURATION_REFERENCE is the identifier of the configuration used to generate this template
    -h                         shows this text
(m) -l LEVEL                   is the template level - "blueprint", "account", "product", "segment", "solution", "application" or "multiple"
(m) -q REQUEST_REFERENCE       is an opaque value to link this template to a triggering request management system
(o) -r REGION                  is the AWS region identifier
(d) -s DEPLOYMENT_UNIT         same as -u
(d) -t LEVEL                   same as -l
(o) -u DEPLOYMENT_UNIT         is the deployment unit to be included in the template
(o) -z DEPLOYMENT_UNIT_SUBSET  is the subset of the deployment unit required 

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

CONFIGURATION_REFERENCE = "${CONFIGURATION_REFERENCE_DEFAULT}"
REQUEST_REFERENCE       = "${REQUEST_REFERENCE_DEFAULT}"

NOTES:

1. You must be in the directory specific to the level
2. REGION is only relevant for the "product" level
3. DEPLOYMENT_UNIT must be one of "s3", "cert", "roles", "apigateway" or "waf" for the "account" level
4. DEPLOYMENT_UNIT must be one of "cmk", "cert", "sns" or "shared" for the "product" level
5. DEPLOYMENT_UNIT must be one of "eip", "s3", "cmk", "cert", "vpc" or "dns" for the "segment" level
6. Stack for DEPLOYMENT_UNIT of "eip" or "s3" must be created before stack for "vpc" for the "segment" level
7. Stack for DEPLOYMENT_UNIT of "vpc" must be created before stack for "dns" for the "segment" level
8. To support legacy configurations, the DEPLOYMENT_UNIT combinations "eipvpc" and "eips3vpc" 
   are also supported but for new products, individual templates for each deployment unit 
   should be created

EOF
}

function options() {

  # Parse options
  while getopts ":b:c:hl:q:r:s:t:u:z:" option; do
      case "${option}" in
          b) BUILD_DEPLOYMENT_UNIT="${OPTARG}" ;;
          c) CONFIGURATION_REFERENCE="${OPTARG}" ;;
          h) usage; return 1 ;;
          l) LEVEL="${OPTARG}" ;;
          q) REQUEST_REFERENCE="${OPTARG}" ;;
          r) REGION="${OPTARG}" ;;
          s) DEPLOYMENT_UNIT="${OPTARG}" ;;
          t) LEVEL="${OPTARG}" ;;
          u) DEPLOYMENT_UNIT="${OPTARG}" ;;
          z) DEPLOYMENT_UNIT_SUBSET="${OPTARG}" ;;
          \?) fatalOption; return 1 ;;
          :) fatalOptionArgument; return 1 ;;
      esac
  done
  
  # Defaults
  CONFIGURATION_REFERENCE="${CONFIGURATION_REFERENCE:-${CONFIGURATION_REFERENCE_DEFAULT}}"
  REQUEST_REFERENCE="${REQUEST_REFERENCE:-${REQUEST_REFERENCE_DEFAULT}}"
  
  # Check level and deployment unit
  ! isValidUnit "${LEVEL}" "${DEPLOYMENT_UNIT}" && fatal "Deployment unit/level not valid" && return 1
  
  # Ensure other mandatory arguments have been provided
  [[ (-z "${REQUEST_REFERENCE}") ||
      (-z "${CONFIGURATION_REFERENCE}") ]] && fatalMandatory && return 1
  
  # Set up the context
  . "${GENERATION_DIR}/setContext.sh"
  
  # Ensure we are in the right place
  case "${LEVEL}" in
    account|product)
      [[ ! ("${LEVEL}" =~ ${LOCATION}) ]] &&
        fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"." && return 1
      ;;
    solution|segment|application|multiple|blueprint)
      [[ ! ("segment" =~ ${LOCATION}) ]] &&
        fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"." && return 1
      ;;
  esac

  return 0
}

function process_template() {
  local level="${1,,}"; shift
  local deployment_unit="${1,,}"; shift
  local deployment_unit_subset="${1,,}"; shift
  local account="$1"; shift
  local account_region="${1,,}"; shift
  local product_region="${1,,}"; shift
  local region="${1,,}"; shift
  local build_deployment_unit="${1,,}"; shift
  local build_reference="${1}"; shift
  local request_reference="${1}"; shift
  local configuration_reference="${1}"; shift

  # Filename parts
  local level_prefix="${level}-"
  local deployment_unit_prefix="${deployment_unit:+${deployment_unit}-}"
  local account_prefix="${account:+${account}-}"
  local region_prefix="${region:+${region}-}"

  # Set up the level specific template information
  local template_dir="${GENERATION_DIR}/templates"
  local template="create${level^}Template.ftl"
  [[ ! -f "${template_dir}/${template}" ]] && template="create${level^}.ftl"
  local template_composites=("POLICY" "ID" "NAME" "RESOURCE")
  
  # Define the possible passes
  local pass_list=("prologue" "template" "epilogue" "config")
  
  # Initialise the components of the pass filenames
  declare -A pass_level_prefix
  declare -A pass_deployment_unit_prefix
  declare -A pass_deployment_unit_subset
  declare -A pass_deployment_unit_subset_prefix
  declare -A pass_account_prefix
  declare -A pass_region_prefix
  declare -A pass_description
  declare -A pass_suffix
  declare -A pass_alternatives

  # Defaults
  for pass in "${pass_list[@]}"; do
    pass_level_prefix["${pass}"]="${level_prefix}"
    pass_deployment_unit_prefix["${pass}"]="${deployment_unit_prefix}"
    pass_deployment_unit_subset["${pass}"]="${pass}"
    pass_deployment_unit_subset_prefix["${pass}"]=""
    pass_account_prefix["${pass}"]="${account_prefix}"
    pass_region_prefix["${pass}"]="${region_prefix}"
    pass_description["${pass}"]="${pass}"
    pass_alternatives["${pass}"]="primary"

  done
  pass_suffix=(
    ["prologue"]="prologue.sh"
    ["template"]="template.json"
    ["epilogue"]="epilogue.sh"
    ["config"]="config.json")

  # Template pass specifics
  pass_deployment_unit_subset["template"]="${deployment_unit_subset}"
  pass_deployment_unit_subset_prefix["template"]="${deployment_unit_subset:+${deployment_unit_subset}-}"
  pass_description["template"]="cloud formation"

  # Default passes
  local passes=("prologue" "template" "epilogue")

  local cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"

  case "${level}" in
    blueprint)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/cot/${SEGMENT}/bp"
      pass_list=("template")
      passes=("template")
      template_composites+=("SEGMENT" "SOLUTION" "APPLICATION" "CONTAINER" )

      # Blueprint applies across accounts and regions
      for pass in "${pass_list[@]}"; do
        pass_account_prefix["${pass}"]=""
        pass_region_prefix["${pass}"]=""
      done

      pass_level_prefix["template"]="blueprint"
      pass_description["template"]="blueprint"
      pass_suffix["template"]=".json"
      ;;

    account)
      cf_dir="${ACCOUNT_INFRASTRUCTURE_DIR}/aws/cf"
      for pass in "${pass_list[@]}"; do pass_region_prefix["${pass}"]="${account_region}-"; done
      template_composites+=("ACCOUNT")

      # LEGACY: Support stacks created before deployment units added to account level
      [[ ("${DEPLOYMENT_UNIT}" =~ s3) &&
        (-f "${cf_dir}/${level_prefix}${region_prefix}template.json") ]] && \
          for pass in "${pass_list[@]}"; do pass_deployment_unit_prefix["${pass}"]=""; done
      ;;

    product)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/aws/cf"
      template_composites+=("PRODUCT")

      # LEGACY: Support stacks created before deployment units added to product
      [[ ("${DEPLOYMENT_UNIT}" =~ cmk) &&
        (-f "${cf_dir}/${level_prefix}${region_prefix}template.json") ]] && \
          for pass in "${pass_list[@]}"; do pass_deployment_unit_prefix["${pass}"]=""; done
      ;;

    solution)
      template_composites+=("SOLUTION" )
      passes=("${passes[@]}" "config")
      if [[ -f "${cf_dir}/solution-${region}-template.json" ]]; then
        for pass in "${pass_list[@]}"; do 
          pass_deployment_unit_prefix["${pass}"]="" 
          pass_alternatives["${pass}"]="${pass_alternatives["${pass}"]} replace1 replace2"
        done
      else
        for pass in "${pass_list[@]}"; do 
          pass_level_prefix["${pass}"]="soln-" 
          pass_alternatives["${pass}"]="${pass_alternatives["${pass}"]} replace1 replace2"
        done
      fi
      ;;

    segment)
      for pass in "${pass_list[@]}"; do pass_level_prefix["${pass}"]="seg-"; done
      template_composites+=("SEGMENT" "SOLUTION" "APPLICATION" "CONTAINER" )

      # LEGACY: Support old formats for existing stacks so they can be updated 
      if [[ !("${DEPLOYMENT_UNIT}" =~ cmk|cert|dns ) ]]; then
        if [[ -f "${cf_dir}/cont-${deployment_unit_prefix}${region_prefix}template.json" ]]; then
          for pass in "${pass_list[@]}"; do pass_level_prefix["${pass}"]="cont-"; done
        fi
        if [[ -f "${cf_dir}/container-${region}-template.json" ]]; then
          for pass in "${pass_list[@]}"; do
            pass_level_prefix["${pass}"]="container-"
            pass_deployment_unit_prefix["${pass}"]=""
          done
        fi
        if [[ -f "${cf_dir}/${SEGMENT}-container-template.json" ]]; then
          for pass in "${pass_list[@]}"; do
            pass_level_prefix["${pass}"]="${SEGMENT}-container-"
            pass_deployment_unit_prefix["${pass}"]=""
            pass_region_prefix["${pass}"]=""
          done
        fi
      fi
      # "cmk" now used instead of "key"
      [[ ("${DEPLOYMENT_UNIT}" == "cmk") &&
        (-f "${cf_dir}/${level_prefix}key-${region_prefix}template.json") ]] && \
          for pass in "${pass_list[@]}"; do pass_deployment_unit_prefix["${pass}"]="key-"; done
      ;;

    application)
      for pass in "${pass_list[@]}"; do pass_level_prefix["${pass}"]="app-"; done
      template_composites+=("APPLICATION" "CONTAINER" )
      passes=("${passes[@]}" "config")
      ;;

    multiple)
      for pass in "${pass_list[@]}"; do pass_level_prefix["${pass}"]="multi-"; done
      template_composites+=("SEGMENT" "SOLUTION" "APPLICATION" "CONTAINER")
      ;;

    *)
      fatalCantProceed "\"${LEVEL}\" is not one of the known stack levels."
      ;;
  esac

  # Ensure the aws tree for the templates exists
  [[ ! -d ${cf_dir} ]] && mkdir -p ${cf_dir}

  # Args common across all passes
  args=()
  [[ -n "${deployment_unit}" ]]        && args+=("-v" "deploymentUnit=${deployment_unit}")
  [[ -n "${build_deployment_unit}" ]]  && args+=("-v" "buildDeploymentUnit=${build_deployment_unit}")
  [[ -n "${build_reference}" ]]        && args+=("-v" "buildReference=${build_reference}")
  
  # Create a random string to use as the run identifier
  info "Creating run identifier ...\n"
  run_id="$(dd bs=128 count=1 if=/dev/urandom  | base64 | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 10 | head -n 1)"
  args+=("-v" "runId=${run_id}")

  # Include the template composites
  # Removal of drive letter (/?/) is specifically for MINGW
  # It shouldn't affect other platforms as it won't be matched
  for composite in "${template_composites[@]}"; do
    composite_var="COMPOSITE_${composite^^}"
    args+=("-r" "${composite,,}List=${!composite_var#/?/}")
  done
  
  args+=("-v" "region=${region}")
  args+=("-v" "productRegion=${product_region}")
  args+=("-v" "accountRegion=${account_region}")
  args+=("-v" "blueprint=${COMPOSITE_BLUEPRINT}")
  args+=("-v" "credentials=${COMPOSITE_CREDENTIALS}")
  args+=("-v" "appsettings=${COMPOSITE_APPSETTINGS}")
  args+=("-v" "stackOutputs=${COMPOSITE_STACK_OUTPUTS}")
  args+=("-v" "requestReference=${request_reference}")
  args+=("-v" "configurationReference=${configuration_reference}")

  # Directory for temporary files
  local tmpdir="$(getTempDir "create_template_XXX")"

  # Perform each pass
  for pass in "${passes[@]}"; do

    # Determine output file
    local output_prefix="${pass_level_prefix[${pass}]}${pass_deployment_unit_prefix[${pass}]}${pass_deployment_unit_subset_prefix[${pass}]}${pass_region_prefix[${pass}]}"
    local output_prefix_with_account="${pass_level_prefix[${pass}]}${pass_deployment_unit_prefix[${pass}]}${pass_deployment_unit_subset_prefix[${pass}]}${pass_account_prefix[${pass}]}${pass_region_prefix[${pass}]}"

    pass_args=("${args[@]}")
    [[ -n "${pass_deployment_unit_subset[${pass}]}" ]] && pass_args+=("-v" "deploymentUnitSubset=${pass_deployment_unit_subset[${pass}]}")

    local file_description="${pass_description[${pass}]}"
    info "Generating ${file_description} file ...\n"

    for pass_alternative in ${pass_alternatives["${pass}"]}; do

      [[ "${pass_alternative}" == "primary" ]] && pass_alternative=""
      pass_args+=("-v" "alternative=${pass_alternative}")
      pass_alternative_prefix="${pass_alternative:+${pass_alternative}-}"

      local output_file="${cf_dir}/${output_prefix}${pass_alternative_prefix}${pass_suffix[${pass}]}"
      local template_result_file="${tmpdir}/${output_prefix}${pass_alternative_prefix}${pass_suffix[${pass}]}"
      if [[ ! -f "${output_file}" ]]; then
        # Include account prefix
        local output_file="${cf_dir}/${output_prefix_with_account}${pass_alternative_prefix}${pass_suffix[${pass}]}"
        local template_result_file="${tmpdir}/${output_prefix_with_account}${pass_alternative_prefix}${pass_suffix[${pass}]}"
      fi

      ${GENERATION_DIR}/freemarker.sh \
        -d "${template_dir}" -t "${template}" -o "${template_result_file}" "${pass_args[@]}" || return $?

      # Ignore whitespace only files
      if [[ $(tr -d " \t\n\r\f" < "${template_result_file}" | wc -m) -eq 0 ]]; then
        info "Ignoring empty ${file_description} file ...\n"

        # Remove any previous version
        [[ -f "${output_file}" ]] && rm "${output_file}"

        continue
      fi

      case "$(fileExtension "${template_result_file}")" in
        sh)
          # Strip out the whitespace added by freemarker
          sed 's/^ *//; s/ *$//; /^$/d; /^\s*$/d' "${template_result_file}" > "${output_file}"
          ;;
    
        json)
          # Detect any exceptions during generation
          jq -r ".Exceptions | select(.!=null)" < "${template_result_file}" > "${template_result_file}-exceptions"
          if [[ -s "${template_result_file}-exceptions" ]]; then
            fatal "Exceptions occurred during template generation. Details follow...\n"
            cat "${template_result_file}-exceptions" >&2
            return 1
          fi

          if [[ ! -f "${output_file}" ]]; then
            # First generation - just format
            jq --indent 2 '.' < "${template_result_file}" > "${output_file}"
            continue
          fi

          # Ignore if only the metadata/timestamps have changed
          jq_pattern="del(.Metadata)"
          sed_patterns=("-e" "s/${request_reference}//g")
          sed_patterns+=("-e" "s/${configuration_reference}//g")
          sed_patterns+=("-e" "s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z//g")

          existing_request_reference="$( jq -r ".Metadata.RequestReference | select(.!=null)" < "${output_file}" )"
          [[ -n "${existing_request_reference}" ]] && sed_patterns+=("-e" "s/${existing_request_reference}//g")

          existing_configuration_reference="$( jq -r ".Metadata.ConfigurationReference | select(.!=null)" < "${output_file}" )"
          [[ -n "${existing_configuration_reference}" ]] && sed_patterns+=("-e" "s/${existing_configuration_reference}//g")

          cat "${template_result_file}" | jq --indent 1 "${jq_pattern}" | sed "${sed_patterns[@]}" > "${template_result_file}-new"
          cat "${output_file}" | jq --indent 1 "${jq_pattern}" | sed "${sed_patterns[@]}" > "${template_result_file}-existing"

          diff "${template_result_file}-existing" "${template_result_file}-new" > "${template_result_file}-difference" &&
            info "Ignoring unchanged ${file_description} file ...\n" ||
            jq --indent 2 '.' < "${template_result_file}" > "${output_file}"
          ;;
      esac
    done
  done

  return 0
}

function main() {

  options "$@" || return $?
  
  case "${LEVEL}" in
    blueprint-disabled)
      process_template \
        "${LEVEL}" \
        "${DEPLOYMENT_UNIT}" "${DEPLOYMENT_UNIT_SUBSET}" \
        "" "${ACCOUNT_REGION}" \
        "${PRODUCT_REGION}" \
        "" \
        "${BUILD_DEPLOYMENT_UNIT}" "${BUILD_REFERENCE}" \
        "${REQUEST_REFERENCE}" \
        "${CONFIGURATION_REFERENCE}"
      ;;

    *)
      process_template \
        "${LEVEL}" \
        "${DEPLOYMENT_UNIT}" "${DEPLOYMENT_UNIT_SUBSET}" \
        "${ACCOUNT}" "${ACCOUNT_REGION}" \
        "${PRODUCT_REGION}" \
        "${REGION}" \
        "${BUILD_DEPLOYMENT_UNIT}" "${BUILD_REFERENCE}" \
        "${REQUEST_REFERENCE}" \
        "${CONFIGURATION_REFERENCE}"
      ;;
  esac
}

main "$@"
