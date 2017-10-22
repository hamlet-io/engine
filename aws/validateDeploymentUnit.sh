#!/bin/bash

# Validate the provided deployment unit
#
# This script is designed to be sourced into other scripts
#
# It requires the deployment unit to be checked
# If level is not defined, it just sets the flags to indicate 
# whether the provided unit is defined at each stack level

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# Expected arguments
CHECK_UNIT="${DEPLOYMENT_UNIT,,}"
CHECK_LEVEL="${LEVEL,,}"

# Ensure arguments have been provided
[[ -z "${CHECK_UNIT}" ]] && fatal "No deployment unit provided"

# Known levels
LEVELS=("account" "product" "application" "solution" "segment" "multiple")

# Ensure level is kwown
[[ (-n "${CHECK_LEVEL}") &&
    (! $(grep -w "${CHECK_LEVEL}" <<< "${LEVELS[*]}")) ]] &&
    fatal "${CHECK_LEVEL} is not a known stack level - select from ${LEVELS[*]}"

# Default deployment units for each level
ACCOUNT_UNITS_ARRAY=("s3" "cert" "roles" "apigateway" "waf")
PRODUCT_UNITS_ARRAY=("s3" "sns" "cert" "cmk")
APPLICATION_UNITS_ARRAY=(${CHECK_UNIT})
SOLUTION_UNITS_ARRAY=(${CHECK_UNIT})
SEGMENT_UNITS_ARRAY=("iam" "lg" "eip" "s3" "cmk" "cert" "vpc" "nat" "ssh" "dns" "eipvpc" "eips3vpc")
MULTIPLE_UNITS_ARRAY=("iam" "dashboard")

# Apply explicit unit lists and check for presence of unit
# Allow them to be separated by commas or spaces in line with the separator
# definitions in setContext.sh for the automation framework
for L in "${LEVELS[@]}"; do
    declare -n UNITS_SOURCE="${L^^}_UNITS"
    declare -n UNITS_ARRAY="${L^^}_UNITS_ARRAY"
    if [[ -n "${UNITS_SOURCE}" ]]; then
        IFS=", " read -ra UNITS_ARRAY <<< "${UNITS_SOURCE}"
    fi

    grep -iw "${CHECK_UNIT}" <<< "${UNITS_ARRAY[*]}" >/dev/null 2>&1 &&
      declare -x IS_${L^^}_UNIT=true ||
      declare -x IS_${L^^}_UNIT=false
done

# Check level if provided
# Confirm provided unit is valid
if [[ (-n "${CHECK_LEVEL}") ]]; then
    declare -n IS_UNIT="IS_${CHECK_LEVEL^^}_UNIT"
    [[ "${IS_UNIT}" != "true" ]] && fatal "Unknown deployment unit ${CHECK_UNIT} for ${CHECK_LEVEL} stack level"
fi

# All good