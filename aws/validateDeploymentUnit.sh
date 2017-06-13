#!/bin/bash

# Validate the provided deployment unit
#
# This script is designed to be sourced into other scripts
#
# It requires the deployment unit to be checked
# If type is not defined, it just sets the flags to indicate 
# whether the provided unit is defined at each type level

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi

# Expected arguments
CHECK_UNIT="${DEPLOYMENT_UNIT}"
CHECK_TYPE="${TYPE}"

# Ensure lower case
CHECK_UNIT="${CHECK_UNIT,,}"
CHECK_TYPE="${CHECK_TYPE,,}"

# Ensure arguments have been provided
if [[ -z "${CHECK_UNIT}" ]]; then
    echo -e "\nNo deployment unit provided" >&2
    exit
fi

# Known types
TYPES=("account" "product" "application" "solution" "segment")

# Ensure type is kwown
if [[ (-n "${CHECK_TYPE}") &&
        (! $(grep -w "${CHECK_TYPE}" <<< "${TYPES[*]}")) ]]; then
    echo -e "\n${CHECK_TYPE} is not a known type - select from ${TYPES[*]}" >&2
    exit
fi

# Default deployment units for each type
ACCOUNT_UNITS_ARRAY=("s3" "cert" "roles" "apigateway")
PRODUCT_UNITS_ARRAY=("s3" "sns" "cert" "cmk")
APPLICATION_UNITS_ARRAY=(${CHECK_UNIT})
SOLUTION_UNITS_ARRAY=(${CHECK_UNIT})
SEGMENT_UNITS_ARRAY=("eip" "s3 " "cmk" "cert" "vpc" "dns" "eipvpc" "eips3vpc")

# Apply explicit unit lists and check for presence of unit
# Allow them to be separated by commas or spaces in line with the separator
# definitions in setContext.sh for the automation framework
for T in "${TYPES[@]}"; do
    UNITS_SOURCE="${T^^}_UNITS"
    UNITS_ARRAY_VAR="${UNITS_SOURCE}_ARRAY"
    if [[ -n "${!UNITS_SOURCE}" ]]; then
        eval "${UNITS_ARRAY_VAR}=\$(IFS=', '; echo \"\${${UNITS_SOURCE}[*]}\")"
    fi

    
    eval "grep -iw \"${CHECK_UNIT}\" <<< \"\${${UNITS_ARRAY_VAR}[*]}\" >/dev/null 2>&1"
    if [[ $? -eq 0 ]]; then
        eval "export IS_${T^^}_UNIT=true"
    else
        eval "export IS_${T^^}_UNIT=false"
    fi
done

# Check type if provided
# Confirm provided unit is valid
if [[ (-n "${CHECK_TYPE}") ]]; then
    UNITS_ARRAY_VAR="${CHECK_TYPE^^}_UNITS_ARRAY"
    eval "grep -iw \"${CHECK_UNIT}\" <<< \"\${${UNITS_ARRAY_VAR}[*]}\" >/dev/null 2>&1"
    if [[ $? -ne 0 ]]; then
        echo -e "\nUnknown deployment unit ${CHECK_UNIT} of ${CHECK_TYPE} type" >&2
        exit
    fi
fi

# All good