#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

BASE64_REGEX="^[A-Za-z0-9+/=\n]\+$"

# Defaults
CRYPTO_OPERATION_DEFAULT="decrypt"
CRYPTO_FILENAME_DEFAULT="credentials.json"

function usage() {
    cat <<-EOF
		Manage cryptographic operations using KMS
		Usage: $(basename $0) -e -d -n -f CRYPTO_FILE -p JSON_PATH -t CRYPTO_TEXT -a ALIAS -k KEYID -b -u -v -q
		where
		(o) -a ALIAS for the master key to be used
		(o) -b force base64 decode of the input before processing
		(o) -d decrypt operation
		(o) -e encrypt operation
		(o) -f CRYPTO_FILE specifies a file which contains the plaintext or ciphertext to be processed
		    -h shows this text
		(o) -k KEYID for the master key to be used
		(o) -n no alteration to CRYPTO_TEXT (pass through as is)
		(o) -p JSON_PATH is the path to the attribute within CRYPTO_FILE to be processed
		(o) -q don't display result (quiet)
		(o) -t CRYPTO_TEXT is the plaintext or ciphertext to be processed
		    -u update the attribute at JSON_PATH (if provided), or replace CRYPTO_FILE with operation result
		    -v result is base64 decoded (visible)
		DEFAULTS:
		OPERATION = ${CRYPTO_OPERATION_DEFAULT}
		FILENAME = ${CRYPTO_FILENAME_DEFAULT}
		NOTES:\n
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

# Parse options
while getopts ":a:bdef:hk:np:qt:uv" opt; do
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
        \?)
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument"
            usage
            ;;
    esac
done

CRYPTO_OPERATION="${CRYPTO_OPERATION:-$CRYPTO_OPERATION_DEFAULT}"

# Set up the context - LOCATION will tell us where we are
. ${GENERATION_DIR}/setContext.sh

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
if [[ "segment" =~ ${LOCATION} ]]; then
    KEYID=${KEYID:-$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r '.[] | select(.OutputKey=="cmkXsegmentXcmk") | .OutputValue | select (.!=null)')}
    if [[ -n "${CRYPTO_FILE}" ]]; then FILES+=("${INFRASTRUCTURE_DIR}/${PRODUCT}/credentials/${SEGMENT}/${CRYPTO_FILE}"); fi
    FILES+=("${INFRASTRUCTURE_DIR}/${PRODUCT}/credentials/${SEGMENT}/${CRYPTO_FILENAME_DEFAULT}")
fi
if [[ "product" =~ ${LOCATION} ]]; then
    KEYID=${KEYID:-$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r '.[] | select(.OutputKey=="cmkXproductXcmk") | .OutputValue | select (.!=null)')}
    if [[ -n "${CRYPTO_FILE}" ]]; then FILES+=("${INFRASTRUCTURE_DIR}/${PRODUCT}/credentials/${CRYPTO_FILE}"); fi
    FILES+=("${INFRASTRUCTURE_DIR}/${PRODUCT}/credentials/${CRYPTO_FILENAME_DEFAULT}")
fi
if [[ "account" =~ ${LOCATION} ]]; then
    KEYID=${KEYID:-$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r '.[] | select(.OutputKey=="cmkXaccountXcmk") | .OutputValue | select (.!=null)')}
    if [[ -n "${CRYPTO_FILE}" ]]; then FILES+=("${INFRASTRUCTURE_DIR}/${ACCOUNT}/credentials/${CRYPTO_FILENAME_DEFAULT}"); fi
    FILES+=("${INFRASTRUCTURE_DIR}/${ACCOUNT}/credentials/${CRYPTO_FILENAME_DEFAULT}")
fi
if [[ ("root" =~ ${LOCATION}) || ("integrator" =~ ${LOCATION}) ]]; then
    KEYID=${KEYID:-$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r '.[] | select(.OutputKey=="cmkXaccountXcmk") | .OutputValue | select (.!=null)')}
fi

# Try and locate  file 
for F in "${FILES[@]}"; do
    if [[ -f "${F}" ]]; then
        TARGET_FILE="${F}"
        break
    fi 
