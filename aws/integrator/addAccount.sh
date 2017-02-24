#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
    
# Defaults

function usage() {
    cat <<EOF

Add a new account for a tenant

Usage: $(basename $0) -l TITLE -n ACCOUNT -d DESCRIPTION -a AID -t TENANT -o DOMAIN -r AWS_REGION -c AWS_ID -f -u

where

(m) -a AID          is the tenant account id
(o) -c AWS_ID       is the AWS account id
(o) -d DESCRIPTION  is the account description
(o) -f              if an existing shelf account should be used as the basis for the new account
    -h              shows this text
(o) -l TITLE        is the account title
(m) -n ACCOUNT      is the human readable form (one word, lowercase and no spaces) of the account id
(o) -o DOMAIN       is the default DNS domain to be used for account products
(o) -r AWS_REGION   is the AWS region identifier for the region in which the account will be created
(m) -t TENANT       is the tenant name
(o) -u              if details should be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS (creation only):

AID=ACCOUNT

NOTES:

1. The script must be run from the root of the integrator tree
2. A sub-directory is created for the account under the tenant
3. The account information is saved in the account profile
4. To update the details, the update option must be explicitly set

EOF
    exit
}

# Parse options
while getopts ":a:c:d:fhl:n:o:r:t:u" opt; do
    case $opt in
        a)
            AID="${OPTARG}"
            ;;
        c)
            AWS_ID="${OPTARG}"
            ;;
        d)
            DESCRIPTION="${OPTARG}"
            ;;
        f)
            USE_SHELF_ACCOUNT="true"
            ;;
        h)
            usage
            ;;
        l)
            TITLE="${OPTARG}"
            ;;
        n)
            ACCOUNT="${OPTARG}"
            ;;
        o)
            DOMAIN="${OPTARG}"
            ;;
        r)
            AWS_REGION="${OPTARG}"
            ;;
        t)
            TENANT="${OPTARG}"
            ;;
        u)
            UPDATE_ACCOUNT="true"
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

# Ensure mandatory arguments have been provided
if [[ (-z "${TENANT}") ||
      (-z "${ACCOUNT}") ]]; then
  echo -e "\nInsufficient arguments" >&2
  exit
fi

# Ensure we are in the integrator tree
INTEGRATOR_PROFILE=integrator.json
if [[ ! -f "${INTEGRATOR_PROFILE}" ]]; then
    echo -e "\nWe don't appear to be in the root of the integrator tree. Are we in the right place?" >&2
    exit
fi

# Ensure the tenant already exists
TENANT_DIR="$(pwd)/tenants/${TENANT}"
if [[ ! -d "${TENANT_DIR}" ]]; then
    echo -e "\nThe tenant needs to be added before the account" >&2
    exit
fi

# Create the directory for the account, potentially using a shelf account
ACCOUNTS_DIR="${TENANT_DIR}/accounts"
mkdir -p "${ACCOUNTS_DIR}"
ACCOUNT_DIR="${ACCOUNTS_DIR}/${ACCOUNT}"
if [[ ! -d "${ACCOUNT_DIR}" ]]; then
    if [[ "${USE_SHELF_ACCOUNT}" == "true" ]]; then
        # Find the highest numbered shelf account available
        for I in $(seq 1 9); do
            SHELF_ACCOUNT="${GENERATION_DATA_DIR}/tenants/aws/accounts/shelf0${I}"
            if [[ -d "${SHELF_ACCOUNT}" ]]; then
                LAST_SHELF_ACCOUNT="${SHELF_ACCOUNT}"
            fi
        done
        if [[ -n "${LAST_SHELF_ACCOUNT}" ]]; then
            ${FILE_MV} "${LAST_SHELF_ACCOUNT}" "${ACCOUNT_DIR}"
        fi
    fi
fi
if [[ ! -d "${ACCOUNT_DIR}" ]]; then
    mkdir -p ${ACCOUNT_DIR}
fi

# Check whether the account profile is already in place
ACCOUNT_PROFILE=${ACCOUNT_DIR}/account.json
if [[ -f ${ACCOUNT_PROFILE} ]]; then
    if [[ ("${UPDATE_ACCOUNT}" != "true") &&
          (-z "${LAST_SHELF_ACCOUNT}") ]]; then
        echo -e "\nAccount profile already exists. Maybe try using update option?" >&2
        exit
    fi
else
    echo "{\"Account\":{}}" > ${ACCOUNT_PROFILE}
    AID="${AID:-${ACCOUNT}}"
fi

# Generate the filter
CERTIFICATE_ID="${ACCOUNT}"
FILTER="."
if [[ -n "${AID}" ]]; then FILTER="${FILTER} | .Tenant.Id=\$AID"; fi
if [[ -n "${ACCOUNT}" ]]; then FILTER="${FILTER} | .Account.Name=\$ACCOUNT"; fi
if [[ -n "${TITLE}" ]]; then FILTER="${FILTER} | .Account.Title=\$TITLE"; fi
if [[ -n "${DESCRIPTION}" ]]; then FILTER="${FILTER} | .Account.Description=\$DESCRIPTION"; fi
if [[ -n "${AWS_ID}" ]]; then FILTER="${FILTER} | .Account.AWSId=\$AWS_ID"; fi
if [[ -n "${AWS_REGION}" ]]; then FILTER="${FILTER} | .Account.Region=\$AWS_REGION"; fi
if [[ -n "${AWS_REGION}" ]]; then FILTER="${FILTER} | .Product.Region=\$AWS_REGION"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Stem=\$DOMAIN"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Certificate.Id=\$CERTIFICATE_ID"; fi

# Generate the account profile
jq --indent 4 \
--arg AID "${AID}" \
--arg ACCOUNT "${ACCOUNT}" \
--arg TITLE "${TITLE}" \
--arg DESCRIPTION "${DESCRIPTION}" \
--arg AWS_ID "${AWS_ID}" \
--arg AWS_REGION "${AWS_REGION}" \
--arg DOMAIN "${DOMAIN}" \
--arg CERTIFICATE_ID "${CERTIFICATE_ID}" \
"${FILTER}" < ${ACCOUNT_PROFILE} > ${ACCOUNT_DIR}/temp_account.json
RESULT=$?

if [[ ${RESULT} -eq 0 ]]; then
    mv ${ACCOUNT_DIR}/temp_account.json ${ACCOUNT_DIR}/account.json
else
    echo -e "\nError creating account profile" >&2
    exit
fi

# Provide an empty credentials profile for the account
if [[ ! -f ${ACCOUNT_DIR}/credentials.json ]]; then
    jq --indent 4 '.' <<< "{\"Credentials\" : {}}" > ${ACCOUNT_DIR}/credentials.json
fi

# All good
RESULT=0
