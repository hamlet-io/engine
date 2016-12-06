#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
    echo -e "\nAdd the application settings for a segment"
    echo -e "\nUsage: $(basename $0) -s SEGMENT -u"
    echo -e "\nwhere\n"
    echo -e "    -h shows this text"
    echo -e "(o) -s SEGMENT if details should be copied from an existing segment"
    echo -e "(o) -u if details should be updated"
    echo -e "\nDEFAULTS:\n"
    echo -e "\nNOTES:\n"
    echo -e "1. If no existing segment is provided, application settings are "
    echo -e "   located via the solution pattern. Nothing is done if no "
    echo -e "   solution pattern can be found"
    echo -e "3. The script must be run in the segment directory"
    echo -e ""
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
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument"
            usage
            ;;
    esac
done

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the segment directory
if [[ ! ("segment" =~ "${LOCATION}") ]]; then
    echo -e "\nWe don't appear to be in the segment directory. Are we in the right place?"
    usage
fi

# Check whether the application settings already exist
SEGMENT_APPSETTINGS_DIR="${APPSETTINGS_DIR}/${SEGMENT}"
SLICES=$(find ${SEGMENT_APPSETTINGS_DIR}/* -type d 2> /dev/null)
if [[ -n ${SLICES} ]]; then
    if [[ "${UPDATE_APPSETTINGS}" != "true" ]]; then
        echo -e "\nSegment application settings already exist. Maybe try using update option?"
        usage
    fi
fi

if [[ -n "${COPY_SEGMENT}" ]]; then
    COPY_DIR="${APPSETTINGS_DIR}/${COPY_SEGMENT}"
else
    # Find the solution name
    SOLUTION_NAME=$(cat ${COMPOSITE_BLUEPRINT} | jq -r ".Solution.Pattern | select(.!=null)")
    
    if [[ -z "${SOLUTION_NAME}" ]]; then
        echo -e "\nNo solution pattern configured yet. Maybe try adding the solution first?"
        usage
    fi
    
    # Check if a corresponding solution pattern exists
    PATTERN_DIR="${GENERATION_PATTERNS_DIR}/solutions/${SOLUTION_NAME}"
    if [[ ! -d ${PATTERN_DIR} ]]; then
        echo -e "\nNo pattern found matching the solution name \"${SOLUTION_NAME}\". Nothing to do"
        RESULT=0
        exit
    fi
    COPY_DIR="${PATTERN_DIR}/appsettings"
fi

if [[ ! -d ${COPY_DIR} ]]; then
    echo -e "\nNo application settings found in ${COPY_DIR}. Nothing to do"
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