done

# Ensure mandatory arguments have been provided
if [[ (-n "${JSON_PATH}") ]]; then
    if [[ -z "${TARGET_FILE}" ]]; then
        echo -e "\nCan't locate target file"
        usage
    fi
    # Default cipherdata to that in the element
    JSON_TEXT=$(cat "${TARGET_FILE}" | jq -r "${JSON_PATH} | select (.!=null)" )
    CRYPTO_TEXT="${CRYPTO_TEXT:-$JSON_TEXT}"

    if [[ (("${CRYPTO_OPERATION}" == "encrypt") && (-z "${CRYPTO_TEXT}")) ]]; then
        echo -e "\nNothing to encrypt"
        usage
    fi
else    
    if [[ -z "${CRYPTO_TEXT}" ]]; then
        if [[ -z "${CRYPTO_FILE}" ]]; then
            echo -e "\nInsufficient arguments"
            usage
        else
            if [[ -z "${TARGET_FILE}" ]]; then
                echo -e "\nCan't locate file based on provided path"
                usage
            fi
        fi
        # Default cipherdata to the file contents
        FILE_TEXT=$(cat "${TARGET_FILE}" )
        CRYPTO_TEXT="${CRYPTO_TEXT:-$FILE_TEXT}"
    fi
fi
    
if [[ ("${CRYPTO_OPERATION}" == "encrypt") && (-z "${KEYID}") ]]; then
    echo -e "\nNo key material available"
    usage
fi

# Prepare ciphertext for processing
echo -n "${CRYPTO_TEXT}" > ./ciphertext.src

# base64 decode if necessary
if [[ -n "${CRYPTO_DECODE}" ]]; then
    # Sanity check on input
    dos2unix < ./ciphertext.src | grep -q "${BASE64_REGEX}"
    RESULT=$?
    if [[ "${RESULT}" -eq 0 ]]; then
        dos2unix < ./ciphertext.src | base64 -d  > ./ciphertext.bin
    else
        echo -e "\nInput doesn't appear to be base64 encoded"
        usage
    fi
else
    mv ./ciphertext.src ./ciphertext.bin
fi
        
# Perform the operation
case ${CRYPTO_OPERATION} in
    encrypt)
        CRYPTO_TEXT=$(aws --region ${REGION} --output text kms ${CRYPTO_OPERATION} \
            --key-id "${KEYID}" --query CiphertextBlob \
            --plaintext "fileb://ciphertext.bin") 
        ;;

    decrypt)
        CRYPTO_TEXT=$(aws --region ${REGION} --output text kms ${CRYPTO_OPERATION} \
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
        CRYPTO_TEXT=$(echo -n "${CRYPTO_TEXT}" | dos2unix | base64 -d)
    fi

    # Update if required
    if [[ "${CRYPTO_UPDATE}" == "true" ]]; then
        if [[ -n "${JSON_PATH}" ]]; then
            cat "${TARGET_FILE}" | jq --indent 4 "${JSON_PATH}=\"${CRYPTO_TEXT}\"" > "temp_${CRYPTO_FILENAME_DEFAULT}"
            RESULT=$?
            if [[ "${RESULT}" -eq 0 ]]; then
                mv "temp_${CRYPTO_FILENAME_DEFAULT}" "${TARGET_FILE}"
            fi
        else
            echo "${CRYPTO_TEXT}" > "temp_${CRYPTO_FILENAME_DEFAULT}"
            RESULT=$?
            if [[ "${RESULT}" -eq 0 ]]; then
                if [[ "${CRYPTO_OPERATION}" == "decrypt" ]]; then
                    mv "temp_${CRYPTO_FILENAME_DEFAULT}" "${TARGET_FILE}.decrypted"
                else
                    mv "temp_${CRYPTO_FILENAME_DEFAULT}" "${TARGET_FILE}"
                fi
            fi            
        fi
    fi
fi

if [[ ("${RESULT}" -eq 0) && ( "${CRYPTO_QUIET}" != "true") ]]; then
    # Display result
    echo -n "${CRYPTO_TEXT}"
fi