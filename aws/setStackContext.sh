#!/bin/bash

# Set up the necessary environment for Cloud Formation stack management
#
# This script is designed to be sourced into other scripts

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi

# Ensure mandatory arguments have been provided
if [[ (-z "${TYPE}") || \
        ((-z "${DEPLOYMENT_UNIT}") && (! ("${TYPE}" =~ product ))) ]]; then
    echo -e "\nInsufficient arguments" >&2
    exit
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

case $TYPE in
    account|product)
        if [[ ! ("${TYPE}" =~ ${LOCATION} ) ]]; then
            echo -e "\nCurrent directory doesn't match requested type \"${TYPE}\". Are we in the right place?" >&2
            exit
        fi
        ;;
    solution|segment|application)
        if [[ ! ("segment" =~ ${LOCATION} ) ]]; then
            echo -e "\nCurrent directory doesn't match requested type \"${TYPE}\". Are we in the right place?" >&2
            exit
        fi
        ;;
esac


# Determine the details of the template to be created
PRODUCT_PREFIX="${PRODUCT}"
TYPE_PREFIX="${TYPE}-"
DEPLOYMENT_UNIT_PREFIX="${DEPLOYMENT_UNIT}-"
REGION_PREFIX="${REGION}-"
SEGMENT_SUFFIX="-${SEGMENT}"
TYPE_SUFFIX="-${TYPE}"
DEPLOYMENT_UNIT_SUFFIX="-${DEPLOYMENT_UNIT}"
if [[ -n "${DEPLOYMENT_UNIT_SUBSET}" ]]; then
    DEPLOYMENT_UNIT_SUBSET_PREFIX="${DEPLOYMENT_UNIT_SUBSET,,}-"
    DEPLOYMENT_UNIT_SUBSET_SUFFIX="-${DEPLOYMENT_UNIT_SUBSET,,}"
fi
case $TYPE in
    account)
        CF_DIR="${INFRASTRUCTURE_DIR}/${ACCOUNT}/aws/cf"
        PRODUCT_PREFIX="${ACCOUNT}"
        REGION="${ACCOUNT_REGION}"
        REGION_PREFIX="${ACCOUNT_REGION}-"
        SEGMENT_SUFFIX=""

        # LEGACY: Support stacks created before deployment units added to account
        if [[ "${DEPLOYMENT_UNIT}" =~ s3 ]]; then
            if [[ -f "${CF_DIR}/${TYPE_PREFIX}${REGION_PREFIX}template.json" ]]; then
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
            fi
        fi
        
        # Simplify stack naming if stack doesn't already exist
        if [[ ! -f "${TYPE_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${REGION_PREFIX}stack.json" ]]; then
            PRODUCT_PREFIX=""
            TYPE_SUFFIX="${TYPE}"
        fi
        ;;

    product)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/cf"
        SEGMENT_SUFFIX=""

        # LEGACY: Support stacks created before deployment units added to product
        if [[ "${DEPLOYMENT_UNIT}" =~ cmk ]]; then
            if [[ -f "${CF_DIR}/${TYPE_PREFIX}${REGION_PREFIX}template.json" ]]; then
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
            fi
        fi
        ;;

    solution)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf"
        TYPE_PREFIX="soln-"
        TYPE_SUFFIX="-soln"
        if [[ -f "${CF_DIR}/solution-${REGION}-template.json" ]]; then
            TYPE_PREFIX="solution-"
            TYPE_SUFFIX="-solution"
            DEPLOYMENT_UNIT_PREFIX=""
            DEPLOYMENT_UNIT_SUFFIX=""
        fi
        ;;

    segment)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf"
        TYPE_PREFIX="seg-"
        TYPE_SUFFIX="-seg"

        # LEGACY: Support old formats for existing stacks so they can be updated 
        if [[ !("${DEPLOYMENT_UNIT}" =~ cmk|cert|dns ) ]]; then
            if [[ -f "${CF_DIR}/cont-${DEPLOYMENT_UNIT_PREFIX}${REGION_PREFIX}template.json" ]]; then
                TYPE_PREFIX="cont-"
                TYPE_SUFFIX="-cont"
            fi
            if [[ -f "${CF_DIR}/container-${REGION}-template.json" ]]; then
                TYPE_PREFIX="container-"
                TYPE_SUFFIX="-container"
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
            fi
            if [[ -f "${CF_DIR}/${SEGMENT}-container-template.json" ]]; then
                TYPE_PREFIX="${SEGMENT}-container-"
                TYPE_SUFFIX="-container"
                DEPLOYMENT_UNIT_PREFIX=""
                DEPLOYMENT_UNIT_SUFFIX=""
                REGION_PREFIX=""
            fi
        fi
        # "cmk" now used instead of "key"
        if [[ "${DEPLOYMENT_UNIT}" == "cmk" ]]; then
            if [[ -f "${CF_DIR}/${TYPE_PREFIX}key-${REGION_PREFIX}template.json" ]]; then
                DEPLOYMENT_UNIT_PREFIX="key-"
                DEPLOYMENT_UNIT_SUFFIX="-key"
            fi
        fi
        ;;

    application)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf"
        TYPE_PREFIX="app-"
        TYPE_SUFFIX="-app"
        ;;

    *)
        echo -e "\n\"$TYPE\" is not one of the known stack types (account, product, segment, solution, application). Nothing to do." >&2
        exit
        exit
        ;;
esac

STACK_NAME="${STACK_NAME:-${PRODUCT_PREFIX}${SEGMENT_SUFFIX}${TYPE_SUFFIX}${DEPLOYMENT_UNIT_SUFFIX}${DEPLOYMENT_UNIT_SUBSET_SUFFIX}}"
TEMPLATE="${TYPE_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}template.json"
STACK="${TYPE_PREFIX}${DEPLOYMENT_UNIT_PREFIX}${DEPLOYMENT_UNIT_SUBSET_PREFIX}${REGION_PREFIX}stack.json"

