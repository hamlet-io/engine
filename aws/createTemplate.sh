#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
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
    return 1
}

function set_context() {

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
  . ${GENERATION_DIR}/validateDeploymentUnit.sh 
  
  # Ensure other mandatory arguments have been provided
  [[ (-z "${REQUEST_REFERENCE}") ||
      (-z "${CONFIGURATION_REFERENCE}") ]] && fatalMandatory
  
  # Set up the context
  . "${GENERATION_DIR}/setContext.sh"
  
  # Ensure we are in the right place
  case $LEVEL in
    account|product)
      [[ ! ("${LEVEL}" =~ ${LOCATION}) ]] &&
        fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"."
      ;;
    solution|segment|application|multiple)
      [[ ! ("segment" =~ ${LOCATION}) ]] &&
        fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"."
      ;;
  esac
}

function main() {

  set_context "$@" || return 1
  
  # Set up the level specific template information
  TEMPLATE_DIR="${GENERATION_DIR}/templates"
  TEMPLATE="create${LEVEL^}Template.ftl"
  TEMPLATE_COMPOSITES=("POLICY" "ID" "NAME" "RESOURCE")
  
  # Determine the template name
  LEVEL_PREFIX="$LEVEL-"
  DEPLOYMENT_UNIT_PREFIX="${DEPLOYMENT_UNIT}-"
  REGION_PREFIX="${REGION}-"
  if [[ -n "${DEPLOYMENT_UNIT_SUBSET}" ]]; then
      DEPLOYMENT_UNIT_SUBSET_PREFIX="${DEPLOYMENT_UNIT_SUBSET,,}-"
  fi
  case $LEVEL in
    account)
      CF_DIR="${ACCOUNT_INFRASTRUCTURE_DIR}/aws/cf"
      REGION_PREFIX="${ACCOUNT_REGION}-"
      TEMPLATE_COMPOSITES+=("ACCOUNT")

      # LEGACY: Support stacks created before deployment units added to account
      if [[ "${DEPLOYMENT_UNIT}" =~ s3 ]]; then
        if [[ -f "${CF_DIR}/${LEVEL_PREFIX}${REGION_PREFIX}template.json" ]]; then
          DEPLOYMENT_UNIT_PREFIX=""
        fi
      fi
      ;;

    product)
      CF_DIR="${PRODUCT_INFRASTRUCTURE_DIR}/aws/cf"
      TEMPLATE_COMPOSITES+=("PRODUCT")

      # LEGACY: Support stacks created before deployment units added to product
      if [[ "${DEPLOYMENT_UNIT}" =~ cmk ]]; then
        if [[ -f "${CF_DIR}/${LEVEL_PREFIX}${REGION_PREFIX}template.json" ]]; then
          DEPLOYMENT_UNIT_PREFIX=""
        fi
      fi
      ;;

    solution)
      CF_DIR="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      LEVEL_PREFIX="soln-"
      TEMPLATE_COMPOSITES+=("SOLUTION" )

      if [[ -f "${CF_DIR}/solution-${REGION}-template.json" ]]; then
        LEVEL_PREFIX="solution-"
        DEPLOYMENT_UNIT_PREFIX=""
      fi
      ;;

    segment)
      CF_DIR="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      LEVEL_PREFIX="seg-"
      TEMPLATE_COMPOSITES+=("SEGMENT" "SOLUTION" "APPLICATION" "CONTAINER" )

      # LEGACY: Support old formats for existing stacks so they can be updated 
      if [[ !("${DEPLOYMENT_UNIT}" =~ cmk|cert|dns ) ]]; then
        if [[ -f "${CF_DIR}/cont-${DEPLOYMENT_UNIT_PREFIX}${REGION_PREFIX}template.json" ]]; then
          LEVEL_PREFIX="cont-"
        fi
        if [[ -f "${CF_DIR}/container-${REGION}-template.json" ]]; then
          LEVEL_PREFIX="container-"
          DEPLOYMENT_UNIT_PREFIX=""
        fi
        if [[ -f "${CF_DIR}/${SEGMENT}-container-template.json" ]]; then
          LEVEL_PREFIX="${SEGMENT}-container-"
          DEPLOYMENT_UNIT_PREFIX=""
          REGION_PREFIX=""
        fi
      fi
      # "cmk" now used instead of "key"
      if [[ "${DEPLOYMENT_UNIT}" == "cmk" ]]; then
        if [[ -f "${CF_DIR}/${LEVEL_PREFIX}key-${REGION_PREFIX}template.json" ]]; then
          DEPLOYMENT_UNIT_PREFIX="key-"
        fi
      fi
      ;;

    application)
      CF_DIR="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      LEVEL_PREFIX="app-"
      TEMPLATE_COMPOSITES+=("APPLICATION" "CONTAINER" )
      ;;

    multiple)
      CF_DIR="${PRODUCT_INFRASTRUCTURE_DIR}/aws/${SEGMENT}/cf"
      LEVEL_PREFIX="multi-"
      TEMPLATE_COMPOSITES+=("SEGMENT" "SOLUTION" "APPLICATION" "CONTAINER")
      ;;

    *)
      fatalCantProceed "\"${LEVEL}\" is not one of the known stack levels."
      ;;
  esac
  
  # Generate the template filename
  OUTPUT="${CF_DIR}/${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}template.json"
  TEMP_OUTPUT="${CF_DIR}/temp_${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}template.json"
  
  # Ensure the aws tree for the templates exists
  [[ ! -d ${CF_DIR} ]] && mkdir -p ${CF_DIR}
  
  ARGS=()
  [[ -n "${DEPLOYMENT_UNIT}" ]]        && ARGS+=("-v" "deploymentUnit=${DEPLOYMENT_UNIT}")
  [[ -n "${DEPLOYMENT_UNIT_SUBSET}" ]] && ARGS+=("-v" "deploymentUnitSubset=${DEPLOYMENT_UNIT_SUBSET}")
  [[ -n "${BUILD_DEPLOYMENT_UNIT}" ]]  && ARGS+=("-v" "buildDeploymentUnit=${BUILD_DEPLOYMENT_UNIT}")
  [[ -n "${BUILD_REFERENCE}" ]]        && ARGS+=("-v" "buildReference=${BUILD_REFERENCE}")
  
  # Include the template composites
  # Removal of drive letter (/?/) is specifically for MINGW
  # It shouldn't affect other platforms as it won't be matched
  for COMPOSITE in "${TEMPLATE_COMPOSITES[@]}"; do
    COMPOSITE_VAR="COMPOSITE_${COMPOSITE^^}"
    ARGS+=("-r" "${COMPOSITE,,}List=${!COMPOSITE_VAR#/?/}")
  done
  
  ARGS+=("-v" "region=${REGION}")
  ARGS+=("-v" "productRegion=${PRODUCT_REGION}")
  ARGS+=("-v" "accountRegion=${ACCOUNT_REGION}")
  ARGS+=("-v" "blueprint=${COMPOSITE_BLUEPRINT}")
  ARGS+=("-v" "credentials=${COMPOSITE_CREDENTIALS}")
  ARGS+=("-v" "appsettings=${COMPOSITE_APPSETTINGS}")
  ARGS+=("-v" "stackOutputs=${COMPOSITE_STACK_OUTPUTS}")
  ARGS+=("-v" "requestReference=${REQUEST_REFERENCE}")
  ARGS+=("-v" "configurationReference=${CONFIGURATION_REFERENCE}")
  
  ${GENERATION_DIR}/freemarker.sh -t ${TEMPLATE} -d ${TEMPLATE_DIR} -o "${TEMP_OUTPUT}" "${ARGS[@]}"
  # Tidy up the result
  RESULT=$? && [[ "${RESULT}" -eq 0 ]] && jq --indent 4 '.' < "${TEMP_OUTPUT}" > "${OUTPUT}"
}

main "$@"
