#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

# Defaults
CONFIGURATION_REFERENCE_DEFAULT="unassigned"
REQUEST_REFERENCE_DEFAULT="unassigned"
DEPLOYMENT_MODE_DEFAULT="update"
GENERATION_PROVIDERS_DEFAULT="aws"
GENERATION_FRAMEWORK_DEFAULT="cf"
GENERATION_INPUT_SOURCE_DEFAULT="composite"

arrayFromList GENERATION_PROVIDERS "${GENERATION_PROVIDERS}" ","

function usage() {
  cat <<EOF

Create a CloudFormation (CF) template

Usage: $(basename $0) -l LEVEL -u DEPLOYMENT_UNIT -c CONFIGURATION_REFERENCE -q REQUEST_REFERENCE -r REGION

where

(o) -c CONFIGURATION_REFERENCE is the identifier of the configuration used to generate this template
(o) -g RESOURCE_GROUP          is the deployment unit resource group
(o) -i GENERATION_INPUT_SOURCE is the source of input data to use when generating the template - "composite", "mock"
    -h                         shows this text
(m) -l LEVEL                   is the template level - "unitlist", "blueprint", "account", "segment", "solution" or "application"
(o) -o OUTPUT_DIR              is the directory where the outputs will be saved - defaults to the PRODUCT_STATE_DIR
(o) -q REQUEST_REFERENCE       is an opaque value to link this template to a triggering request management system
(o) -r REGION                  is the AWS region identifier
(m) -u DEPLOYMENT_UNIT         is the deployment unit to be included in the template
(o) -z DEPLOYMENT_UNIT_SUBSET  is the subset of the deployment unit required
(o) -d DEPLOYMENT_MODE         is the deployment mode the template will be generated for
(o) -p GENERATION_PROVIDER     is a provider to load for template generation - multiple providers can be added with extra arguments
(o) -f GENERATION_FRAMEWORK    is the output framework to use for template generation

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

CONFIGURATION_REFERENCE = "${CONFIGURATION_REFERENCE_DEFAULT}"
REQUEST_REFERENCE       = "${REQUEST_REFERENCE_DEFAULT}"
DEPLOYMENT_MODE         = "${DEPLOYMENT_MODE_DEFAULT}"
GENERATION_PROVIDERS    = "${GENERATION_PROVIDERS_DEFAULT}"
GENERATION_FRAMEWORK    = "${GENERATION_FRAMEWORK_DEFAULT}"
GENERATION_INPUT_SOURCE = "${GENRATION_INPUT_SOURCE_DEFAULT}"

NOTES:

1. You must be in the directory specific to the level
2. DEPLOYMENT_UNIT must be one of "s3", "cert", "roles", "apigateway" or "waf" for the "account" level
3. For the "segment" level the "baseline" unit must be deployed before any other unit
4. When deploying network level components in the "segment" level you must deploy vpc before igw, nat, or vpcendpoint

EOF
}

