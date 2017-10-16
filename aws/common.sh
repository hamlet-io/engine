#!/bin/bash

# Utility Functions
#
# This script is designed to be sourced into other scripts

# -- Error handling  --

function message() {
    local SEVERITY="${1}"; shift
    echo -e "\n(${SEVERITY})" "$@"
}

function locationMessage() {
    echo "$@" "Are we in the right place?"
}

function cantProceedMessage() {
    echo "$@" "Nothing to do."
}

function debug() {
    [[ -n "${GENERATION_DEBUG}" ]] && message "Debug" "$@"
}

function trace() {
    message "Trace" "$@"
}

function info() {
    message "Info" "$@"
}

function warning() {
    message "Warning" "$@"
}

function error() {
    message "Error" "$@" >&2
}

function fatal() {
    message "Fatal" "$@" >&2
    exit
}

function fatalOption() {
    fatal "Invalid option: \"-${1:-${OPTARG}}\""
}

function fatalOptionArgument() {
    fatal "Option \"-${1:-${OPTARG}}\" requires an argument"
}

function fatalCantProceed() {
    fatal $(cantProceedMessage "$@" )
}

function fatalLocation() {
    local NULLGLOB=$(shopt -p nullglob)
    local GLOBSTAR=$(shopt -p globstar)

    shopt -u nullglob globstar
    fatal $(locationMessage "$@")

    ${NULLGLOB}
    ${GLOBSTAR}
}

function fatalDirectory() {
    fatalLocation "We don't appear to be in the ${1} directory."
}

function fatalMandatory() {
    fatal "Mandatory arguments missing. Check usage via -h option."
}

# -- String manipulation --

function join() {
    local IFS="$1"; shift
    echo -n "$*"
}

function contains() {
#    echo [[ "${1}" =~ ${2} ]]
    [[ "${1}" =~ ${2} ]]
}

# -- File manipulation --
function formatPath() {
    join "/" "$@"
}

function filePath() {
    echo "${1%/*}"
}

function fileName() {
    echo "${1##*/}"
}

function fileBase() {
    local name=$(fileName "$@")
    echo "${name%.*}"
}

function fileExtension() {
    local name="$(fileName "$@")"
    echo "${name##*.}"
}

function fileContents() {
    [[ -f "${1}" ]] && cat "${1}"
}

function fileContentsInEnv() {
    local ENV="${1}"; shift

    for F in "$@"; do
        if [[ -f "${F}" ]]; then
             declare -gx "${ENV}=$(fileContents "${F}")"
            break
        fi
    done
}

function findAncestorDir() {
    local ANCESTOR="${1}"; shift
    local CURRENT="${1:-$(pwd)}"

    while [[ -n "${CURRENT}" ]]; do
        if [[ "$(fileName "${CURRENT}")" == "${ANCESTOR}" ]]; then
            echo -n "${CURRENT}"
            return 0
        fi
        CURRENT="$(filePath "${CURRENT}")"
    done
    return 1
}

function findDir() {
    local MARKER="${1}"; shift
    local ROOT_DIR="${1}"; shift
    local SUBDIRS_ONLY="${1}"

    local RESTORE_NULLGLOB=$(shopt -p nullglob)
    local RESTORE_GLOBSTAR=$(shopt -p globstar)
    shopt -s nullglob globstar

    [[ -n "${SUBDIRS_ONLY}" ]] &&
        MATCHES=("${ROOT_DIR}"/*/**/${MARKER}) ||
        MATCHES=("${ROOT_DIR}"/**/${MARKER})

    ${RESTORE_NULLGLOB}
    ${RESTORE_GLOBSTAR}

    [[ $(arrayIsEmpty "MATCHES") ]] && return 1

    [[ -f "${MATCHES[0]}" ]] &&
        echo -n "$(filePath "${MATCHES[0]}")" ||
        echo -n "${MATCHES[0]}"
    return 0
}

