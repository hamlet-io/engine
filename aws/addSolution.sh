#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults

function usage() {
    cat <<EOF

Add a solution pattern to a product

Usage: $(basename $0) -s SOLUTION_NAME  -u

where

    -h                  shows this text
(m) -s SOLUTION_NAME    is the name of the solution pattern
(o) -u                  if solution should be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. Script will copy solution to product/segment depending on current location

EOF
    exit
}

# Parse options
while getopts "hs:u" opt; do
    case $opt in
        h)
            usage
            ;;
        s)
            SOLUTION_NAME="${OPTARG}"
            ;;
        u)
            UPDATE_SOLUTION="true"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Ensure mandatory arguments have been provided
[[ (-z "${SOLUTION_NAME}") ]] && fatalMandatory

# Ensure solution exists
PATTERN_DIR="${GENERATION_PATTERNS_DIR}/solutions/${SOLUTION_NAME}"
[[ ! -d "${PATTERN_DIR}" ]] && fatal "Solution pattern is not known"

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

# Ensure we are in the product or segment directory
if [[ ("product" =~ "${LOCATION}") ]]; then
    TARGET_DIR="./solutions"
    mkdir -p ${TARGET_DIR}
elif [[ ("segment" =~ "${LOCATION}") ]]; then
    TARGET_DIR="."
else
    fatalProductOrSegmentDirectory
fi

# Check whether the solution profile is already in place
SOLUTION_FILE="${TARGET_DIR}/solution.json"
[[ (-f "${SOLUTION_FILE}") && ("${UPDATE_SOLUTION}" != "true") ]] &&
    fatal "Solution profile already exists. Maybe try using update option?"

# Copy across the solution pattern
cp -rp ${PATTERN_DIR}/* ${TARGET_DIR}

# Add a reference to the pattern to the solution
SOLUTION_TEMP_FILE="${TARGET_DIR}/temp_solution.json"
if [[ -f "${SOLUTION_FILE}" ]]; then
    jq --indent 4 ".Solution.Pattern=\"${SOLUTION_NAME}\"" < "${SOLUTION_FILE}" > ${SOLUTION_TEMP_FILE}
    RESULT=$?
    [[ "${RESULT}" -ne 0 ]] && fatal "Unable to add pattern reference to solution"

    mv "${SOLUTION_TEMP_FILE}" "${SOLUTION_FILE}"
fi

# All good
RESULT=0

