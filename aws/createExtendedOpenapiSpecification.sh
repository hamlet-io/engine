#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '[[ (-z "${GENERATION_DEBUG}") && (-n "${tmpdir}") ]] && rm -rf "${tmpdir}"; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Create a temporary directory for this run
pushTempDir "cot_gw_XXXXXX"
export GENERATION_TMPDIR="$(getTopTempDir)"
debug "TMPDIR=${GENERATION_TMPDIR}"

tmp_dir="${GENERATION_TMPDIR}"

# Defaults
INTEGRATIONS_FILE_DEFAULT="apigw.json"

function usage() {
    cat <<EOF

Create an extended OpenAPI specification

Usage: $(basename $0) -i OPENAPI_FILE -o EXTENDED_OPENAPI_FILE -p INTEGRATIONS_FILE

where

    -h                         shows this text
(m) -i INTEGRATIONS_FILE       contains patterns to match path+verb combinations to integration types
(m) -o EXTENDED_OPENAPI_FILE   is the output file required
(m) -s OPENAPI_FILE            is the source openAPI JSON file

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

INTEGRATIONS_FILE = "${INTEGRATIONS_FILE_DEFAULT}"

NOTES:

1. A file is produced for every combination of region and account included in
   the integrations file with the account and region appended to the provided
   filename with "-" separators.
2. If EXTENDED_OPENAPI_FILE ends with a ".zip" extension, then the generated
   files are packaged into a zip file.
3. The files produced contain the openAPI extensions requested.

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
            EXTENDED_OPENAPI_FILE="${OPTARG}"
            ;;
        s)
            OPENAPI_FILE="${OPTARG}"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Defaults
INTEGRATIONS_FILE="${INTEGRATIONS_FILE:-${INTEGRATIONS_FILE_DEFAULT}}"

# Ensure mandatory arguments have been provided
[[ (-z "${OPENAPI_FILE}") ||
    (-z "${EXTENDED_OPENAPI_FILE}") ||
    (-z "${INTEGRATIONS_FILE}") ]] && fatalMandatory

# Determine the base of the resulting files
EXTENDED_OPENAPI_FILE_PATH="${EXTENDED_OPENAPI_FILE%/*}"
EXTENDED_OPENAPI_FILE_BASENAME="${EXTENDED_OPENAPI_FILE##*/}"
EXTENDED_OPENAPI_FILE_EXTENSION="${EXTENDED_OPENAPI_FILE_BASENAME##*.}"
EXTENDED_OPENAPI_FILE_BASE="${EXTENDED_OPENAPI_FILE_BASENAME%.*}"

# Determine the accounts and regions
ACCOUNTS=($(jq -r '.Accounts | select(.!=null) | .[]' < ${INTEGRATIONS_FILE} | tr -s [:space:] ' '))
REGIONS=($(jq -r '.Regions | select(.!=null) | .[]' < ${INTEGRATIONS_FILE} | tr -s [:space:] ' '))

# TODO adjust next lines when path length limitations in jq are fixed
POST_PROCESSING_FILTER="${tmp_dir}/pp.jq"
cp ${GENERATION_DIR}/postProcessOpenapi.jq "${POST_PROCESSING_FILTER}"

# Set up the type specific template information
TEMPLATE_DIR="${GENERATION_DIR}/templates"
TEMPLATE="createOpenapiExtensions.ftl"
OPENAPI_EXTENSIONS_FILE="${tmp_dir}/openapi_extensions.json"
OPENAPI_EXTENSIONS_PRE_POST_FILE="${tmp_dir}/openapi_pre_post.json"

# Process the required accounts and regions
tmp_results_dir="${tmp_dir}/extensions"
mkdir -p "${tmp_results_dir}"

for ACCOUNT in "${ACCOUNTS[@]}"; do
    for REGION in "${REGIONS[@]}"; do

        TARGET_OPENAPI_FILE="${tmp_results_dir}/${EXTENDED_OPENAPI_FILE_BASE}-${REGION}-${ACCOUNT}.json"

        ARGS=()
        ARGS+=("-v" "account=${ACCOUNT}")
        ARGS+=("-v" "region=${REGION}")
        ARGS+=("-v" "openapi=${OPENAPI_FILE}")
        ARGS+=("-v" "integrations=${INTEGRATIONS_FILE}")

        ${GENERATION_DIR}/freemarker.sh -t ${TEMPLATE} -d ${TEMPLATE_DIR} -o "${OPENAPI_EXTENSIONS_FILE}" "${ARGS[@]}"
        RESULT=$?
        [[ "${RESULT}" -ne 0 ]] && exit

        # Merge the two
        ${GENERATION_DIR}/manageJSON.sh -o "${OPENAPI_EXTENSIONS_PRE_POST_FILE}" "${OPENAPI_FILE}" "${OPENAPI_EXTENSIONS_FILE}"
        RESULT=$?
        [[ "${RESULT}" -ne 0 ]] && exit

        # Post processing
        jq -f "${POST_PROCESSING_FILTER}" < "${OPENAPI_EXTENSIONS_PRE_POST_FILE}" > "${TARGET_OPENAPI_FILE}"
        RESULT=$?
        [[ "${RESULT}" -ne 0 ]] && exit

    done
done

# If the target is a zip file, zip up the generated files
cd "${tmp_results_dir}"
if [[ "${EXTENDED_OPENAPI_FILE_EXTENSION}" == "zip" ]]; then
    cp "${OPENAPI_FILE}" "${EXTENDED_OPENAPI_FILE_BASE}-extended-base.json"
    zip ${EXTENDED_OPENAPI_FILE_BASE}.zip *.json
    rm *.json
fi
cp * "${EXTENDED_OPENAPI_FILE_PATH}"

# All good
RESULT=0
