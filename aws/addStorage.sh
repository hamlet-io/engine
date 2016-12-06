#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

STORAGE_PROFILE_DEFAULT="default"
STORAGE_DEVICE_DEFAULT="sdp"
STORAGE_SIZE_DEFAULT="100"
COMPONENT_TYPE_VALUES=("ECS" "EC2")
function usage() {
    echo -e "\nAdd a processor"
    echo -e "\nUsage: $(basename $0) -d STORAGE_DEVICE -p STORAGE_PROFILE -s STORAGE_SIZE -t COMPONENT_TYPE"
    echo -e "\nwhere\n"
    echo -e "(m) -d STORAGE_DEVICE is the storage device"
    echo -e "    -h shows this text"
    echo -e "(m) -p STORAGE_PROFILE is the storage profile"
    echo -e "(m) -s STORAGE_SIZE is the storage size in Gb"
    echo -e "(m) -t COMPONENT_TYPE is the component type"
    echo -e "\nDEFAULTS:\n"
    echo -e "STORAGE_PROFILE=${STORAGE_PROFILE_DEFAULT}"
    echo -e "COMPONENT_TYPE=${COMPONENT_TYPE_VALUES[0]}"
    echo -e "STORAGE_DEVICE=${STORAGE_DEVICE_DEFAULT}"
    echo -e "STORAGE_SIZE=${STORAGE_SIZE_DEFAULT}"
    echo -e "\nNOTES:\n"
    echo -e "1. The profile to be updated is determined by the current directory location"
    echo -e "2. COMPONENT_TYPE is one of" "${COMPONENT_TYPE_VALUES[@]}"
    echo -e ""
    exit
}

# Parse options
while getopts ":d:hp:s:t:" opt; do
    case $opt in
        d)
            STORAGE_DEVICE="${OPTARG}"
            ;;
        h)
            usage
            ;;
        p)
            STORAGE_PROFILE="${OPTARG}"
            ;;
        s)
            STORAGE_SIZE="${OPTARG}"
            ;;
        t)
            COMPONENT_TYPE="${OPTARG}"
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

STORAGE_PROFILE="${STORAGE_PROFILE:-$STORAGE_PROFILE_DEFAULT}"
COMPONENT_TYPE="${COMPONENT_TYPE:-${COMPONENT_TYPE_VALUES[0]}}"
STORAGE_DEVICE="${STORAGE_DEVICE:-$STORAGE_DEVICE_DEFAULT}"
STORAGE_SIZE="${STORAGE_SIZE:-$STORAGE_SIZE_DEFAULT}"

# Ensure mandatory arguments have been provided
if [[ (-z "${STORAGE_PROFILE}") ||
      (-z "${COMPONENT_TYPE}") ||
      (-z "${STORAGE_DEVICE}") ||
      (-z "${STORAGE_SIZE}") ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the product or segment directory
if [[ ("product" =~ "${LOCATION}") ]]; then
    TARGET_FILE="./solutions/solution.json"
else
    if [[ ("segment" =~ "${LOCATION}") ]]; then
        TARGET_FILE="./segment.json"
    else
        echo -e "\nWe don't appear to be in the product or segment directory. Are we in the right place?"
        usage
    fi
fi

# Check whether the target exists
if [[ ! -f "${TARGET_FILE}" ]]; then
    echo -e "\nSolution or segment profile not found. Maybe try adding solution/segment first?"
    usage
fi

# Update the target file
FILTER=".Storage[\"${STORAGE_PROFILE}\"][\"${COMPONENT_TYPE}\"].Volumes[0].Device=\"/dev/${STORAGE_DEVICE}\""
FILTER="${FILTER} | .Storage[\"${STORAGE_PROFILE}\"][\"${COMPONENT_TYPE}\"].Volumes[0].Size=\"${STORAGE_SIZE}\""
cat "${TARGET_FILE}" | jq --indent 4 "${FILTER}" > ./temp_profile.json
RESULT=$?
if [[ "${RESULT}" -eq 0 ]]; then
    mv ./temp_profile.json "${TARGET_FILE}"
fi

