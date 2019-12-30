#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

BASE64_REGEX="^[A-Za-z0-9+/=\n]\+$"

# Defaults
CREDENTIAL_TYPE_LOGIN="LOGIN"
CREDENTIAL_TYPE_API="API"
CREDENTIAL_TYPE_ENV="ENV"
CREDENTIAL_TYPE_DEFAULT="${CREDENTIAL_TYPE_LOGIN}"

function usage() {
    cat <<EOF

Manage crypto for credential storage

Usage: $(basename $0) -f CRYPTO_FILE -n CREDENTIAL_PATH -y CREDENTIAL_TYPE -i CREDENTIAL_ID -s CREDENTIAL_SECRET -e CREDENTIAL_EMAIL -v

where

(o) -e CREDENTIAL_EMAIL     is the email associated with the credential (not encrypted)
(o) -f CRYPTO_FILE          is the path to the credentials file to be used
    -h                      shows this text
(o) -i CREDENTIAL_ID        of credential (i.e. Username/Client Key/Access Key value) - not encrypted
(m) -n CREDENTIAL_PATH      for the set of values (id, secret, email)
(o) -s CREDENTIAL_SECRET    of credential (i.e. Password/Secret Key value) - encrypted
(o) -v                      if CREDENTIAL_SECRET should be decrypted (visible)
(m) -y CREDENTIAL_TYPE      of credential

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

CREDENTIAL_TYPE = ${CREDENTIAL_TYPE_DEFAULT}

NOTES:
1. CREDENTIAL_PATH is a JSON path so values separated by dots. It is case sensitive.
2. CREDENTIAL_TYPE is ${CREDENTIAL_TYPE_LOGIN}, ${CREDENTIAL_TYPE_API} or ${CREDENTIAL_TYPE_ENV}
3. For CREDENTIAL_TYPE of ${CREDENTIAL_TYPE_LOGIN}, Id Attribute = Username, Secret Attribute = Password
4. For CREDENTIAL_TYPE of ${CREDENTIAL_TYPE_API}, Id Attribute = AccessKey, Secret Attribute = SecretKey
5. For CREDENTIAL_TYPE of ${CREDENTIAL_TYPE_ENV}, Id Attribute = ACCESS_KEY, Secret Attribute = SECRET_KEY

EOF
    exit
}

# Parse options
while getopts ":e:f:hi:n:s:vy:" opt; do
    case $opt in
        e)
            CREDENTIAL_EMAIL="${OPTARG}"
            ;;
        f)
            export CRYPTO_FILE="${OPTARG}"
            ;;
        h)
            usage
            ;;
        i)
            CREDENTIAL_ID="${OPTARG}"
            ;;
        n)
            CREDENTIAL_PATH="${OPTARG}"
            ;;
        s)
            CREDENTIAL_SECRET="${OPTARG}"
            ;;
        v)
            CRYPTO_VISIBLE="true"
            ;;
        y)
            CREDENTIAL_TYPE="${OPTARG}"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

CREDENTIAL_TYPE="${CREDENTIAL_TYPE:-${CREDENTIAL_TYPE_DEFAULT}}"

# Ensure mandatory arguments have been provided
[[ (-z "${CREDENTIAL_PATH}") ||
    (-z "${CREDENTIAL_TYPE}") ]] && fatalMandatory && exit 1

# Define JSON paths
PATH_BASE="${CREDENTIAL_PATH}"
case ${CREDENTIAL_TYPE^^} in
    LOGIN)
        ATTRIBUTE_ID="Username"
        ATTRIBUTE_SECRET="Password"
        ;;
    API)
        ATTRIBUTE_ID="AccessKey"
        ATTRIBUTE_SECRET="SecretKey"
        ;;
    ENV)
        ATTRIBUTE_ID="ACCESS_KEY"
        ATTRIBUTE_SECRET="SECRET_KEY"
        ;;
    *)
        ATTRIBUTE_ID="Username"
        ATTRIBUTE_SECRET="Password"
        ;;
esac
ATTRIBUTE_EMAIL="Email"

PATH_ID=".${PATH_BASE}.${ATTRIBUTE_ID}"
PATH_SECRET=".${PATH_BASE}.${ATTRIBUTE_SECRET}"
PATH_EMAIL=".${PATH_BASE}.Email"

# Define which attributes to encrypt
ENCRYPT_ID="-n"
ENCRYPT_SECRET="-e"
ENCRYPT_EMAIL="-n"

# Perform updates if required
for ATTRIBUTE in ID SECRET EMAIL; do
    VAR_NAME="CREDENTIAL_${ATTRIBUTE}"
    VAR_PATH="PATH_${ATTRIBUTE}"
    VAR_ENCRYPT="ENCRYPT_${ATTRIBUTE}"
    if [[ -n "${!VAR_NAME}" ]]; then
        ${GENERATION_DIR}/manageCrypto.sh ${!VAR_ENCRYPT} -t "${!VAR_NAME}" -p "${!VAR_PATH}" -u -q
        RESULT=$?
        [[ "${RESULT}" -ne 0 ]] && fatal "Failed to update credential ${ATTRIBUTE}"
    fi
done

# Display current values
echo -e "\n${PATH_BASE}"
for ATTRIBUTE in ID SECRET EMAIL; do
    VAR_PATH="PATH_${ATTRIBUTE}"
    VAR_ATTRIBUTE="ATTRIBUTE_${ATTRIBUTE}"
    RAW_VALUE=$(${GENERATION_DIR}/manageCrypto.sh -n -p "${!VAR_PATH}")
    RESULT=$?
    if [[ "${RESULT}" -eq 0 ]]; then
        ENCRYPTED=$(grep -q "${BASE64_REGEX}" <<< "${RAW_VALUE}")
        if [[ ($? -eq 0) && (-n "${CRYPTO_VISIBLE}" ) ]]; then
            VALUE=$(${GENERATION_DIR}/manageCrypto.sh -d -b -v -p "${!VAR_PATH}" 2> /dev/null)
            RESULT=$?
            if [[ "${RESULT}" -eq 0 ]]; then
                echo -e "${!VAR_ATTRIBUTE}=${VALUE}"
            else
#                if [[ "${!VAR_ATTRIBUTE}" == "AccessKey" ]]; then
                    # AccessKey value matches base64 regex so show raw value
                    echo -e "${!VAR_ATTRIBUTE}=${RAW_VALUE}"
#                fi
            fi
        else
            echo -e "${!VAR_ATTRIBUTE}=${RAW_VALUE}"
        fi
    fi
done

# All good
RESULT=0
