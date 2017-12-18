#!/usr/bin/env bash
                                                                                        
[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
CREDENTIAL_NAME_DEFAULT="root+aws"
CREDENTIAL_TYPE_DEFAULT="Login"

function usage() {
    cat <<EOF

Manage tenant/account credentials

Usage: $(basename $0) -t TENANT -a ACCOUNT -n CREDENTIAL_NAME -y CREDENTIAL_TYPE -i CREDENTIAL_ID -s CREDENTIAL_SECRET -e CREDENTIAL_EMAIL

where

(o) -a ACCOUNT              is the tenant account name
(o) -e CREDENTIAL_EMAIL     is the email associated with the credential (not encrypted)
    -h                      shows this text
(o) -i CREDENTIAL_ID        of credential (i.e. Username/Client Key/Access Key value) - not encrypted
(m) -n CREDENTIAL_NAME      for the set of values (id, secret, email)
(o) -s CREDENTIAL_SECRET    of credential (i.e. Password/Secret Key value) - encrypted
(m) -t TENANT               is the tenant name
(m) -y CREDENTIAL_TYPE      of credential

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

CREDENTIAL_NAME = ${CREDENTIAL_NAME_DEFAULT} (account only)
CREDENTIAL_TYPE = ${CREDENTIAL_TYPE_DEFAULT}

NOTES:

1. The script must be run from the root of the integrator tree
2. Omit the account to manage tenant credentials
3. Provided values (if any) are updated
4. Current values are displayed
5. Common CREDENTIAL_NAME values are "Login" for interactive credentials and "API" for AWS access keys

EOF
    exit
}

# Parse options
while getopts ":a:e:hi:n:s:t:y:" opt; do
    case $opt in
        a)
            ACCOUNT="${OPTARG}"
            ;;
        e)
            export CREDENTIAL_EMAIL="${OPTARG}"
            ;;
        h)
            usage
            ;;
        i)
            export CREDENTIAL_ID="${OPTARG}"
            ;;
        n)
            export CREDENTIAL_NAME="${OPTARG}"
            ;;
        s)
            export CREDENTIAL_SECRET="${OPTARG}"
            ;;
        t)
            TENANT="${OPTARG}"
            ;;
        y)
            export CREDENTIAL_TYPE="${OPTARG}"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Apply defaults
if [[ -n "${ACCOUNT}" ]]; then
    CRYPTO_FILE_PATH="tenants/${TENANT}/accounts/${ACCOUNT}"
    export CREDENTIAL_NAME="${CREDENTIAL_NAME:-${CREDENTIAL_NAME_DEFAULT}}"
else
    CRYPTO_FILE_PATH="tenants/${TENANT}"
fi
export CREDENTIAL_TYPE="${CREDENTIAL_TYPE:-${CREDENTIAL_TYPE_DEFAULT}}"


# Ensure mandatory arguments have been provided
[[ (-z "${TENANT}") ||
    (-z "${CREDENTIAL_NAME}") ||
    (-z "${CREDENTIAL_TYPE}") ]] && fatalMandatory

# Ensure we are in the integrator tree
INTEGRATOR_PROFILE=integrator.json
[[ ! -f "${INTEGRATOR_PROFILE}" ]] &&
    fatalLocation "We don't appear to be in the root of the integrator tree."

# Manage the credentials
${GENERATION_DIR}/manageCredentialCrypto.sh -f "${CRYPTO_FILE_PATH}" -v
RESULT=$?
