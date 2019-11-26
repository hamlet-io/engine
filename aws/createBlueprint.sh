#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

function options() {

  # Parse options
  while getopts ":f:hi:o:p:s:t:" option; do
      case "${option}" in
          f|i|o|p|s|t) TEMPLATE_ARGS="${TEMPLATE_ARGS} -${option} ${OPTARG}" ;;
          h) usage; return 1 ;;
          \?) fatalOption; return 1 ;;
      esac
  done

  return 0
}

function usage() {
  cat <<EOF

Create a blueprint output of the segment

Usage: $(basename $0) -i GENERATION_INPUT_SOURCE -t GENERATION_TESTCASE -s GENERATION_SCENARIOS

where

(o) -i GENERATION_INPUT_SOURCE is the source of input data to use when generating the template
    -h                         shows this text
(o) -o OUTPUT_DIR              is the directory where the outputs will be saved - defaults to the PRODUCT_STATE_DIR
(o) -p GENERATION_PROVIDER     is the provider to for template generation
(o) -f GENERATION_FRAMEWORK    is the output framework to use for template generation
(o) -t GENERATION_TESTCASE     is the test case you would like to generate a template for
(o) -s GENERATION_SCENARIOS    is a comma seperated list of framework scenarios to load

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. You must be in the directory specific to the level

EOF
}

function main() {

    options "$@" || return $?

    ${GENERATION_DIR}/createTemplate.sh -l blueprint ${TEMPLATE_ARGS}
    RESULT=$?
    return "${RESULT}"
}

main "$@"
