#!/usr/bin/env bash

# Set up the necessary environment for Cloud Formation stack management
#
# This script is designed to be sourced into other scripts

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# Ensure mandatory arguments have been provided
[[ (-z "${LEVEL}") ||
    ((-z "${DEPLOYMENT_UNIT}") && (! ("${LEVEL}" =~ product ))) ]] && fatalMandatory

# Set up the context
. "${GENERATION_BASE_DIR}/execution/setContext.sh"

case $LEVEL in
    account|product)
        [[ ! ("${LEVEL}" =~ ${LOCATION} ) ]] &&
            fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"."
        ;;
    solution|segment|application|multiple)
        [[ ! ("segment" =~ ${LOCATION} ) ]] &&
            fatalLocation "Current directory doesn't match requested level \"${LEVEL}\"."
        ;;
esac


# Determine the details of the template to be created
PRODUCT_PREFIX="${PRODUCT}"
LEVEL_PREFIX="${LEVEL}-"
DEPLOYMENT_UNIT_PREFIX="${DEPLOYMENT_UNIT}-"
ACCOUNT_PREFIX="${ACCOUNT}-"
REGION_PREFIX="${REGION}-"
ENVIRONMENT_SUFFIX="-${ENVIRONMENT}"
SEGMENT_SUFFIX="-${SEGMENT}"
if [[ ("${SEGMENT}" == "${ENVIRONMENT}") ||
        ("${SEGMENT}" == "default") ]]; then
    SEGMENT_SUFFIX=""
fi
LEVEL_SUFFIX="-${LEVEL}"
DEPLOYMENT_UNIT_SUFFIX="-${DEPLOYMENT_UNIT}"
if [[ -n "${DEPLOYMENT_UNIT_SUBSET}" ]]; then
    DEPLOYMENT_UNIT_SUBSET_PREFIX="${DEPLOYMENT_UNIT_SUBSET,,}-"
    DEPLOYMENT_UNIT_SUBSET_SUFFIX="-${DEPLOYMENT_UNIT_SUBSET,,}"
fi

# First determine the CF_DIR so we can handle deployment unit subdirectories
case $LEVEL in
    account)
        CF_DIR="${ACCOUNT_STATE_DIR}/cf/shared"
        REGION="${ACCOUNT_REGION}"
        REGION_PREFIX="${ACCOUNT_REGION}-"
        ;;

    product)
        CF_DIR="${PRODUCT_STATE_DIR}/cf/shared"
        ;;

    solution|segment|application|multiple)
        CF_DIR="${PRODUCT_STATE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"
        ;;
    *)
        fatalCantProceed "\"$LEVEL\" is not one of the known stack levels."
        ;;
esac

# Adjust for deployment unit subdirectories
readarray -t legacy_files < <(find "${CF_DIR}" -mindepth 1 -maxdepth 1 -name "*${DEPLOYMENT_UNIT}*" )

if [[ (-d "${CF_DIR}/${DEPLOYMENT_UNIT}") || "${#legacy_files[@]}" -eq 0 ]]; then
    CF_DIR=$(getUnitCFDir "${CF_DIR}" "${LEVEL}" "${DEPLOYMENT_UNIT}" "" "${REGION}" )
fi

