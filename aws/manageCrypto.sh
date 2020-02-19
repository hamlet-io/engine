#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

BASE64_REGEX="^[A-Za-z0-9+/=\n]\+$"

# Defaults
CRYPTO_OPERATION_DEFAULT="decrypt"
CRYPTO_FILENAME_DEFAULT="credentials.json"
PREFIX_DEFAULT="base64"

tmp_dir="$(getTempDir "cote_crypto_XXX")"

function usage() {
    cat <<EOF

Manage cryptographic operations using KMS

Usage: $(basename $0) -e -d -n -b -u -v -q
                        -f CRYPTO_FILE
                        -p JSON_PATH
                        -t CRYPTO_TEXT
                        -a ALIAS
                        -k KEYID
                        -x PREFIX

where

(o) -a ALIAS        for the master key to be used
(o) -b              force base64 decode of the input before processing
(o) -d              decrypt operation
(o) -e              encrypt operation
(o) -f CRYPTO_FILE  specifies a file which contains the plaintext or ciphertext to be processed
    -h              shows this text
(o) -k KEYID        for the master key to be used
(o) -n              no alteration to CRYPTO_TEXT (pass through as is)
(o) -p JSON_PATH    is the path to the attribute within CRYPTO_FILE to be processed
(o) -q              don't display result (quiet)
(o) -t CRYPTO_TEXT  is the plaintext or ciphertext to be processed
    -u              update the attribute at JSON_PATH (if provided), or replace CRYPTO_FILE with operation result
    -v              result is base64 decoded (visible)
(o) -x              prefix (without colon) to prepend with colon separator to cyphertext if encrypting

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

OPERATION = ${CRYPTO_OPERATION_DEFAULT}
FILENAME = ${CRYPTO_FILENAME_DEFAULT}
PREFIX = ${PREFIX_DEFAULT}

NOTES:

1. If a file is required but not provided, the default filename
     will be expected in the equivalent directory of the infrastructure tree
2. If JSON_PATH is provided,
   - a CRYPTO_FILE is required
   - the targetted file must be JSON format
   - encrypt requires CRYPTO_TEXT to be provided, or for the attribute to
     to present
   - attribute is updated with the operation result if update flag is set
3. If JSON_PATH is NOT provided,
   - one of CRYPTO_FILE or CRYPTO_TEXT must be provided
   - CRYPTO_TEXT takes precedence over CRYPTO_FILE
4. If a file at CRYPTO_FILE can't be located based on current directory, it will be
   treated as a relative directory using the default filename
5. Don't include "alias/" in any provided alias
6. If encrypting, the key is located as follows,
   - use KEYID if provided
   - use ALIAS if provided
   - if in segment directory, use segment keyid if available
   - if in product directory, use product keyid if available
   - if in account directory, use account keyid if available
   - otherwise error
7. The result is sent to stdout and is base64 encoded unless the
   visibility flag is set
8. Decrypted files will have a ".decrypted" extension added so they can be ignored by git

EOF
    exit
}

function options() {
    # Parse options
    while getopts ":a:bdef:hk:np:qt:uvx:" opt; do
        case $opt in
            a)
                ALIAS="${OPTARG}"
                ;;
            b)
                CRYPTO_DECODE="true"
                ;;
            d)
                CRYPTO_OPERATION="decrypt"
                ;;
            e)
                CRYPTO_OPERATION="encrypt"
                ;;
            f)
                CRYPTO_FILE="${OPTARG}"
                ;;
            h)
                usage
                ;;
            k)
                KEYID="${OPTARG}"
                ;;
            n)
                CRYPTO_OPERATION="noop"
                ;;
            p)
                JSON_PATH="${OPTARG}"
                ;;
            q)
                CRYPTO_QUIET="true"
                ;;
            t)
                CRYPTO_TEXT="${OPTARG}"
                ;;
            u)
                CRYPTO_UPDATE="true"
                ;;
            v)
                CRYPTO_VISIBLE="true"
                ;;
            x)
                PREFIX="${OPTARG}"
                ;;
            \?)
                fatalOption
                ;;
            :)
                fatalOptionArgument
                ;;
        esac
    done

    CRYPTO_OPERATION="${CRYPTO_OPERATION:-$CRYPTO_OPERATION_DEFAULT}"

    return 0
}

