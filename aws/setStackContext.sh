#!/usr/bin/env bash

# Set up the necessary environment for Cloud Formation stack management
#
# This script is designed to be sourced into other scripts

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# Ensure mandatory arguments have been provided
[[ (-z "${LEVEL}") ||
    ((-z "${DEPLOYMENT_UNIT}") && (! ("${LEVEL}" =~ product ))) ]] && fatalMandatory

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

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
case $LEVEL in
    account)
        CF_DIR="${ACCOUNT_STATE_DIR}/cf/shared"
        PRODUCT_PREFIX="${ACCOUNT}"
        REGION="${ACCOUNT_REGION}"
        REGION_PREFIX="${ACCOUNT_REGION}-"
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
        else
            STACK_NAME=$(jq -r ".Stacks[0].StackName" <  "${CF_DIR}/${LEVEL_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${REGION_PREFIX}stack.json")
        fi
        ;;

    product)
        CF_DIR="${PRODUCT_STATE_DIR}/cf/shared"
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
        CF_DIR="${PRODUCT_STATE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"
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
        CF_DIR="${PRODUCT_STATE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"
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
        CF_DIR="${PRODUCT_STATE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"
        LEVEL_PREFIX="app-"
        LEVEL_SUFFIX="-app"
        ;;

    multiple)
        CF_DIR="${PRODUCT_STATE_DIR}/cf/${ENVIRONMENT}/${SEGMENT}"
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

