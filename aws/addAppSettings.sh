#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
    cat <<-ENDOFMESSAGE
Add the application settings for a segment
Usage: $(basename $0) -s SEGMENT -u
where
    -h shows this text
(o) -s SEGMENT if details should be copied from an existing segment
(o) -u if details should be updated
DEFAULTS:
NOTES:
1. If no existing segment is provided, application settings are 
   located via the solution pattern. Nothing is done if no 
   solution pattern can be found
3. The script must be run in the segment directory

ENDOFMESSAGE
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
            cat <<< "Invalid option: -${OPTARG}" >&2
            usage
            ;;
        :)
            cat <<< "Option -${OPTARG} requires an argument" >&2
            usage
            ;;
    esac
done

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the segment directory
if [[ ! ("segment" =~ "${LOCATION}") ]]; then
    cat <<< "We don't appear to be in the segment directory. Are we in the right place?" >&2
    usage
fi

# Check whether the application settings already exist
SEGMENT_APPSETTINGS_DIR="${APPSETTINGS_DIR}/${SEGMENT}"
SLICES=$(find ${SEGMENT_APPSETTINGS_DIR}/* -type d 2> /dev/null)
if [[ -n ${SLICES} ]]; then
    if [[ "${UPDATE_APPSETTINGS}" != "true" ]]; then
        cat <<< "Segment application settings already exist. Maybe try using update option?" >&2
        usage
    fi
fi

if [[ -n "${COPY_SEGMENT}" ]]; then
    COPY_DIR="${APPSETTINGS_DIR}/${COPY_SEGMENT}"
else
    # Find the solution name
    SOLUTION_NAME=$(cat ${COMPOSITE_BLUEPRINT} | jq -r ".Solution.Pattern | select(.!=null)")
    
    if [[ -z "${SOLUTION_NAME}" ]]; then
        cat <<< "No solution pattern configured yet. Maybe try adding the solution first?" >&2
        usage
    fi
    
    # Check if a corresponding solution pattern exists
    PATTERN_DIR="${GENERATION_PATTERNS_DIR}/solutions/${SOLUTION_NAME}"
    if [[ ! -d ${PATTERN_DIR} ]]; then
        cat <<< "No pattern found matching the solution name \"${SOLUTION_NAME}\". Nothing to do"
        RESULT=0
        exit
    fi
    COPY_DIR="${PATTERN_DIR}/appsettings"
fi

if [[ ! -d ${COPY_DIR} ]]; then
    cat <<< "No application settings found in ${COPY_DIR}. Nothing to do"
    RESULT=0
    exit
fi

# Copy across the application settings 
mkdir -p ${SEGMENT_APPSETTINGS_DIR}
cp -rp ${COPY_DIR}/* ${SEGMENT_APPSETTINGS_DIR}

# Remove any build references that may have been copied from another segment
find ${SEGMENT_APPSETTINGS_DIR} -name "build.ref" -delete

# All good
RESULT=0
