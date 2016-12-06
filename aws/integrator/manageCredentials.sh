#!/bin/bash
                                                                                        
if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

CREDENTIAL_NAME_DEFAULT="root+aws"
CREDENTIAL_TYPE_DEFAULT="Login"
function usage() {
    echo -e "\nManage tenant/account credentials"
    echo -e "\nUsage: $(basename $0) -t TENANT -a ACCOUNT -n CREDENTIAL_NAME -y CREDENTIAL_TYPE -i CREDENTIAL_ID -s CREDENTIAL_SECRET -e CREDENTIAL_EMAIL\n"
    echo -e "\nwhere\n"
    echo -e "(o) -a ACCOUNT is the tenant account name"
    echo -e "(o) -e CREDENTIAL_EMAIL is the email associated with the credential (not encrypted)"
    echo -e "    -h shows this text"
    echo -e "(o) -i CREDENTIAL_ID of credential (i.e. Username/Client Key/Access Key value) - not encrypted"
    echo -e "(m) -n CREDENTIAL_NAME for the set of values (id, secret, email)"
    echo -e "(o) -s CREDENTIAL_SECRET of credential (i.e. Password/Secret Key value) - encrypted"
    echo -e "(m) -t TENANT is the tenant name"
    echo -e "(m) -y CREDENTIAL_TYPE of credential"
    echo -e "\nDEFAULTS:\n"
    echo -e "CREDENTIAL_NAME = ${CREDENTIAL_NAME_DEFAULT} (account only)"
    echo -e "CREDENTIAL_TYPE = ${CREDENTIAL_TYPE_DEFAULT}"
    echo -e "\nNOTES:\n"
    echo -e "1. The script must be run from the root of the integrator tree"
    echo -e "2. Omit the account to manage tenant credentials"
    echo -e "3. Provided values (if any) are updated"
    echo -e "4. Current values are displayed"
    echo -e "5. Common CREDENTIAL_NAME values are \"Login\" for interactive credentials and \"API\" for AWS access keys"  
    echo -e ""
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
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument"
            usage
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
if [[ (-z "${TENANT}") || (-z "${CREDENTIAL_NAME}") || (-z "${CREDENTIAL_TYPE}") ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

# Ensure we are in the integrator tree
INTEGRATOR_PROFILE=integrator.json
if [[ ! -f "${INTEGRATOR_PROFILE}" ]]; then
    echo -e "\nWe don't appear to be in the root of the integrator tree. Are we in the right place?"
    usage
fi

# Manage the credentials
${GENERATION_DIR}/manageCredentialCrypto.sh -f "${CRYPTO_FILE_PATH}" -v
RESULT=$?
