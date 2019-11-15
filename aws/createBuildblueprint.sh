#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

function options() {

  # Parse options
  while getopts ":f:hi:p:s:t:u:" option; do
      case "${option}" in
          f|i|p|s|t|u) TEMPLATE_ARGS="${TEMPLATE_ARGS} -${option} ${OPTARG}" ;;
          h) usage; return 1 ;;
          \?) fatalOption; return 1 ;;
      esac
  done

  return 0
}

function usage() {
  cat <<EOF

Create a blueprint output for the provided deployment unit

Usage: $(basename $0) -u DEPLOYMENT_UNIT

where

(o) -i GENERATION_INPUT_SOURCE is the source of input data to use when generating the template
    -h                         shows this text
(o) -p GENERATION_PROVIDER     is the provider to for template generation
(o) -f GENERATION_FRAMEWORK    is the output framework to use for template generation
(o) -s GENERATION_SCENARIOS    is a comma seperated list of framework scenarios to load
(o) -t GENERATION_TESTCASE     is the test case you would like to generate a template for
(m) -u DEPLOYMENT_UNIT         is the deployment unit to be included in the template

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. You must be in the directory specific to the level

EOF
}

function main() {

    options "$@" || return $?

    ${GENERATION_DIR}/createTemplate.sh -l buildblueprint ${TEMPLATE_ARGS}
    RESULT=$?
    return "${RESULT}"
}

main "$@"
