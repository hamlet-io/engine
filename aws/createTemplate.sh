#!/bin/bash

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
(m) -l LEVEL                   is the template level - "account", "product", "segment", "solution", "application" or "multiple"
(m) -q REQUEST_REFERENCE       is an opaque value to link this template to a triggering request management system
(o) -r REGION                  is the AWS region identifier
(d) -s DEPLOYMENT_UNIT         same as -u
(d) -t LEVEL                   same as -l
(m) -u DEPLOYMENT_UNIT         is the deployment unit to be included in the template
(o) -z DEPLOYMENT_UNIT_SUBSET  is the subset of the deployment unit required 

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

CONFIGURATION_REFERENCE = "${CONFIGURATION_REFERENCE_DEFAULT}"
REQUEST_REFERENCE       = "${REQUEST_REFERENCE_DEFAULT}"

NOTES:

1. You must be in the directory specific to the level
2. REGION is only relevant for the "product" level
3. DEPLOYMENT_UNIT may be one of "s3", "cert", "roles", "apigateway" or "waf" for the "account" level
4. DEPLOYMENT_UNIT may be one of "cmk", "cert", "sns" or "shared" for the "product" level
5. DEPLOYMENT_UNIT may be one of "eip", "s3", "cmk", "cert", "vpc" or "dns" for the "segment" level
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
    solution|segment|application|multiple)
      [[ ! ("segment" =~ ${LOCATION}) ]] &&
        fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"." && return 1
      ;;
  esac

  return 0
}

