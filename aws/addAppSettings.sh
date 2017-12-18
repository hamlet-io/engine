#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

function usage() {
    cat <<EOF

Add the application settings for a segment

Usage: $(basename $0) -s SEGMENT -u

where

    -h          shows this text
(o) -s SEGMENT  if details should be copied from an existing segment
(o) -u          if details should be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. If no existing segment is provided, application settings are 
   located via the solution pattern. Nothing is done if no 
   solution pattern can be found
2. The script must be run in the segment directory

EOF
    exit
}

# Parse options
while getopts ":hs:u" opt; do
    case $opt in
        h)
            usage
            ;;
        s)
            COPY_SEGMENT="${OPTARG}"
            ;;
        u)
            UPDATE_APPSETTINGS="true"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

# Ensure we are in the segment directory
checkInSegmentDirectory

# Check whether the application settings already exist
SEGMENT_APPSETTINGS_DIR="${APPSETTINGS_DIR}/${SEGMENT}"
DEPLOYMENT_UNITS=$(find ${SEGMENT_APPSETTINGS_DIR}/* -type d 2> /dev/null)
[[ (-n "${DEPLOYMENT_UNITS}") && ("${UPDATE_APPSETTINGS}" != "true") ]] &&
    fatal "Segment application settings already exist. Maybe try using update option?"

if [[ -n "${COPY_SEGMENT}" ]]; then
    COPY_DIR="${APPSETTINGS_DIR}/${COPY_SEGMENT}"
else
    # Find the solution name
    SOLUTION_NAME=$(jq -r ".Solution.Pattern | select(.!=null)" < ${COMPOSITE_BLUEPRINT})
    
    [[ -z "${SOLUTION_NAME}" ]] &&
        fatal "No solution pattern configured yet. Maybe try adding the solution first?"
    
    # Check if a corresponding solution pattern exists
    PATTERN_DIR="${GENERATION_PATTERNS_DIR}/solutions/${SOLUTION_NAME}"
    [[ ! -d ${PATTERN_DIR} ]] && RESULT=0 &&
        fatalCantProceed "No pattern found matching the solution name \"${SOLUTION_NAME}\"."
    COPY_DIR="${PATTERN_DIR}/appsettings"
fi

[[ ! -d ${COPY_DIR} ]]  && RESULT=0 &&
    fatalCantProceed "No application settings found in ${COPY_DIR}."

# Copy across the application settings 
mkdir -p ${SEGMENT_APPSETTINGS_DIR}
cp -rp ${COPY_DIR}/* ${SEGMENT_APPSETTINGS_DIR}

# Remove any build references that may have been copied from another segment
find ${SEGMENT_APPSETTINGS_DIR} -name "build.ref" -delete

# All good
RESULT=0