case $LEVEL in
    account)
        PRODUCT_PREFIX="${ACCOUNT}"
        ENVIRONMENT_SUFFIX=""
        SEGMENT_SUFFIX=""

        # LEGACY: Support stacks created before deployment units added to account
        if [[ "${DEPLOYMENT_UNIT}" =~ s3 ]]; then
            if [[ -f "${CF_DIR}/${LEVEL_PREFIX}${REGION_PREFIX}template.json" ]]; then
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
            fi
        fi

        # Simplify stack naming if stack doesn't already exist
        if [[ ! -f "${CF_DIR}/${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${REGION_PREFIX}stack.json" ]]; then
            PRODUCT_PREFIX=""
            LEVEL_SUFFIX="${LEVEL}"
        fi
        ;;

    product)
        ENVIRONMENT_SUFFIX=""
        SEGMENT_SUFFIX=""

        # LEGACY: Support stacks created before deployment units added to product
        if [[ "${DEPLOYMENT_UNIT}" =~ cmk ]]; then
            if [[ -f "${CF_DIR}/${LEVEL_PREFIX}${REGION_PREFIX}template.json" ]]; then
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
            fi
        fi
        ;;

    solution)
        LEVEL_PREFIX="soln-"
        LEVEL_SUFFIX="-soln"
        if [[ -f "${CF_DIR}/solution-${REGION}-template.json" ]]; then
            LEVEL_PREFIX="solution-"
            LEVEL_SUFFIX="-solution"
            DEPLOYMENT_UNIT_PREFIX=""
            DEPLOYMENT_UNIT_SUFFIX=""
        fi
        ;;

    segment)
        LEVEL_PREFIX="seg-"
        LEVEL_SUFFIX="-seg"

        # LEGACY: Support old formats for existing stacks so they can be updated
        if [[ !("${DEPLOYMENT_UNIT}" =~ cmk|cert|dns ) ]]; then
            if [[ -f "${CF_DIR}/cont-${DEPLOYMENT_UNIT_PREFIX}${REGION_PREFIX}template.json" ]]; then
                LEVEL_PREFIX="cont-"
                LEVEL_SUFFIX="-cont"
            fi
            if [[ -f "${CF_DIR}/container-${REGION}-template.json" ]]; then
                LEVEL_PREFIX="container-"
                LEVEL_SUFFIX="-container"
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
            fi
            if [[ -f "${CF_DIR}/${SEGMENT}-container-template.json" ]]; then
                LEVEL_PREFIX="${SEGMENT}-container-"
                LEVEL_SUFFIX="-container"
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
                REGION_PREFIX=""
            fi
        fi
        # "cmk" now used instead of "key"
        if [[ "${DEPLOYMENT_UNIT}" == "cmk" ]]; then
            if [[ -f "${CF_DIR}/${LEVEL_PREFIX}key-${REGION_PREFIX}template.json" ]]; then
                DEPLOYMENT_UNIT_PREFIX="key-"
                DEPLOYMENT_UNIT_SUFFIX="-key"
            fi
        fi
        ;;

    application)
        LEVEL_PREFIX="app-"
        LEVEL_SUFFIX="-app"
        ;;

    multiple)
        LEVEL_PREFIX="multi-"
        LEVEL_SUFFIX="-multi"
        ;;

    *)
        fatalCantProceed "\"$LEVEL\" is not one of the known stack levels."
        ;;
esac

STACK_NAME="${STACK_NAME:-${PRODUCT_PREFIX}${ENVIRONMENT_SUFFIX}${SEGMENT_SUFFIX}${LEVEL_SUFFIX}${DEPLOYMENT_UNIT_SUFFIX}${DEPLOYMENT_UNIT_SUBSET_SUFFIX}}"
TEMPLATE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}template.json"
STACK="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}stack.json"
CHANGE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}lastchange.json"
if [[ ! -f "${CF_DIR}/${TEMPLATE}" ]]; then
    TEMPLATE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}template.json"
    STACK="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}stack.json"
    CHANGE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}lastchange.json"
fi

# Permit renaming of stack files without affecting existing stack status
if [[ -f "${CF_DIR}/${STACK}" ]]; then
    STACK_NAME=$(jq -r ".Stacks[0].StackName" <  "${CF_DIR}/${STACK}")
fi

ALTERNATIVE_TEMPLATES=$(findFiles \
    "${CF_DIR}/${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}*-template.json" \
    "${CF_DIR}/${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}*-template.json" )

CONFIG="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}config.json"
if [[ ! -f "${CF_DIR}/${CONFIG}" ]]; then
    CONFIG="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}config.json"
fi

PROLOGUE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}prologue.sh"
if [[ ! -f "${CF_DIR}/${PROLOGUE}" ]]; then
    PROLOGUE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}prologue.sh"
fi

EPILOGUE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}epilogue.sh"
if [[ ! -f "${CF_DIR}/${EPILOGUE}" ]]; then
    EPILOGUE="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}epilogue.sh"
fi

CLI="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}cli.json"

DEFINITION="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}definition.json"

PARAMETERS="${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${ACCOUNT_PREFIX}${REGION_PREFIX}parameters.json"