#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
PROCESSOR_PROFILE_DEFAULT="default"
COMPONENT_TYPE_VALUES=("ECS" "EC2")

function usage() {
    cat <<EOF

Add a processor

Usage: $(basename $0) -i PROCESSOR_INSTANCE -p PROCESSOR_PROFILE -t COMPONENT_TYPE

where

    -h                      shows this text
(m) -i PROCESSOR_INSTANCE   is the processor instance type
(m) -p PROCESSOR_PROFILE    is the processor profile
(m) -t COMPONENT_TYPE       is the component type

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

PROCESSOR_PROFILE=${PROCESSOR_PROFILE_DEFAULT}
COMPONENT_TYPE=${COMPONENT_TYPE_VALUES[0]}

NOTES:

1. The profile to be updated is determined by the current directory location
2. COMPONENT_TYPE is one of" "${COMPONENT_TYPE_VALUES[@]}

EOF
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
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

PROCESSOR_PROFILE="${PROCESSOR_PROFILE:-$PROCESSOR_PROFILE_DEFAULT}"
COMPONENT_TYPE="${COMPONENT_TYPE:-${COMPONENT_TYPE_VALUES[0]}}"

# Ensure mandatory arguments have been provided
[[ (-z "${PROCESSOR_PROFILE}") ||
    (-z "${COMPONENT_TYPE}") ||
    (-z "${PROCESSOR_INSTANCE}") ]] && fatalMandatory

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

# Ensure we are in the product or segment directory
if [[ ("product" =~ "${LOCATION}") ]]; then
    TARGET_FILE="./solutions/solution.json"
else
    if [[ ("segment" =~ "${LOCATION}") ]]; then
        TARGET_FILE="./segment.json"
    else
        fatalProductOrSegmentDirectory
    fi
fi

# Check whether the target exists
[[ ! -f "${TARGET_FILE}" ]] && fatal "Solution or segment profile not found. Maybe try adding solution/segment first?"

# Update the target file
FILTER=".Processors[\"${PROCESSOR_PROFILE}\"][\"${COMPONENT_TYPE}\"].Processor=\"${PROCESSOR_INSTANCE}\""
jq --indent 4 "${FILTER}" < "${TARGET_FILE}" > ./temp_profile.json
RESULT=$?
[[ "${RESULT}" -eq 0 ]] && mv ./temp_profile.json "${TARGET_FILE}"


