#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults
INTEGRATIONS_FILE_DEFAULT="apigw.json"

function usage() {
    cat <<EOF

Create an extended Swagger specification

Usage: $(basename $0) -i SWAGGER_FILE -o EXTENDED_SWAGGER_FILE -p INTEGRATIONS_FILE

where

    -h                         shows this text
(m) -i INTEGRATIONS_FILE       contains patterns to match path+verb combinations to integration types
(m) -o EXTENDED_SWAGGER_FILE   is the output file required
(m) -s SWAGGER_FILE            is the source swagger JSON file

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

INTEGRATIONS_FILE = "${INTEGRATIONS_FILE_DEFAULT}"

NOTES:

1. The file produced contains the extensions requested. It needs to be merged
   with the original swagger file before being given to AWS.

EOF
    exit
}

# Parse options
while getopts ":hi:o:s:" opt; do
    case $opt in
        h)
            usage
            ;;
        i)
            INTEGRATIONS_FILE="${OPTARG}"
            ;;
        o)
            EXTENDED_SWAGGER_FILE="${OPTARG}"
            ;;
        s)
            SWAGGER_FILE="${OPTARG}"
            ;;
        \?)
            echo -e "\nInvalid option: -${OPTARG}" >&2
            exit
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument" >&2
            exit
            ;;
    esac
done

# Defaults
INTEGRATIONS_FILE="${INTEGRATIONS_FILE:-${INTEGRATIONS_FILE_DEFAULT}}"

# Ensure mandatory arguments have been provided
if [[ (-z "${SWAGGER_FILE}") ||
        (-z "${EXTENDED_SWAGGER_FILE}") ||
        (-z "${INTEGRATIONS_FILE}") ]]; then
    echo -e "\nInsufficient arguments" >&2
    exit
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Set up the type specific template information
TEMPLATE_DIR="${GENERATION_DIR}/templates"
TEMPLATE="createSwaggerExtensions.ftl"
SWAGGER_EXTENSIONS_FILE="temp_swagger_extensions.json"
SWAGGER_EXTENSIONS_PRE_POST_FILE="temp_swagger_pre_post.json"

ARGS=()
ARGS+=("-v" "region=${REGION}")
ARGS+=("-v" "productRegion=${PRODUCT_REGION}")
ARGS+=("-v" "accountRegion=${ACCOUNT_REGION}")
ARGS+=("-v" "blueprint=${COMPOSITE_BLUEPRINT}")
ARGS+=("-v" "credentials=${COMPOSITE_CREDENTIALS}")
ARGS+=("-v" "appsettings=${COMPOSITE_APPSETTINGS}")
ARGS+=("-v" "stackOutputs=${COMPOSITE_STACK_OUTPUTS}")

ARGS+=("-v" "swagger=${SWAGGER_FILE}")
ARGS+=("-v" "integrations=${INTEGRATIONS_FILE}")

${GENERATION_DIR}/freemarker.sh -t ${TEMPLATE} -d ${TEMPLATE_DIR} -o "${SWAGGER_EXTENSIONS_FILE}" "${ARGS[@]}"
RESULT=$?
if [[ "${RESULT}" -eq 0 ]]; then
    # Merge the two
    ${GENERATION_DIR}/manageJSON.sh -o "${SWAGGER_EXTENSIONS_PRE_POST_FILE}" "${SWAGGER_FILE}" "${SWAGGER_EXTENSIONS_FILE}"
    RESULT=$?
    if [[ "${RESULT}" -eq 0 ]]; then
        # TODO adjust next lines when path length limitations in jq are fixed
        POST_PROCESSING_FILTER="./temp_post_processing.jq"
        cp ${GENERATION_DIR}/postProcessSwagger.jq "${POST_PROCESSING_FILTER}"
        jq -f "${POST_PROCESSING_FILTER}" < "${SWAGGER_EXTENSIONS_PRE_POST_FILE}" > "${EXTENDED_SWAGGER_FILE}"
        RESULT=$?
    fi
fi

# Let last result become the result of this script
