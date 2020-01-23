#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

function options() {

  # Parse options
  while getopts ":f:hi:o:p:u:" option; do
      case "${option}" in
          f|i|o|p|u) TEMPLATE_ARGS="${TEMPLATE_ARGS} -${option} ${OPTARG}" ;;
          h) usage; return 1 ;;
          \?) fatalOption; return 1 ;;
      esac
  done

  return 0
}

function usage() {
  cat <<EOF

DESCRIPTION:
  Create a blueprint providing contextual CodeOnTap information for a specifc deployment unit within a solution
  Information is provided based on your segment context

USAGE:
  $(basename $0) -u DEPLOYMENT_UNIT

PARAMETERS:

(o) -f GENERATION_FRAMEWORK    is the output framework to use for template generation
(o) -i GENERATION_INPUT_SOURCE is the source of input data to use when generating the template
    -h                         shows this text
(o) -o OUTPUT_DIR              is the directory where the outputs will be saved - defaults to the PRODUCT_STATE_DIR
(o) -p GENERATION_PROVIDER     is a provider to load for template generation - multiple providers can be added with extra arguments
(m) -u DEPLOYMENT_UNIT         is the deployment unit to be included in the template

  (m) mandatory, (o) optional, (d) deprecated

CONTEXT:

  CMDBS:
    (m) Account CMDB
    (m) Product CMDB

  LOCATION:
    (m) SEGMENT_DIR

  ENVIRONMENT_VARIABLES:
    (m) ACCOUNT

  (m) mandatory, (o) optional

DEFAULTS:

OUTPUTS:

  - File
    - Name: blueprint.json
    - Directory: "OUTPUT_DIR" or "PRODUCT_INFRASTRUCTURE_DIR/cot/ENVIRONMENT/SEGMENT/"

NOTES:


EOF
}

function main() {

    options "$@" || return $?

    ${GENERATION_DIR}/createTemplate.sh -l buildblueprint ${TEMPLATE_ARGS}
    RESULT=$?
    return "${RESULT}"
}

main "$@"
