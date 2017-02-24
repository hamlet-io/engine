#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults

function usage() {
    cat <<EOF

Add a solution pattern to a product

Usage: $(basename $0) -s SOLUTION_NAME  -u

where

    -h shows this text
(m) -s SOLUTION_NAME is the name of the solution pattern
(o) -u if solution should be updated

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
            echo -e "\nInvalid option: -${OPTARG}" >&2
            exit
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument" >&2
            exit
            ;;
    esac
done

# Ensure mandatory arguments have been provided
if [[ (-z "${SOLUTION_NAME}") ]]; then
    echo -e "\nInsufficient arguments" >&2
    exit
fi

# Ensure solution exists
PATTERN_DIR="${GENERATION_PATTERNS_DIR}/solutions/${SOLUTION_NAME}"
if [[ ! -d "${PATTERN_DIR}" ]]; then
    echo -e "\nSolution pattern is not known" >&2
    exit
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the product or segment directory
if [[ ("product" =~ "${LOCATION}") ]]; then
    TARGET_DIR="./solutions"
    mkdir -p ${TARGET_DIR}
elif [[ ("segment" =~ "${LOCATION}") ]]; then
    TARGET_DIR="."
else
    echo -e "\nWe don't appear to be in the product or segment directory. Are we in the right place?" >&2
    exit
fi

# Check whether the solution profile is already in place
SOLUTION_FILE="${TARGET_DIR}/solution.json"
if [[ -f "${SOLUTION_FILE}" ]]; then
    if [[ "${UPDATE_SOLUTION}" != "true" ]]; then
        echo -e "\nSolution profile already exists. Maybe try using update option?" >&2
        exit
    fi
fi

# Copy across the solution pattern
cp -rp ${PATTERN_DIR}/* ${TARGET_DIR}

# Add a reference to the pattern to the solution
SOLUTION_TEMP_FILE="${TARGET_DIR}/temp_solution.json"
if [[ -f "${SOLUTION_FILE}" ]]; then
    jq --indent 4 ".Solution.Pattern=\"${SOLUTION_NAME}\"" < ${SOLUTION_FILE} > ${SOLUTION_TEMP_FILE}
    RESULT=$?
    if [[ "${RESULT}" -eq 0 ]]; then
        mv "${SOLUTION_TEMP_FILE}" "${SOLUTION_FILE}"
    else
        echo -e "\nUnable to add pattern reference to solution" >&2
        exit
    fi
fi

# All good
RESULT=0