function main() {

    options "$@" || return $?

    # Set up the context - LOCATION will tell us where we are
    . "${GENERATION_BASE_DIR}/execution/setContext.sh"

    # Set up the list of files to check
    FILES=()
    if [[ (-n "${CRYPTO_FILE}") ]]; then
        FILES+=("${CRYPTO_FILE}")
        FILES+=("./${CRYPTO_FILE}/${CRYPTO_FILENAME_DEFAULT}")
    fi

    # Try and locate the key material
    if [[ (-z "${KEYID}") && (-n "${ALIAS}") ]]; then
        KEYID="alias/${ALIAS}"
    fi

    # If not provided find the key using the cmdb
    if [[ -z "${KEYID}" && "${CRYPTO_OPERATION}" == "encrypt" ]]; then

        info "Finding Segment CMK..."
        ${GENERATION_DIR}/createBuildblueprint.sh -u baseline -o "${tmp_dir}/" >/dev/null || return $?

        BUILD_BLUEPRINT="${tmp_dir}/build_blueprint-baseline-config.json"

        case "${LOCATION}" in
            "segment")

                arrayFromList "KEY_IDS" "$(jq -r '.Occurrence.Occurrences[] | select( .Core.Type == "baselinekey" and .Configuration.Solution.Engine == "cmk" ) | .State.Attributes.ARN' < ${BUILD_BLUEPRINT})"

                if [[ "$(arraySize "KEY_IDS" )" > 1 ]]; then
                    fatal "Multiple keys found - please run again using the -k parameter"
                    fatal "Keys Found: $(listFromArray "KEYID" )"
                    return 255
                else
                    KEYID="${KEY_IDS[0]}"
                fi
                ;;

            "account"|"root"|"integrator")

                KEYID="$(jq -r '.Occurrence.Occurrences[] | select( .Core.Type == "baselinekey" and .Configuration.Solution.Engine == "cmk-account" ) | .State.Attributes.ARN' < ${BUILD_BLUEPRINT})"

                ;;
        esac

        if [[ -z "${KEYID}" ]]; then
            fatal "No key material available"
            return 255
        fi

        debug "Key to be used is ${KEYID}"
    fi

    # Location base file search
    case "${LOCATION}" in

        "segment")
            if [[ -n "${CRYPTO_FILE}" ]]; then
                FILES+=("${SEGMENT_OPERATIONS_DIR}/${CRYPTO_FILE}")
            fi
            FILES+=("${SEGMENT_OPERATIONS_DIR}/${CRYPTO_FILENAME_DEFAULT}")
            ;;

        "account")
            if [[ -n "${CRYPTO_FILE}" ]]; then
                FILES+=("${ACCOUNT_OPERATIONS_DIR}/${CRYPTO_FILENAME_DEFAULT}")
            fi
            FILES+=("${ACCOUNT_OPERATIONS_DIR}/${CRYPTO_FILENAME_DEFAULT}")
    esac

    # Try and locate  file
    for F in "${FILES[@]}"; do
        if [[ -f "${F}" ]]; then
            TARGET_FILE="${F}"
            debug "Target file is ${TARGET_FILE}"
            break
        fi
    done

    # Ensure mandatory arguments have been provided
    if [[ (-n "${JSON_PATH}") ]]; then

        if [[ -z "${TARGET_FILE}" ]]; then
            fatal "Can't locate target file"
            return 255
        fi

        PATH_PARTS=(${JSON_PATH//./ })

        # Use jq [] syntax to handle dash in parts
        ESCAPED_JSON_PATH="."
        for PATH_PART in "${PATH_PARTS[@]}"; do
            ESCAPED_JSON_PATH="${ESCAPED_JSON_PATH}[\"${PATH_PART}\"]"
        done

        debug "jq path in file is ${ESCAPED_JSON_PATH}"

        # Default cipherdata to that in the element
        JSON_TEXT=$(jq -r "${ESCAPED_JSON_PATH} | select (.!=null)" < "${TARGET_FILE}")
        CRYPTO_TEXT="${CRYPTO_TEXT:-$JSON_TEXT}"

        [[ (("${CRYPTO_OPERATION}" == "encrypt") && (-z "${CRYPTO_TEXT}")) ]] &&
            fatal "Nothing to encrypt"
    else
        if [[ -z "${CRYPTO_TEXT}" ]]; then
            [[ -z "${CRYPTO_FILE}" ]] && insufficientArgumentsError && return 255
            [[ -z "${TARGET_FILE}" ]] && fatal "Can't locate file based on provided path" && return 255

            # Default cipherdata to the file contents
            FILE_TEXT=$( cat "${TARGET_FILE}")
            CRYPTO_TEXT="${CRYPTO_TEXT:-$FILE_TEXT}"
        fi
    fi

    # Strip any explicit prefix indication of encoding/encryption engine
    if [[ $(grep "^${PREFIX}:" <<< "${CRYPTO_TEXT}") ]]; then
        [[ "${PREFIX,,}" == "base64" ]] && CRYPTO_DECODE="true"
        CRYPTO_TEXT="${CRYPTO_TEXT#${PREFIX}:}"
    fi

    ciphertext_src="${tmp_dir}/ciphertext.src"
    ciphertext_bin="${tmp_dir}/ciphertext.bin"

    # Prepare ciphertext for processing
    echo -n "${CRYPTO_TEXT}" > "${ciphertext_src}"

    # base64 decode if necessary
    if [[ (-n "${CRYPTO_DECODE}") ]]; then
        # Sanity check on input
        dos2unix < "${ciphertext_src}" | grep -q "${BASE64_REGEX}"
        RESULT=$?
        if [[ "${RESULT}" -eq 0 ]]; then
            dos2unix < "${ciphertext_src}" | base64 -d  > "${ciphertext_bin}"
        else
            fatal "Input doesn't appear to be base64 encoded"
            return 255
        fi
    else
        mv "${ciphertext_src}" "${ciphertext_bin}"
    fi

    # Perform the operation
    case ${CRYPTO_OPERATION} in
        encrypt)
            CRYPTO_TEXT=$(cd "${tmp_dir}"; aws --region ${REGION} --output text kms encrypt \
                --key-id "${KEYID}" --query CiphertextBlob \
                --plaintext "fileb://ciphertext.bin")
            ;;

        decrypt)
            CRYPTO_TEXT=$(cd "${tmp_dir}"; aws --region ${REGION} --output text kms decrypt \
                --query Plaintext \
                --ciphertext-blob "fileb://ciphertext.bin")
            ;;
        noop)
            # Don't touch CRYPTO_TEXT so either existing value will be displayed, or
            # unchanged value will be saved.
            RESULT=0
            ;;
    esac
    RESULT=$?

    if [[ "${RESULT}" -eq 0 ]]; then
        # Decode if required
        if [[ "${CRYPTO_VISIBLE}" == "true" ]]; then
            CRYPTO_TEXT=$(dos2unix <<< "${CRYPTO_TEXT}" | base64 -d)
        fi

        # Update if required
        if [[ "${CRYPTO_UPDATE}" == "true" ]]; then
            if [[ -n "${JSON_PATH}" ]]; then
                if [[ "${CRYPTO_OPERATION}" == "encrypt" ]]; then
                    CRYPTO_TEXT="${PREFIX:+${PREFIX}:}${CRYPTO_TEXT}"
                fi
                jq --indent 4 "${ESCAPED_JSON_PATH}=\"${CRYPTO_TEXT}\"" < "${TARGET_FILE}"  > "${tmp_dir}/${CRYPTO_FILENAME_DEFAULT}"
                RESULT=$?
                if [[ "${RESULT}" -eq 0 ]]; then
                    mv "${tmp_dir}/${CRYPTO_FILENAME_DEFAULT}" "${TARGET_FILE}"
                fi
            else
                echo "${CRYPTO_TEXT}" > "${tmp_dir}/${CRYPTO_FILENAME_DEFAULT}"
                RESULT=$?
                if [[ "${RESULT}" -eq 0 ]]; then
                    if [[ "${CRYPTO_OPERATION}" == "decrypt" ]]; then
                        mv "${tmp_dir}/${CRYPTO_FILENAME_DEFAULT}" "${TARGET_FILE}.decrypted"
                    else
                        mv "${tmp_dir}/${CRYPTO_FILENAME_DEFAULT}" "${TARGET_FILE}"
                    fi
                fi
            fi
        fi
    fi

    if [[ ("${RESULT}" -eq 0) && ( "${CRYPTO_QUIET}" != "true") ]]; then
        # Display result
        echo "${CRYPTO_TEXT}"
    fi

    return 0
}

main "$@"