function findFile() {

    local RESTORE_NULLGLOB=$(shopt -p nullglob)
    local RESTORE_GLOBSTAR=$(shopt -p globstar)
    shopt -s nullglob globstar

    MATCHES=($@)

    ${RESTORE_NULLGLOB}
    ${RESTORE_GLOBSTAR}

    for MATCH in "${MATCHES[@]}"; do
        if [[ -f "${MATCH}" ]]; then
            echo -n "${MATCH}"
            return 0
        fi
    done

    return 1
}


# -- Array manipulation --

function inArray() {
    local ARRAY="${1}"; shift
    local PATTERN="${1}"

    eval "contains \"\${${ARRAY}[*]}\" \"${PATTERN}\""
}

function arraySize() {
    local ARRAY="${1}"

    eval "echo \"\${#${ARRAY}[@]}\""
}

function arrayIsEmpty() {
    local ARRAY="${1}"

    [[ $(arraySize "${ARRAY}") -eq 0 ]]
}

function addToArrayWithPrefix() {
    local ARRAY="${1}"; shift
    local PREFIX="${1}"; shift

    for ARG in "$@"; do
        if [[ -n "${ARG}" ]]; then
            eval "${ARRAY}+=(\"${PREFIX}${ARG}\")"
        fi
    done
}

function addToArray() {
    local ARRAY="${1}"; shift

    addToArrayWithPrefix "${ARRAY}" "" "$@"
}

function addToArrayHeadWithPrefix() {
    local ARRAY="${1}"; shift
    local PREFIX="${1}"; shift

    for ARG in "$@"; do
        if [[ -n "${ARG}" ]]; then
            eval "${ARRAY}=(\"${PREFIX}${ARG}\" \"\${${ARRAY}[@]}\")"
        fi
    done
}

function addToArrayHead() {
    local ARRAY="${1}"; shift

    addToArrayHeadWithPrefix "${ARRAY}" "" "$@"
}

# -- JSON manipulation --

function runJQ() {
    local RETURN_VALUE

    # TODO: remove once path length limitations in jq are fixed
    JQ_TEMP="./temp_jq_${RANDOM}"
    mkdir -p "${JQ_TEMP}"
    local JQ_ARGS=()
    local JQ_ARG_INDEX=0
    for ARG in "$@"; do
        if [[ -f "${ARG}" ]]; then
            local JQ_TEMP_FILE="${JQ_TEMP}/temp_${JQ_ARG_INDEX}"
            cp "${ARG}" "${JQ_TEMP_FILE}" > /dev/null
            JQ_ARGS+=("${JQ_TEMP_FILE}")
        else
            JQ_ARGS+=("${ARG}")
        fi
        ((JQ_ARG_INDEX++))
    done

    # TODO: Add -L once path length limitations fixed
    jq "${JQ_ARGS[@]}"
    RETURN_VALUE=$?

    if [[ ! -n "${GENERATION_DEBUG}" ]]; then
        rm -rf ./temp_jq
    fi
    return ${RETURN_VALUE}
}

function getJSONValue() {
    local JSON_FILE="${1}"; shift
    local VALUE

    for PATTERN in "$@"; do
        VALUE=$(runJQ -r "${PATTERN} | select (.!=null)" < "${JSON_FILE}")
        [[ -n "${VALUE}" ]] && echo "${VALUE}" && return 0
    done
    return 1
}