function options() {

  # Parse options
  while getopts ":c:d:f:g:hi:l:o:p:q:r:u:z:" option; do
      case "${option}" in
          c) CONFIGURATION_REFERENCE="${OPTARG}" ;;
          d) DEPLOYMENT_MODE="${OPTARG}" ;;
          f) GENERATION_FRAMEWORK="${OPTARG}" ;;
          g) RESOURCE_GROUP="${OPTARG}" ;;
          h) usage; return 1 ;;
          i) GENERATION_INPUT_SOURCE="${OPTARG}" ;;
          l) LEVEL="${OPTARG}" ;;
          o) OUTPUT_DIR="${OPTARG}" ;;
          p) GENERATION_PROVIDERS+=("${OPTARG}") ;;
          q) REQUEST_REFERENCE="${OPTARG}" ;;
          r) REGION="${OPTARG}" ;;
          u) DEPLOYMENT_UNIT="${OPTARG}" ;;
          z) DEPLOYMENT_UNIT_SUBSET="${OPTARG}" ;;
          \?) fatalOption; return 1 ;;
          :) fatalOptionArgument; return 1 ;;
      esac
  done

  # Defaults
  CONFIGURATION_REFERENCE="${CONFIGURATION_REFERENCE:-${CONFIGURATION_REFERENCE_DEFAULT}}"
  REQUEST_REFERENCE="${REQUEST_REFERENCE:-${REQUEST_REFERENCE_DEFAULT}}"
  DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-${DEPLOYMENT_MODE_DEFAULT}}"
  GENERATION_FRAMEWORK="${GENERATION_FRAMEWORK:-${GENERATION_FRAMEWORK_DEFAULT}}"
  GENERATION_INPUT_SOURCE="${GENERATION_INPUT_SOURCE:-${GENERATION_INPUT_SOURCE_DEFAULT}}"

  if [[ "${#GENERATION_PROVIDERS[@]}" == "0" ]]; then
    GENERATION_PROVIDERS+=("${GENERATION_PROVIDERS_DEFAULT}")
  fi
  GENERATION_PROVIDERS=$(listFromArray "GENERATION_PROVIDERS" ",")

  # Check level and deployment unit
  ! isValidUnit "${LEVEL}" "${DEPLOYMENT_UNIT}" && fatal "Deployment unit/level not valid" &&  return 1

  # Ensure other mandatory arguments have been provided
  if [[ (-z "${REQUEST_REFERENCE}") || (-z "${CONFIGURATION_REFERENCE}") ]]; then
    fatalMandatory
    return 1
  fi

  # Input control for composite/CMDB input
  if [[ "${GENERATION_INPUT_SOURCE}" == "composite" ]]; then


  # Set up the context
  . "${GENERATION_BASE_DIR}/execution/setContext.sh"

    # Ensure we are in the right place
    case "${LEVEL}" in
      account)
        [[ ! ("${LEVEL}" =~ ${LOCATION}) ]] &&
          fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"." && return 1
        ;;

      solution|segment|application|blueprint|unitlist)
        [[ ! ("segment" =~ ${LOCATION}) ]] &&
          fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"." && return 1
        ;;
    esac

    # Add default composite fragments including end fragment
    if [[ (("${GENERATION_USE_CACHE}" != "true")  &&
        ("${GENERATION_USE_FRAGMENTS_CACHE}" != "true")) ||
        (! -f "${CACHE_DIR}/composite_account.ftl") ]]; then

        for composite in "${TEMPLATE_COMPOSITES[@]}"; do

            # only support provision of fragment files via cmdb
            # others can now be provided via the plugin mechanism
            if [[ "${composite}" == "fragment" ]]; then
                for blueprint_alternate_dir in "${blueprint_alternate_dirs[@]}"; do
                    [[ (-z "${blueprint_alternate_dir}") || (! -d "${blueprint_alternate_dir}") ]] && continue
                    for fragment in "${blueprint_alternate_dir}"/${composite}_*.ftl; do
                        fragment_name="$(fileName "${fragment}")"
                        $(inArray "${composite}_array" "${fragment_name}") && continue
                        addToArray "${composite}_array" "${fragment}"
                    done
                done
            fi

            # Legacy fragments
            for fragment in ${GENERATION_DIR}/templates/${composite}/${composite}_*.ftl; do
                $(inArray "${composite}_array" $(fileName "${fragment}")) && continue
                addToArray "${composite}_array" "${fragment}"
            done

            # Legacy end fragments
            for fragment in ${GENERATION_DIR}/templates/${composite}/*end.ftl; do
                $(inArray "${composite}_array" $(fileName "${fragment}")) && continue
                addToArray "${composite}_array" "${fragment}"
            done
        done

        # create the template composites
        for composite in "${TEMPLATE_COMPOSITES[@]}"; do
            namedef_supported &&
            declare -n composite_array="${composite}_array" ||
            eval "declare composite_array=(\"\${${composite}_array[@]}\")"
            debug "${composite^^}=${composite_array[*]}"
            cat "${composite_array[@]}" > "${CACHE_DIR}/composite_${composite}.ftl"
        done

        for composite in "segment" "solution" "application" "id" "name" "policy" "resource"; do
            rm -rf "${CACHE_DIR}/composite_${composite}.ftl"
        done
    fi

    # Assemble settings
    export COMPOSITE_SETTINGS="${CACHE_DIR}/composite_settings.json"
    if [[ (("${GENERATION_USE_CACHE}" != "true") &&
            ("${GENERATION_USE_SETTINGS_CACHE}" != "true")) ||
        (! -f "${COMPOSITE_SETTINGS}") ]]; then
        debug "Generating composite settings ..."
        assemble_settings "${GENERATION_DATA_DIR}" "${COMPOSITE_SETTINGS}" || return $?
    fi

    # Create the composite definitions
    export COMPOSITE_DEFINITIONS="${CACHE_DIR}/composite_definitions.json"
    if [[ (("${GENERATION_USE_CACHE}" != "true") &&
            ("${GENERATION_USE_DEFINITIONS_CACHE}" != "true")) ||
        (! -f "${COMPOSITE_DEFINITIONS}") ]]; then
        assemble_composite_definitions || return $?
    fi

    # Create the composite stack outputs
    export COMPOSITE_STACK_OUTPUTS="${CACHE_DIR}/composite_stack_outputs.json"
    if [[ (("${GENERATION_USE_CACHE}" != "true") &&
            ("${GENERATION_USE_STACK_OUTPUTS_CACHE}" != "true")) ||
        (! -f "${COMPOSITE_STACK_OUTPUTS}") ]]; then
        assemble_composite_stack_outputs || return $?
    fi

  fi

  # Specific intput control for mock input
  if [[ "${GENERATION_INPUT_SOURCE}" == "mock" ]]; then

    if [[ -z "${OUTPUT_DIR}" ]]; then
      fatalMandatory
      return 1
    fi

  fi



  return 0
}

function get_openapi_definition_file() {
  local registry="$1"; shift
  local openapi_zip="$1"; shift
  local id="$1"; shift
  local name="$1"; shift
  local accountId="$1"; shift
  local accountNumber="$1"; shift
  local region="$1"; shift

  pushTempDir "${FUNCNAME[0]}_XXXXXX"
  local openapi_file_dir="$(getTopTempDir)"

  # Name definitions based on the component
  local definition_file="${cf_dir}/defn-${name}-${accountId}-${region}-definition.json"

  local openapi_file="${openapi_file_dir}/${registry}-extended-base.json"
  local legacy_openapi_file="${openapi_file_dir}/${registry}-${region}-${accountNumber}.json"
  local openapi_definition=

  [[ -s "${openapi_zip}" ]] ||
      { fatal "Unable to locate zip file ${openapi_zip}"; popTempDir; return 1; }

  unzip "${openapi_zip}" -d "${openapi_file_dir}"  ||
      { fatal "Unable to unzip zip file ${openapi_zip}"; popTempDir; return 1; }

  # Use existing legacy files in preference to generation as part of deployment
  # This is mainly so projects using the legacy approach are not affected
  # To switch to the new approach, delete the apigw.json from the code repo and
  # move it to the settings entry for the api gateway component in the cmdb. e.g.
  # {
  #    "Integrations" : {
  #      "Internal" : true,
  #      "Value" : ... (existing file contents)
  #    }
  # }
  [[ -f "${openapi_file}"        ]] && openapi_definition="${openapi_file}"
  [[ -f "${legacy_openapi_file}" ]] && openapi_definition="${legacy_openapi_file}"

  [[ -n "${openapi_definition}" ]] ||
      { fatal "Unable to locate ${registry} file in ${openapi_zip}"; popTempDir; return 1; }

  info "Saving ${openapi_definition} to ${definition_file} ..."

  # Index via id to allow definitions to be combined into single composite
  addJSONAncestorObjects "${openapi_definition}" "${id}" > "${openapi_file_dir}/definition.json" ||
      { popTempDir; return 1; }

  cp "${openapi_file_dir}/definition.json" "${definition_file}" ||
      { popTempDir; return 1; }

  popTempDir
  return 0
}


function process_template_pass() {
  local providers="${1,,}"; shift
  local deployment_framework="${1,,}"; shift
  local output_type="${1,,}"; shift
  local output_format="${1,,}"; shift
  local output_suffix="${1,,}"; shift
  local pass="${1,,}"; shift
  local pass_alternative="${1,,}"; shift
  local level="${1,,}"; shift
  local deployment_unit="${1,,}"; shift
  local resource_group="${1,,}"; shift
  local deployment_unit_subset="${1,,}"; shift
  local account="$1"; shift
  local account_region="${1,,}"; shift
  local region="${1,,}"; shift
  local request_reference="${1}"; shift
  local configuration_reference="${1}"; shift
  local deployment_mode="${1}"; shift
  local cf_dir="${1}"; shift
  local run_id="${1,,}"; shift

  # Filename parts
  local level_prefix="${level}-"
  local deployment_unit_prefix="${deployment_unit:+${deployment_unit}-}"
  local account_prefix="${account:+${account}-}"
  local region_prefix="${region:+${region}-}"

  # Set up the level specific template information
  local template_dir="${GENERATION_DIR}/templates"
  local template="create${level^}Template.ftl"
  [[ ! -f "${template_dir}/${template}" ]] && template="create${level^}.ftl"
  local template_composites=()

  # Define the possible passes
  local pass_list=("generationcontract" "testcase" "pregeneration" "prologue" "template" "epilogue" "cli" "parameters" "config")

  # Initialise the components of the pass filenames
  declare -A pass_level_prefix
  declare -A pass_deployment_unit_prefix
  declare -A pass_deployment_unit_subset
  declare -A pass_deployment_unit_subset_prefix
  declare -A pass_account_prefix
  declare -A pass_region_prefix
  declare -A pass_description

  # Defaults
  for p in "${pass_list[@]}"; do
    pass_level_prefix["${p}"]="${level_prefix}"
    pass_deployment_unit_prefix["${p}"]="${deployment_unit_prefix}"
    pass_deployment_unit_subset["${p}"]="${p}"
    pass_deployment_unit_subset_prefix["${p}"]=""
    pass_account_prefix["${p}"]="${account_prefix}"
    pass_region_prefix["${p}"]="${region_prefix}"
    pass_description["${p}"]="${p}"

  done

  # Template pass specifics
  pass_deployment_unit_subset["template"]="${deployment_unit_subset}"
  pass_deployment_unit_subset_prefix["template"]="${deployment_unit_subset:+${deployment_unit_subset}-}"
  pass_description["template"]="cloud formation"

  case "${level}" in

    unitlist)
      # Blueprint applies across accounts and regions
      for p in "${pass_list[@]}"; do
        pass_account_prefix["${p}"]=""
        pass_region_prefix["${p}"]=""
      done

      pass_level_prefix["config"]="unitlist"
      pass_description["config"]="unitlist"
      pass_suffix["config"]=".json"
      ;;

    blueprint)
      template_composites+=("FRAGMENT" )

      # Blueprint applies across accounts and regions
      for p in "${pass_list[@]}"; do
        pass_account_prefix["${p}"]=""
        pass_region_prefix["${p}"]=""
      done

      pass_level_prefix["config"]="blueprint"
      pass_description["config"]="blueprint"
      [[ ${pass} == "config" ]] && output_suffix=".json"
      ;;

    buildblueprint)
      template_composites+=("FRAGMENT" )

      # Blueprint applies across accounts and regions
      for p in "${pass_list[@]}"; do
        pass_account_prefix["${p}"]=""
        pass_region_prefix["${p}"]=""
      done

      pass_level_prefix["config"]="build_blueprint-"
      pass_description["config"]="buildblueprint"
      ;;

    account)
      for p in "${pass_list[@]}"; do pass_region_prefix["${p}"]="${account_region}-"; done
      template_composites+=("ACCOUNT")

      # LEGACY: Support stacks created before deployment units added to account level
      [[ ("${DEPLOYMENT_UNIT}" =~ s3) &&
        (-f "${cf_dir}/${level_prefix}${region_prefix}template.json") ]] && \
          for p in "${pass_list[@]}"; do pass_deployment_unit_prefix["${p}"]=""; done
      ;;

    solution)
      template_composites+=("FRAGMENT")
      if [[ -f "${cf_dir}/solution-${region}-template.json" ]]; then
        for p in "${pass_list[@]}"; do
          pass_deployment_unit_prefix["${p}"]=""
        done
      else
        for p in "${pass_list[@]}"; do
          pass_level_prefix["${p}"]="soln-"
        done
      fi
      ;;

    segment)
      for p in "${pass_list[@]}"; do pass_level_prefix["${p}"]="seg-"; done
      template_composites+=("FRAGMENT" )

      # LEGACY: Support old formats for existing stacks so they can be updated
      if [[ !("${DEPLOYMENT_UNIT}" =~ cmk|cert|dns ) ]]; then
        if [[ -f "${cf_dir}/cont-${deployment_unit_prefix}${region_prefix}template.json" ]]; then
          for p in "${pass_list[@]}"; do pass_level_prefix["${p}"]="cont-"; done
        fi
        if [[ -f "${cf_dir}/container-${region}-template.json" ]]; then
          for p in "${pass_list[@]}"; do
            pass_level_prefix["${p}"]="container-"
            pass_deployment_unit_prefix["${p}"]=""
          done
        fi
        if [[ -f "${cf_dir}/${SEGMENT}-container-template.json" ]]; then
          for p in "${pass_list[@]}"; do
            pass_level_prefix["${p}"]="${SEGMENT}-container-"
            pass_deployment_unit_prefix["${p}"]=""
            pass_region_prefix["${p}"]=""
          done
        fi
      fi
      # "cmk" now used instead of "key"
      [[ ("${DEPLOYMENT_UNIT}" == "cmk") &&
        (-f "${cf_dir}/${level_prefix}key-${region_prefix}template.json") ]] && \
          for p in "${pass_list[@]}"; do pass_deployment_unit_prefix["${p}"]="key-"; done
      ;;

    application)
      for p in "${pass_list[@]}"; do pass_level_prefix["${p}"]="app-"; done
      template_composites+=("FRAGMENT" )
      ;;

    *)
      fatalCantProceed "\"${LEVEL}\" is not one of the known stack levels." && return 1
      ;;
  esac

  # Args common across all passes
  local args=()
  [[ -n "${providers}" ]]                 && args+=("-v" "providers=${providers}")
  [[ -n "${deployment_framework}" ]]      && args+=("-v" "deploymentFramework=${deployment_framework}")
  [[ -n "${GENERATION_MODEL}" ]]          && args+=("-v" "deploymentFrameworkModel=${GENERATION_MODEL}")
  [[ -n "${output_type}" ]]               && args+=("-v" "outputType=${output_type}")
  [[ -n "${output_format}" ]]             && args+=("-v" "outputFormat=${output_format}")
  [[ -n "${deployment_unit}" ]]           && args+=("-v" "deploymentUnit=${deployment_unit}")
  [[ -n "${resource_group}" ]]            && args+=("-v" "resourceGroup=${resource_group}")
  [[ -n "${GENERATION_LOG_LEVEL}" ]]      && args+=("-v" "logLevel=${GENERATION_LOG_LEVEL}")
  [[ -n "${GENERATION_INPUT_SOURCE}" ]]   && args+=("-v" "inputSource=${GENERATION_INPUT_SOURCE}")

  # Include the template composites
  # Removal of drive letter (/?/) is specifically for MINGW
  # It shouldn't affect other platforms as it won't be matched
  for composite in "${template_composites[@]}"; do
    composite_var="COMPOSITE_${composite^^}"
    args+=("-r" "${composite,,}List=${!composite_var#/?/}")
  done

  args+=("-g" "${GENERATION_DATA_DIR}")
  args+=("-v" "region=${region}")
  args+=("-v" "accountRegion=${account_region}")
  args+=("-v" "blueprint=${COMPOSITE_BLUEPRINT}")
  args+=("-v" "settings=${COMPOSITE_SETTINGS}")
  args+=("-v" "definitions=${COMPOSITE_DEFINITIONS}")
  args+=("-v" "stackOutputs=${COMPOSITE_STACK_OUTPUTS}")
  args+=("-v" "requestReference=${request_reference}")
  args+=("-v" "configurationReference=${configuration_reference}")
  args+=("-v" "deploymentMode=${DEPLOYMENT_MODE}")
  args+=("-v" "runId=${run_id}")

  # Directory for temporary files
  local tmp_dir="$(getTopTempDir)"

  # Directory where we gather the results
  # As any file could change, we need to gather them all
  # and copy as a set at the end of processing if a change
  # is detected
  local results_dir="${tmp_dir}/results"

  # No differences seen so far
  local differences_detected="false"

  # Determine output file
  local output_prefix="${pass_level_prefix[${pass}]}${pass_deployment_unit_prefix[${pass}]}${pass_deployment_unit_subset_prefix[${pass}]}${pass_region_prefix[${pass}]}"
  local output_prefix_with_account="${pass_level_prefix[${pass}]}${pass_deployment_unit_prefix[${pass}]}${pass_deployment_unit_subset_prefix[${pass}]}${pass_account_prefix[${pass}]}${pass_region_prefix[${pass}]}"

  [[ -n "${pass_deployment_unit_subset[${pass}]}" ]] && args+=("-v" "deploymentUnitSubset=${pass_deployment_unit_subset[${pass}]}")

  local file_description="${pass_description[${pass}]}"
  info "Generating ${file_description} file ...\n"

  [[ "${pass_alternative}" == "primary" ]] && pass_alternative=""
  pass_alternative_prefix=""
  if [[ -n "${pass_alternative}" ]]; then
    args+=("-v" "alternative=${pass_alternative}")
    pass_alternative_prefix="${pass_alternative}-"
  fi

  local output_filename="${output_prefix}${pass_alternative_prefix}${output_suffix}"
  if [[ ! -f "${cf_dir}/${output_filename}" ]]; then
    # Include account prefix
    local output_filename="${output_prefix_with_account}${pass_alternative_prefix}${output_suffix}"
    local output_prefix="${output_prefix_with_account}"
  fi
  args+=("-v" "outputPrefix=${output_prefix}")

  local template_result_file="${tmp_dir}/${output_filename}"
  local output_file="${cf_dir}/${output_filename}"
  local result_file="${results_dir}/${output_filename}"

      ${GENERATION_BASE_DIR}/execution/freemarker.sh \
        -d "${template_dir}" \
        ${GENERATION_PRE_PLUGIN_DIRS:+ -d "${GENERATION_PRE_PLUGIN_DIRS}"} \
        -d "${GENERATION_BASE_DIR}/engine" \
        -d "${GENERATION_BASE_DIR}/providers" \
        ${GENERATION_PLUGIN_DIRS:+ -d "${GENERATION_PLUGIN_DIRS}"} \
		    -t "${template}" \
        -o "${template_result_file}" \
        "${args[@]}" || return $?

  # Ignore whitespace only files
  if [[ $(tr -d " \t\n\r\f" < "${template_result_file}" | wc -m) -eq 0 ]]; then
    info "Ignoring empty ${file_description} file ...\n"

    # Remove any previous version
    [[ -f "${output_file}" ]] && rm "${output_file}"

    # Indicate template should be ignored
    return 254
  fi

  # Check for fatal strings in the output
  grep "COTFatal:" < "${template_result_file}" > "${template_result_file}-exceptionstrings"
  if [[ -s "${template_result_file}-exceptionstrings"  ]]; then
    fatal "Exceptions occurred during template generation. Details follow...\n"
    case "$(fileExtension "${template_result_file}")" in
      json)
        jq --indent 2 '.' < "${template_result_file}-exceptionstrings" >&2
        ;;
      *)
        cat "${template_result_file}-exceptionstrings" >&2
        ;;
    esac
    return 1
  fi

  case "$(fileExtension "${template_result_file}")" in
    sh)
      # Detect any exceptions during generation
      grep "\[fatal \]" < "${template_result_file}" > "${template_result_file}-exceptions"
      if [[ -s "${template_result_file}-exceptions" ]]; then
        fatal "Exceptions occurred during script generation. Details follow...\n"
        cat "${template_result_file}-exceptions" >&2
        return 1
      fi

      # Capture the result
      cat "${template_result_file}" | sed "-e" 's/^ *//; s/ *$//; /^$/d; /^\s*$/d' > "${result_file}"
      results_list+=("${output_filename}")

      if [[ ! -f "${output_file}" ]]; then
        # First generation
        differences_detected="true"
      else

        # Ignore if only the metadata/timestamps have changed
        sed_patterns=("-e" 's/^ *//; s/ *$//; /^$/d; /^\s*$/d')
        sed_patterns+=("-e" "s/${request_reference}//g")
        sed_patterns+=("-e" "s/${configuration_reference}//g")

        existing_request_reference="$( grep "#--COT-RequestReference=" "${output_file}" )"
        [[ -n "${existing_request_reference}" ]] && sed_patterns+=("-e" "s/${existing_request_reference#"#--COT-RequestReference="}//g")

        existing_configuration_reference="$( grep "#--COT-ConfigurationReference=" "${output_file}" )"
        [[ -n "${existing_configuration_reference}" ]] && sed_patterns+=("-e" "s/${existing_configuration_reference#"#--COT-ConfigurationReference="}//g")

        if [[ "${TREAT_RUN_ID_DIFFERENCES_AS_SIGNIFICANT}" != "true" ]]; then
          sed_patterns+=("-e" "s/${run_id}//g")
          existing_run_id="$( grep "#--COT-RunId=" "${output_file}" )"
          [[ -n "${existing_run_id}" ]] && sed_patterns+=("-e" "s/${existing_run_id#"#--COT-RunId="}//g")
        fi

        cat "${template_result_file}" | sed "${sed_patterns[@]}" > "${template_result_file}-new"
        cat "${output_file}" | sed "${sed_patterns[@]}" > "${template_result_file}-existing"

        diff "${template_result_file}-existing" "${template_result_file}-new" > "${template_result_file}-difference" &&
          info "No change in ${file_description} detected ...\n" ||
          differences_detected="true"

      fi

      if [[ "${pass}" == "pregeneration" ]]; then
        info "Processing pregeneration script ..."
        [[ "${differences_detected}" == "true" ]] &&
          . "${result_file}" ||
          . "${output_file}"
        assemble_composite_definitions
      fi
      ;;

    json)
      # Detect any exceptions during generation
      jq -r ".COTMessages | select(.!=null) | .[] | select(.Severity == \"fatal\")" \
        < "${template_result_file}" > "${template_result_file}-exceptions"
      if [[ -s "${template_result_file}-exceptions" ]]; then
        fatal "Exceptions occurred during template generation. Details follow...\n"
        cat "${template_result_file}-exceptions" >&2
        return 1
      fi

      # Capture the result
      jq --indent 2 '.' < "${template_result_file}" > "${result_file}"
      results_list+=("${output_filename}")

      if [[ ! -f "${output_file}" ]]; then
        # First generation
        differences_detected="true"
      else

        # Ignore if only the metadata/timestamps have changed
        jq_pattern="del(.Metadata)"
        sed_patterns=("-e" "s/${request_reference}//g")
        sed_patterns+=("-e" "s/${configuration_reference}//g")
        sed_patterns+=("-e" "s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z//g")

        existing_request_reference="$( jq -r ".Metadata.RequestReference | select(.!=null)" < "${output_file}" )"
        [[ -z "${existing_request_reference}" ]] && existing_request_reference="$( jq -r ".REQUEST_REFERENCE | select(.!=null)" < "${output_file}" )"
        [[ -n "${existing_request_reference}" ]] && sed_patterns+=("-e" "s/${existing_request_reference}//g")

        existing_configuration_reference="$( jq -r ".Metadata.ConfigurationReference | select(.!=null)" < "${output_file}" )"
        [[ -z "${existing_configuration_reference}" ]] && existing_configuration_reference="$( jq -r ".CONFIGURATION_REFERENCE | select(.!=null)" < "${output_file}" )"
        [[ -n "${existing_configuration_reference}" ]] && sed_patterns+=("-e" "s/${existing_configuration_reference}//g")

        if [[ "${TREAT_RUN_ID_DIFFERENCES_AS_SIGNIFICANT}" != "true" ]]; then
          sed_patterns+=("-e" "s/${run_id}//g")
          existing_run_id="$( jq -r ".Metadata.RunId | select(.!=null)" < "${output_file}" )"
          [[ -z "${existing_run_id}" ]] && existing_run_id="$( jq -r ".RUN_ID | select(.!=null)" < "${output_file}" )"
          [[ -n "${existing_run_id}" ]] && sed_patterns+=("-e" "s/${existing_run_id}//g")
        fi

        cat "${template_result_file}" | jq --indent 1 "${jq_pattern}" | sed "${sed_patterns[@]}" > "${template_result_file}-new"
        cat "${output_file}" | jq --indent 1 "${jq_pattern}" | sed "${sed_patterns[@]}" > "${template_result_file}-existing"

        diff "${template_result_file}-existing" "${template_result_file}-new" > "${template_result_file}-difference" &&
          info "No change in ${file_description} detected ...\n" ||
          differences_detected="true"
      fi
      ;;
  esac

  # Indicate something changed
  if [[ "${differences_detected}" == "true" ]]; then
    return 0
  fi

  # Indicate no change
  return 255
}

function process_template() {
  local level="${1,,}"; shift
  local deployment_unit="${1,,}"; shift
  local resource_group="${1,,}"; shift
  local deployment_unit_subset="${1,,}"; shift
  local account="$1"; shift
  local account_region="${1,,}"; shift
  local region="${1,,}"; shift
  local request_reference="${1}"; shift
  local configuration_reference="${1}"; shift
  local deployment_mode="${1}"; shift

  # Defaults
  local passes=("template")
  local template_alternatives=("primary")

  case "${level}" in

    unitlist|blueprint|buildblueprint)
      local cf_dir_default="${PRODUCT_STATE_DIR}/cot/${ENVIRONMENT}/${SEGMENT}"
      ;;

    account)
      local cf_dir_default="${ACCOUNT_STATE_DIR}/cf/shared"
      ;;

    product)
      local cf_dir_default="${PRODUCT_STATE_DIR}/cf/shared"
      ;;

    solution|segment|application)
      local cf_dir_default="${PRODUCT_STATE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"
      ;;

    *)
      fatalCantProceed "\"${LEVEL}\" is not one of the known stack levels." && return 1
      ;;
  esac

  # Handle >=v2.0.1 cmdb where du/placement subdirectories were introduced for state
  #
  # Assumption is that if files whose names contain the du are not present in
  # the base cf_dir, then the du directory structure should be used
  #
  # This will start to cause the new structure to be created by default for new units,
  # and will accommodate the cmdb update when it is performed.
  case "${level}" in
    unitlist|blueprint|buildblueprint)
      # No subdirectories for deployment units
      ;;
    *)
      readarray -t legacy_files < <(find "${cf_dir_default}" -mindepth 1 -maxdepth 1 -type f -name "*${deployment_unit}*" )

      if [[ (-d "${cf_dir_default}/${deployment_unit}") || "${#legacy_files[@]}" -eq 0 ]]; then
        local cf_dir_default=$(getUnitCFDir "${cf_dir_default}" "${level}" "${deployment_unit}" "" "${region}" )
      fi
      ;;
  esac

  # Permit an override
  cf_dir="${OUTPUT_DIR:-${cf_dir_default}}"

  # Ensure the aws tree for the templates exists
  [[ ! -d ${cf_dir} ]] && mkdir -p ${cf_dir}

  # Create a random string to use as the run identifier
  info "Creating run identifier ...\n"
  run_id="$(dd bs=128 count=1 if=/dev/urandom  | base64 | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 10 | head -n 1)"

  # Directory for temporary files
  pushTempDir "create_template_XXXXXX"
  local tmp_dir="$(getTopTempDir)"

  # Directory where we gather the results
  # As any file could change, we need to gather them all
  # and copy as a set at the end of processing if a change
  # is detected
  local differences_detected="false"
  local results_list=()
  local results_dir="${tmp_dir}/results"
  mkdir -p "${results_dir}"

  # First see if an generation plan can be generated
  process_template_pass \
      "${GENERATION_PROVIDERS}" \
      "${GENERATION_FRAMEWORK}" \
      "contract" \
      "" \
      "generation-contract.json" \
      "generationcontract" \
      "" \
      "${level}" \
      "${deployment_unit}" \
      "${resource_group}" \
      "${deployment_unit_subset}" \
      "${account}" \
      "${account_region}" \
      "${region}" \
      "${request_reference}" \
      "${configuration_reference}" \
      "${deployment_mode}" \
      "${cf_dir}" \
      "${run_id}"
  local result=$?

  if [[ ( ${result} == 0 ) || ( ${result} == 255 ) ]]; then
    local generation_contract="${results_dir}/${results_list[0]}"
    info "Generating documents from generation contract ${generation_contract}"
    willLog "debug" && cat ${generation_contract}

    local task_list_file="$( getTempFile "XXXXXX" "${tmp_dir}" )"
    getTasksFromContract "${generation_contract}" "${task_list_file}" ";"

    local process_template_tasks_file="$( getTempFile "XXXXXX" "${tmp_dir}" )"
    cat "${task_list_file}" | grep "^process_template_pass" > "${process_template_tasks_file}"
    readarray -t process_template_tasks_list < "${process_template_tasks_file}"
  else
    # Need execution plan to define template framework and format
    fatalCantProceed "No execution plan." && return 1
  fi

  # Perform each pass/alternative combination
  for step in "${process_template_tasks_list[@]}"; do

    task_parameter_string="${step#"process_template_pass "}"
    arrayFromList task_parameters "${task_parameter_string}" ";"

    process_template_pass \
      "${task_parameters[@]}" \
      "${level}" \
      "${deployment_unit}" \
      "${resource_group}" \
      "${deployment_unit_subset}" \
      "${account}" \
      "${account_region}" \
      "${region}" \
      "${request_reference}" \
      "${configuration_reference}" \
      "${deployment_mode}" \
      "${cf_dir}" \
      "${run_id}"

    local result=$?
    case ${result} in
      254)
        # Nothing generated
        ;;
      255)
        # No difference
        ;;
      0)
        # At least one difference seen
        differences_detected="true"
        ;;
      *)
        # Fatal error of some description
        return ${result}
    esac
  done

  # Copy the set of result file if necessary
  if [[ "${differences_detected}" == "true" ]]; then
    info "Differences detected ..."
    for f in "${results_list[@]}"; do
      info "Updating "${f}" ..."
      cp "${results_dir}/${f}" "${cf_dir}/${f}"
    done
  else
    info "No differences detected."
  fi

  return 0
}

function main() {

  options "$@" || return $?

  pushTempDir "create_template_XXXXXX"
  tmp_dir="$(getTopTempDir)"
  tmpdir="${tmp_dir}"

  case "${LEVEL}" in
    blueprint-disabled)
      process_template \
        "${LEVEL}" \
        "${DEPLOYMENT_UNIT}" "${RESOURCE_GROUP}" "${DEPLOYMENT_UNIT_SUBSET}" \
        "" "${ACCOUNT_REGION}" \
        "" \
        "${REQUEST_REFERENCE}" \
        "${CONFIGURATION_REFERENCE}" \
        "${DEPLOYMENT_MODE}"
      ;;

    *)
      process_template \
        "${LEVEL}" \
        "${DEPLOYMENT_UNIT}" "${RESOURCE_GROUP}" "${DEPLOYMENT_UNIT_SUBSET}" \
        "${ACCOUNT}" "${ACCOUNT_REGION}" \
        "${REGION}" \
        "${REQUEST_REFERENCE}" \
        "${CONFIGURATION_REFERENCE}" \
        "${DEPLOYMENT_MODE}"
      ;;
  esac
}

main "$@"
