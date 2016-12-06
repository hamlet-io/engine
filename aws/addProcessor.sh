#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

PROCESSOR_PROFILE_DEFAULT="default"
COMPONENT_TYPE_VALUES=("ECS" "EC2")
function usage() {
    echo -e "\nAdd a processor"
    echo -e "\nUsage: $(basename $0) -i PROCESSOR_INSTANCE -p PROCESSOR_PROFILE -t COMPONENT_TYPE"
    echo -e "\nwhere\n"
    echo -e "    -h shows this text"
    echo -e "(m) -i PROCESSOR_INSTANCE is the processor instance type"
    echo -e "(m) -p PROCESSOR_PROFILE is the processor profile"
    echo -e "(m) -t COMPONENT_TYPE is the component type"
    echo -e "\nDEFAULTS:\n"
    echo -e "PROCESSOR_PROFILE=${PROCESSOR_PROFILE_DEFAULT}"
    echo -e "COMPONENT_TYPE=${COMPONENT_TYPE_VALUES[0]}"
    echo -e "\nNOTES:\n"
    echo -e "1. The profile to be updated is determined by the current directory location"
    echo -e "2. COMPONENT_TYPE is one of" "${COMPONENT_TYPE_VALUES[@]}"
    echo -e ""
    exit
}

# Parse options
while getopts ":hi:p:t:" opt; do
    case $opt in
        h)
            usage
            ;;
        i)
            PROCESSOR_INSTANCE="${OPTARG}"
            ;;
        p)
            PROCESSOR_PROFILE="${OPTARG}"
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

PROCESSOR_PROFILE="${PROCESSOR_PROFILE:-$PROCESSOR_PROFILE_DEFAULT}"
COMPONENT_TYPE="${COMPONENT_TYPE:-${COMPONENT_TYPE_VALUES[0]}}"

# Ensure mandatory arguments have been provided
if [[ (-z "${PROCESSOR_PROFILE}") ||
      (-z "${COMPONENT_TYPE}") ||
      (-z "${PROCESSOR_INSTANCE}") ]]; then
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
FILTER=".Processors[\"${PROCESSOR_PROFILE}\"][\"${COMPONENT_TYPE}\"].Processor=\"${PROCESSOR_INSTANCE}\""
cat "${TARGET_FILE}" | jq --indent 4 "${FILTER}" > ./temp_profile.json
RESULT=$?
if [[ "${RESULT}" -eq 0 ]]; then
    mv ./temp_profile.json "${TARGET_FILE}"
fi