function addJSONParentObjects() {
    local JSON_FILE="${1}"; shift
    local PARENTS=("$@")

    local PATTERN="."
    for (( INDEX=${#PARENTS[@]}-1 ; INDEX >= 0 ; INDEX-- )) ; do
        PATTERN="{\"${PARENTS[INDEX]}\" : ${PATTERN} }"
    done

    runJQ "${PATTERN}" < "${JSON_FILE}"
}

# -- S3 --

function isBucketAccessible() {
    local region="${1}"; shift
    local bucket="${1}"; shift
    local prefix="${1}"

    aws --region ${region} s3 ls "s3://${bucket}/${prefix}${prefix:+/}" > temp_bucket_access.txt
    return $?
}

function syncFilesToBucket() {
    local region="${1}"; shift
    local bucket="${1}"; shift
    local prefix="${1}"; shift
    local filesArrayName="${1}[@]"; shift
    local dryrunOrDelete="${1} ${2}"

    local filesArray=("${!filesArrayName}")
    local tempDir="./temp_copyfiles"
    
    rm -rf "${tempDir}"
    mkdir  "${tempDir}"
    
    # Copy files locally so we can synch with S3, potentially including deletes
    for file in "${filesArray[@]}" ; do
        if [[ -n "${file}" ]]; then
            case ${file##*.} in
                zip)
                    unzip "${file}" -d "${tempDir}"
                    ;;
                *)
                    cp "${file}" "${tempDir}"
                    ;;
            esac
        fi
    done
    
    # Now synch with s3
    aws --region ${region} s3 sync ${dryrunOrDelete} "${tempDir}/" "s3://${bucket}/${prefix}${prefix:+/}"
}
function deleteTreeFromBucket() {
    local region="${1}"; shift
    local bucket="${1}"; shift
    local prefix="${1}"; shift
    local dryrun="${1}"

    # Delete everything below the prefix
    aws --region ${region} s3 rm --recursive ${dryrun} "s3://${bucket}/${prefix}/"
}

function syncCMDBFilesToOperationsBucket() {
    local sourceBaseDir="${1}"; shift
    local prefix="${1}"; shift
    local dryrun="${1}"; shift

    SYNC_FILES_ARRAY=()

    SYNC_FILES_ARRAY+=(${sourceBaseDir}/${SEGMENT}/asFile/*)
    SYNC_FILES_ARRAY+=(${sourceBaseDir}/${SEGMENT}/${DEPLOYMENT_UNIT}/asFile/*)
    SYNC_FILES_ARRAY+=(${sourceBaseDir}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/asFile/*)

    syncFilesToBucket ${REGION} $(getOperationsBucket) "${prefix}/${PRODUCT}/${SEGMENT}/${DEPLOYMENT_UNIT}" "SYNC_FILES_ARRAY" ${dryrun} --delete
}

function deleteCMDBFilesFromOperationsBucket() {
    local prefix="${1}"; shift
    local dryrun="${1}"; shift

    deleteTreeFromBucket ${REGION} $(getOperationsBucket)  "${prefix}/${PRODUCT}/${SEGMENT}${DEPLOYMENT_UNIT}" ${dryrun}
}

# -- Composites --

function parseStackFilename() {

    # Parse stack name for key values
    # Account is not yet part of the stack filename
    contains $(fileName "${1}") "([a-z0-9]+)-(.+)-([a-z]{2}-[a-z]+-[1-9])-stack.json"
    STACK_LEVEL="${BASH_REMATCH[1]}"
    STACK_ACCOUNT=""
    STACK_REGION="${BASH_REMATCH[3]}"
    STACK_DEPLOYMENT_UNIT="${BASH_REMATCH[2]}"
}

function getCompositeStackOutput() {
    local STACK_FILE="${1}"; shift
    local PATTERNS=()

    for KEY in "$@"; do
        PATTERNS+=(".[] | .${KEY} ")
    done
    getJSONValue "${STACK_FILE}" "${PATTERNS[@]}"
}

function getBucketName() {
    getCompositeStackOutput "${COMPOSITE_STACK_OUTPUTS}" "$@"
}

function getOperationsBucket() {
    getBucketName "s3XsegmentXops"
}

function getCodeBucket() {
    getBucketName "s3XaccountXcode"
}

function getCmk() {
    local LEVEL="${1}"; shift

    getCompositeStackOutput "${COMPOSITE_STACK_OUTPUTS}" "cmkX${LEVEL}" "cmkX${LEVEL}Xcmk"
}

function getBluePrintParameter() {
    getJSONValue "${COMPOSITE_BLUEPRINT}" "$@"
}


# -- GEN3 directory structure --

function findGen3RootDir() {
    local CURRENT="${1}"; shift

    local CONFIG_ROOT_DIR="$(filePath "$(findAncestorDir config "${CURRENT}")")"
    local INFRASTRUCTURE_ROOT_DIR="$(filePath "$(findAncestorDir infrastructure "${CURRENT}")")"
    local ROOT_DIR="${CONFIG_ROOT_DIR:-${INFRASTRUCTURE_ROOT_DIR}}"

    if [[ (-d "${ROOT_DIR}/config") && (-d "${ROOT_DIR}/infrastructure") ]]; then
        echo -n "${ROOT_DIR}"
        return 0
    fi
    return 1
}

function findGen3ProductDir() {
    local GEN3_ROOT_DIR="${1}"; shift
    local GEN3_PRODUCT="${1:=${PRODUCT}}"

    findDir "${GEN3_PRODUCT}/product.json" "${GEN3_ROOT_DIR}"
}

function findGen3SegmentDir() {
    local GEN3_ROOT_DIR="${1}"; shift
    local GEN3_PRODUCT="${1:-${PRODUCT}}"; shift
    local GEN3_SEGMENT="${1:-${SEGMENT}}"; shift

    local GEN3_PRODUCT_DIR="$(findGen3ProductDir "${GEN3_ROOT_DIR}" "${GEN3_PRODUCT}")"
    [[ -z "${GEN3_PRODUCT_DIR}" ]] && return 1

    findDir "solutions/${GEN3_SEGMENT}/segment.json"   "${GEN3_PRODUCT_DIR}" ||
    findDir "solutions/${GEN3_SEGMENT}/container.json" "${GEN3_PRODUCT_DIR}"
}

function getGen3Env() {
    local GEN3_ENV="${1}"; shift
    local GEN3_PREFIX="${1}"; shift

    local GEN3_ENV_NAME="${GEN3_PREFIX}${GEN3_ENV}"
    echo "${!GEN3_ENV_NAME}"
}

function checkGen3Dir() {
    local GEN3_ENV="${1}"; shift
    local GEN3_PREFIX="${1}"; shift

    local GEN3_ENV_NAME="${GEN3_PREFIX}${GEN3_ENV}"
    for DIR in "$@"; do
        if [[ -d "${DIR}" ]]; then
            declare -gx "${GEN3_ENV_NAME}=${DIR}"
            return 0
        fi
    done

    error $(locationMessage "Can't locate ${GEN3_ENV} directory.")
    return 1
}

function findGen3Dirs() {
    local GEN3_ROOT_DIR="${1}"; shift
    local GEN3_ACCOUNT="${1:-${ACCOUNT}}"; shift
    local GEN3_PRODUCT="${1:-${PRODUCT}}"; shift     
    local GEN3_SEGMENT="${1:-${SEGMENT}}"; shift
    local GEN3_PREFIX="${1}"; shift

    checkGen3Dir "CONFIG_DIR" "${GEN3_PREFIX}" \
        "${GEN3_ROOT_DIR}/config" || return 1
    checkGen3Dir "INFRASTRUCTURE_DIR" "${GEN3_PREFIX}" \
        "${GEN3_ROOT_DIR}/infrastructure" || return 1

    checkGen3Dir "TENANT_DIR" "${GEN3_PREFIX}" \
        "$(findDir "tenant.json" "${GEN3_ROOT_DIR}")" || return 1
    checkGen3Dir "ACCOUNT_DIR" "${GEN3_PREFIX}" \
        "$(findDir "${GEN3_ACCOUNT}/account.json" "${GEN3_ROOT_DIR}")" || return 1
    checkGen3Dir "ACCOUNT_INFRASTRUCTURE_DIR" "${GEN3_PREFIX}" \
        "$(findDir "${GEN3_ACCOUNT}" "${GEN3_ROOT_DIR}/infrastructure")" || return 1
    eval "export ${GEN3_PREFIX}ACCOUNT_APPSETTINGS_DIR=$(getGen3Env "ACCOUNT_DIR" "${GEN3_PREFIX}")/appsettings"
    eval "export ${GEN3_PREFIX}ACCOUNT_CREDENTIALS_DIR=$(getGen3Env "ACCOUNT_INFRASTRUCTURE_DIR" "${GEN3_PREFIX}")/credentials"

    if [[ -n "${GEN3_PRODUCT}" ]]; then
        checkGen3Dir "PRODUCT_DIR" "${GEN3_PREFIX}" \
            "$(findGen3ProductDir "${GEN3_ROOT_DIR}" "${GEN3_PRODUCT}")" || return 1
        checkGen3Dir "PRODUCT_INFRASTRUCTURE_DIR" "${GEN3_PREFIX}" \
            "$(findDir "${GEN3_PRODUCT}" "${GEN3_ROOT_DIR}/infrastructure")" || return 1
        eval "export ${GEN3_PREFIX}PRODUCT_APPSETTINGS_DIR=$(getGen3Env "PRODUCT_DIR" "${GEN3_PREFIX}")/appsettings"
        eval "export ${GEN3_PREFIX}PRODUCT_SOLUTIONS_DIR=$(getGen3Env "PRODUCT_DIR" "${GEN3_PREFIX}")/solutions"
        eval "export ${GEN3_PREFIX}PRODUCT_CREDENTIALS_DIR=$(getGen3Env "PRODUCT_INFRASTRUCTURE_DIR" "${GEN3_PREFIX}")/credentials"
        if [[ -n "${GEN3_SEGMENT}" ]]; then
            checkGen3Dir "SEGMENT_DIR"  "${GEN3_PREFIX}" \
                "$(findGen3SegmentDir "${GEN3_ROOT_DIR}" "${GEN3_PRODUCT}" "${GEN3_SEGMENT}")" || return 1
            eval "export ${GEN3_PREFIX}SEGMENT_APPSETTINGS_DIR=$(getGen3Env "PRODUCT_APPSETTINGS_DIR" "${GEN3_PREFIX}")/${GEN3_SEGMENT}"
            eval "export ${GEN3_PREFIX}SEGMENT_CREDENTIALS_DIR=$(getGen3Env "PRODUCT_CREDENTIALS_DIR" "${GEN3_PREFIX}")/${GEN3_SEGMENT}"
        fi
    fi
}

function checkInRootDirectory() {
    [[ ! ("root" =~ "${1:-${LOCATION}}") ]] && fatalDirectory "root"
}

function checkInSegmentDirectory() {
    [[ ! ("segment" =~ "${1:-${LOCATION}}") ]] && fatalDirectory "segment"
}

function checkInProductDirectory() {
    [[ ! ("product" =~ "${1:-${LOCATION}}") ]] && fatalDirectory "product"
}

function checkInAccountDirectory() {
    [[ ! ("account" =~ "${1:-${LOCATION}}") ]] && fatalDirectory "account"
}

function fatalProductOrSegmentDirectory() {
    fatalDirectory "product or segment"
}

function buildAppSettings () {
    local ROOT_DIR="${1}"; shift
    local FILE_PATTERN="${1}"; shift
    local ANCESTORS=("$@")
    
    local NULLGLOB=$(shopt -p nullglob)
    shopt -s nullglob
    
    for FILE in "${ROOT_DIR}"/${FILE_PATTERN}; do
        echo Processing ${FILE} to "$(filePath "${FILE}")/temp_$(fileName "${FILE}")"
        addJSONParentObjects "${FILE}" "${PARENTS[@]}" > "$(filePath "${FILE}")/temp_$(fileName "${FILE}")"
    done

    ${NULLGLOB}

    local CHILDREN=($(find "${ROOT_DIR}" -maxdepth 1 -type d ! -path "${ROOT_DIR}"))
#    echo CHILDREN="${CHILDREN[@]}"
    for CHILD in "${CHILDREN[@]}"; do
        addJSONParentDirs "${CHILD}" "${FILE_PATTERN}" "${PARENTS[@]}" "$(fileName "${CHILD}")"
    done
    
}