function main() {

  options "$@" || return $?
  
  # Set up the level specific template information
  template_dir="${GENERATION_DIR}/templates"
  template="create${LEVEL^}Template.ftl"
  template_composites=("POLICY" "ID" "NAME" "RESOURCE")
  
  # Determine the template name
  level_prefix="${LEVEL}-"
  deployment_unit_prefix="${DEPLOYMENT_UNIT}-"
  region_prefix="${REGION}-"
  if [[ -n "${DEPLOYMENT_UNIT_SUBSET}" ]]; then
      deployment_unit_subset_prefix="${DEPLOYMENT_UNIT_SUBSET,,}-"
  fi
  case $LEVEL in
    account)
      cf_dir="${ACCOUNT_INFRASTRUCTURE_DIR}/aws/cf"
      region_prefix="${ACCOUNT_REGION}-"
      template_composites+=("ACCOUNT")

      # LEGACY: Support stacks created before deployment units added to account
      [[ ("${DEPLOYMENT_UNIT}" =~ s3) &&
        (-f "${cf_dir}/${level_prefix}${region_prefix}template.json") ]] && \
        deployment_unit_prefix=""
      ;;

    product)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/aws/cf"
      template_composites+=("PRODUCT")

      # LEGACY: Support stacks created before deployment units added to product
      [[ ("${DEPLOYMENT_UNIT}" =~ cmk) &&
        (-f "${cf_dir}/${level_prefix}${region_prefix}template.json") ]] && \
        deployment_unit_prefix=""
      ;;

    solution)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      level_prefix="soln-"
      template_composites+=("SOLUTION" )

      if [[ -f "${cf_dir}/solution-${REGION}-template.json" ]]; then
        level_prefix="solution-"
        deployment_unit_prefix=""
      fi
      ;;

    segment)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      level_prefix="seg-"
      template_composites+=("SEGMENT" "SOLUTION" "APPLICATION" "CONTAINER" )

      # LEGACY: Support old formats for existing stacks so they can be updated 
      if [[ !("${DEPLOYMENT_UNIT}" =~ cmk|cert|dns ) ]]; then
        if [[ -f "${cf_dir}/cont-${deployment_unit_prefix}${region_prefix}template.json" ]]; then
          level_prefix="cont-"
        fi
        if [[ -f "${cf_dir}/container-${REGION}-template.json" ]]; then
          level_prefix="container-"
          deployment_unit_prefix=""
        fi
        if [[ -f "${cf_dir}/${SEGMENT}-container-template.json" ]]; then
          level_prefix="${SEGMENT}-container-"
          deployment_unit_prefix=""
          region_prefix=""
        fi
      fi
      # "cmk" now used instead of "key"
      [[ ("${DEPLOYMENT_UNIT}" == "cmk") &&
        (-f "${cf_dir}/${level_prefix}key-${region_prefix}template.json") ]] && \
          deployment_unit_prefix="key-"
      ;;

    application)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      level_prefix="app-"
      template_composites+=("APPLICATION" "CONTAINER" )
      ;;

    multiple)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      level_prefix="multi-"
      template_composites+=("SEGMENT" "SOLUTION" "APPLICATION" "CONTAINER")
      ;;

    *)
      fatalCantProceed "\"${LEVEL}\" is not one of the known stack levels."
      ;;
  esac
  
  # Define the different subsets
  [[ ("${LEVEL}" == "application") ]] &&
    subsets=("${DEPLOYMENT_UNIT_SUBSET}" "config" "prologue" "epilogue") ||
    subsets=("${DEPLOYMENT_UNIT_SUBSET}")
  output_suffix=("template.json" "config.json" "prologue.sh" "epilogue.sh")
  output_prefix="${level_prefix}${deployment_unit_prefix}${deployment_unit_subset_prefix}${region_prefix}"
  
  # Ensure the aws tree for the templates exists
  [[ ! -d ${cf_dir} ]] && mkdir -p ${cf_dir}
  
  # Args common across all passes
  args=()
  [[ -n "${DEPLOYMENT_UNIT}" ]]        && args+=("-v" "deploymentUnit=${DEPLOYMENT_UNIT}")
  [[ -n "${BUILD_DEPLOYMENT_UNIT}" ]]  && args+=("-v" "buildDeploymentUnit=${BUILD_DEPLOYMENT_UNIT}")
  [[ -n "${BUILD_REFERENCE}" ]]        && args+=("-v" "buildReference=${BUILD_REFERENCE}")
  
  # Include the template composites
  # Removal of drive letter (/?/) is specifically for MINGW
  # It shouldn't affect other platforms as it won't be matched
  for composite in "${template_composites[@]}"; do
    composite_var="COMPOSITE_${composite^^}"
    args+=("-r" "${composite,,}List=${!composite_var#/?/}")
  done
  
  args+=("-v" "region=${REGION}")
  args+=("-v" "productRegion=${PRODUCT_REGION}")
  args+=("-v" "accountRegion=${ACCOUNT_REGION}")
  args+=("-v" "blueprint=${COMPOSITE_BLUEPRINT}")
  args+=("-v" "credentials=${COMPOSITE_CREDENTIALS}")
  args+=("-v" "appsettings=${COMPOSITE_APPSETTINGS}")
  args+=("-v" "stackOutputs=${COMPOSITE_STACK_OUTPUTS}")
  args+=("-v" "requestReference=${REQUEST_REFERENCE}")
  args+=("-v" "configurationReference=${CONFIGURATION_REFERENCE}")

  # Perform each pass
  for pass_index in "${!subsets[@]}"; do

    output_file="${cf_dir}/${output_prefix}${output_suffix[${pass_index}]}"
    temp_output_file="${cf_dir}/temp_${output_prefix}${output_suffix[${pass_index}]}"

    pass_args=("${args[@]}")
    [[ -n "${subsets[${pass_index}]}" ]] && pass_args+=("-v" "deploymentUnitSubset=${subsets[${pass_index}]}")

    ${GENERATION_DIR}/freemarker.sh \
      -d "${template_dir}" -t "${template}" -o "${temp_output_file}" "${pass_args[@]}" || return $?

    # Process the results - ignore whitespace only files
    if [[ $(tr -d " \t\n\r\f" < "${temp_output_file}" | wc -m) -gt 0 ]]; then
      case "$(fileExtension "${temp_output_file}")" in
        sh)
          # Strip out the whitespace added by freemarker
          sed 's/^ *//; s/ *$//; /^$/d; /^\s*$/d' "${temp_output_file}" > "${output_file}"
          ;;
    
        json)
          jq --indent 4 '.' < "${temp_output_file}" > "${output_file}"
          ;;
      esac
    fi
  done

  return 0
}

main "$@"
