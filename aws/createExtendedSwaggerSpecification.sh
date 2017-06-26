#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'rm -rf temp_*; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

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

1. A file is produced for every combination of region and account included in
   the integrations file with the account and region appended to the provided 
   filename with "-" separators.
2. If EXTENDED_SWAGER_FILE ends with a ".zip" extension, then the generated
   files are packaged into a zip file.
3. The files produced contain the swagger extensions requested.

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

# Determine the base of the resulting files
EXTENDED_SWAGGER_FILE_BASE="${EXTENDED_SWAGGER_FILE%.*}"
EXTENDED_SWAGGER_FILE_PATH="${EXTENDED_SWAGGER_FILE%/*}"
EXTENDED_SWAGGER_FILE_EXTENSION="${EXTENDED_SWAGGER_FILE##*.}"
EXTENDED_SWAGGER_FILE_BASENAME="${EXTENDED_SWAGGER_FILE##*/}"

# Determine the accounts and regions
ACCOUNTS=($(jq -r '.Accounts | select(.!=null) | .[]' < ${INTEGRATIONS_FILE} | tr -s [:space:] ' '))
REGIONS=($(jq -r '.Regions | select(.!=null) | .[]' < ${INTEGRATIONS_FILE} | tr -s [:space:] ' '))

# TODO adjust next lines when path length limitations in jq are fixed
POST_PROCESSING_FILTER="./temp_post_processing.jq"
cp ${GENERATION_DIR}/postProcessSwagger.jq "${POST_PROCESSING_FILTER}"
            
# Set up the type specific template information
TEMPLATE_DIR="${GENERATION_DIR}/templates"
TEMPLATE="createSwaggerExtensions.ftl"
SWAGGER_EXTENSIONS_FILE="temp_swagger_extensions.json"
SWAGGER_EXTENSIONS_PRE_POST_FILE="temp_swagger_pre_post.json"

# Process the required accounts and regions
mkdir -p temp_results_dir
for ACCOUNT in "${ACCOUNTS[@]}"; do
    for REGION in "${REGIONS[@]}"; do

        TARGET_SWAGGER_FILE="temp_results_dir/${EXTENDED_SWAGGER_FILE_BASENAME}-${ACCOUNT}-${REGION}.json"

        ARGS=()
        ARGS+=("-v" "account=${ACCOUNT}")
        ARGS+=("-v" "region=${REGION}")
        ARGS+=("-v" "swagger=${SWAGGER_FILE}")
        ARGS+=("-v" "integrations=${INTEGRATIONS_FILE}")
        
        ${GENERATION_DIR}/freemarker.sh -t ${TEMPLATE} -d ${TEMPLATE_DIR} -o "${SWAGGER_EXTENSIONS_FILE}" "${ARGS[@]}"
        RESULT=$?
        [[ "${RESULT}" -ne 0 ]] && exit

        # Merge the two
        ${GENERATION_DIR}/manageJSON.sh -o "${SWAGGER_EXTENSIONS_PRE_POST_FILE}" "${SWAGGER_FILE}" "${SWAGGER_EXTENSIONS_FILE}"
        RESULT=$?
        [[ "${RESULT}" -ne 0 ]] && exit

        # Post processing
        jq -f "${POST_PROCESSING_FILTER}" < "${SWAGGER_EXTENSIONS_PRE_POST_FILE}" > "${TARGET_SWAGGER_FILE}"
        RESULT=$?
        [[ "${RESULT}" -ne 0 ]] && exit
        
    done
done

# If the target is a zip file, zip up the generated files
cd temp_results_dir
if [[ "${EXTENDED_SWAGGER_FILE_EXTENSION}" == "zip" ]]; then
    zip ${EXTENDED_SWAGGER_FILE_BASENAME}.zip ${EXTENDED_SWAGGER_FILE_BASENAME}-*.json
else
    cp ${EXTENDED_SWAGGER_FILE_BASENAME}-*.json "${EXTENDED_SWAGGER_FILE_PATH}"
fi

# All good
RESULT=0
