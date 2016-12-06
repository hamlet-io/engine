#!/bin/bash

# Set up the necessary environment for Cloud Formation stack management
#
# This script is designed to be sourced into other scripts

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi

# Ensure mandatory arguments have been provided
if [[ (-z "${TYPE}") || \
        ((-z "${SLICE}") && (! ("${TYPE}" =~ product ))) ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

case $TYPE in
    account|product)
        if [[ ! ("${TYPE}" =~ ${LOCATION} ) ]]; then
            echo -e "\nCurrent directory doesn't match requested type \"${TYPE}\". Are we in the right place?"
            usage
        fi
        ;;
    solution|segment|application)
        if [[ ! ("segment" =~ ${LOCATION} ) ]]; then
            echo -e "\nCurrent directory doesn't match requested type \"${TYPE}\". Are we in the right place?"
            usage
        fi
        ;;
esac


# Determine the details of the template to be created
PRODUCT_PREFIX="${PRODUCT}"
TYPE_PREFIX="${TYPE}-"
SLICE_PREFIX="${SLICE}-"
REGION_PREFIX="${REGION}-"
SEGMENT_SUFFIX="-${SEGMENT}"
TYPE_SUFFIX="-${TYPE}"
SLICE_SUFFIX="-${SLICE}"
case $TYPE in
    account)
        CF_DIR="${INFRASTRUCTURE_DIR}/${ACCOUNT}/aws/cf"
        PRODUCT_PREFIX="${ACCOUNT}"
        REGION_PREFIX="${ACCOUNT_REGION}-"
        SEGMENT_SUFFIX=""

        # LEGACY: Support stacks created before slices added to account
        if [[ "${SLICE}" =~ s3 ]]; then
            if [[ -f "${CF_DIR}/${TYPE_PREFIX}${REGION_PREFIX}template.json" ]]; then
                SLICE_PREFIX=""
                SLICE_SUFFIX=""
            fi
        fi
        ;;

    product)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/cf"
        SEGMENT_SUFFIX=""

        # LEGACY: Support stacks created before slices added to product
        if [[ "${SLICE}" =~ cmk ]]; then
            if [[ -f "${CF_DIR}/${TYPE_PREFIX}${REGION_PREFIX}template.json" ]]; then
                SLICE_PREFIX=""
                SLICE_SUFFIX=""
            fi
        fi
        ;;

    solution)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf"
        TYPE_PREFIX="soln-"
        TYPE_SUFFIX="-soln"
        ;;

    segment)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf"
        TYPE_PREFIX="seg-"
        TYPE_SUFFIX="-seg"

        # LEGACY: Support old formats for existing stacks so they can be updated 
        if [[ !("${SLICE}" =~ cmk|cert|dns ) ]]; then
            if [[ -f "${CF_DIR}/cont-${SLICE_PREFIX}${REGION_PREFIX}template.json" ]]; then
                TYPE_PREFIX="cont-"
                TYPE_SUFFIX="-cont"
            fi
            if [[ -f "${CF_DIR}/container-${REGION}-template.json" ]]; then
                TYPE_PREFIX="container-"
                TYPE_SUFFIX="-container"
                SLICE_PREFIX=""
                SLICE_SUFFIX=""
            fi
            if [[ -f "${CF_DIR}/${SEGMENT}-container-template.json" ]]; then
                TYPE_PREFIX="${SEGMENT}-container-"
                TYPE_SUFFIX="-container"
                SLICE_PREFIX=""
                SLICE_SUFFIX=""
                REGION_PREFIX=""
            fi
        fi
        # "cmk" now used instead of "key"
        if [[ "${SLICE}" == "cmk" ]]; then
            if [[ -f "${CF_DIR}/${TYPE_PREFIX}key-${REGION_PREFIX}template.json" ]]; then
                SLICE_PREFIX="key-"
                SLICE_SUFFIX="-key"
            fi
        fi
        ;;

    application)
        CF_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf"
        TYPE_PREFIX="app-"
        TYPE_SUFFIX="-app"
        ;;

    *)
        echo -e "\n\"$TYPE\" is not one of the known stack types (account, product, segment, solution, application). Nothing to do."
        usage
        ;;
esac

STACKNAME="${PRODUCT_PREFIX}${SEGMENT_SUFFIX}${TYPE_SUFFIX}${SLICE_SUFFIX}"
TEMPLATE="${TYPE_PREFIX}${SLICE_PREFIX}${REGION_PREFIX}template.json"
STACK="${TYPE_PREFIX}${SLICE_PREFIX}${REGION_PREFIX}stack.json"

