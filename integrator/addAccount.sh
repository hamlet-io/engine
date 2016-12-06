#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
    
function usage() {
    echo -e "\nAdd a new account for a tenant"
    echo -e "\nUsage: $(basename $0) -l TITLE -n ACCOUNT -d DESCRIPTION -a AID -t TENANT -o DOMAIN -r AWS_REGION -s AWS_SES_REGION -c AWS_ID -f -u"
    echo -e "\nwhere\n"
    echo -e "(m) -a AID is the tenant account id"
    echo -e "(o) -c AWS_ID is the AWS account id"
    echo -e "(o) -d DESCRIPTION is the account description"
    echo -e "(o) -f if an existing shelf account should be used as the basis for the new account"
    echo -e "    -h shows this text"
    echo -e "(o) -l TITLE is the account title"
    echo -e "(m) -n ACCOUNT is the human readable form (one word, lowercase and no spaces) of the account id"
    echo -e "(o) -o DOMAIN is the default DNS domain to be used for account products"
    echo -e "(o) -r AWS_REGION is the AWS region identifier for the region in which the account will be created"
    echo -e "(o) -s AWS_SES_REGION is the default AWS region for use of the SES service"
    echo -e "(m) -t TENANT is the tenant name"
    echo -e "(o) -u if details should be updated"
    echo -e "\nDEFAULTS (creation only):\n"
    echo -e "AID=ACCOUNT"
    echo -e "\nNOTES:\n"
    echo -e "1. The script must be run from the root of the integrator tree"
    echo -e "2. A sub-directory is created for the account under the tenant"
    echo -e "3. The account information is saved in the account profile"
    echo -e "4. To update the details, the update option must be explicitly set"
    echo -e ""
    exit
}

# Parse options
while getopts ":a:c:d:fhl:n:o:r:s:t:u" opt; do
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
        s)
            AWS_SES_REGION="${OPTARG}"
            ;;
        t)
            TENANT="${OPTARG}"
            ;;
        u)
            UPDATE_ACCOUNT="true"
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

# Ensure mandatory arguments have been provided
if [[ (-z "${TENANT}") ||
      (-z "${ACCOUNT}") ]]; then
  echo -e "\nInsufficient arguments"
  usage
fi

# Ensure we are in the integrator tree
INTEGRATOR_PROFILE=integrator.json
if [[ ! -f "${INTEGRATOR_PROFILE}" ]]; then
    echo -e "\nWe don't appear to be in the root of the integrator tree. Are we in the right place?"
    usage
fi

# Ensure the tenant already exists
TENANT_DIR="$(pwd)/tenants/${TENANT}"
if [[ ! -d "${TENANT_DIR}" ]]; then
    echo -e "\nThe tenant needs to be added before the account"
    usage
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
        echo -e "\nAccount profile already exists. Maybe try using update option?"
        usage
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
if [[ -n "${AWS_SES_REGION}" ]]; then FILTER="${FILTER} | .Product.SES.Region=\$AWS_SES_REGION"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Stem=\$DOMAIN"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Certificate.Id=\$CERTIFICATE_ID"; fi

# Generate the account profile
cat ${ACCOUNT_PROFILE} | jq --indent 4 \
--arg AID "${AID}" \
--arg ACCOUNT "${ACCOUNT}" \
--arg TITLE "${TITLE}" \
--arg DESCRIPTION "${DESCRIPTION}" \
--arg AWS_ID "${AWS_ID}" \
--arg AWS_REGION "${AWS_REGION}" \
--arg DOMAIN "${DOMAIN}" \
--arg CERTIFICATE_ID "${CERTIFICATE_ID}" \
"${FILTER}" > ${ACCOUNT_DIR}/temp_account.json
RESULT=$?

if [[ ${RESULT} -eq 0 ]]; then
    mv ${ACCOUNT_DIR}/temp_account.json ${ACCOUNT_DIR}/account.json
else
    echo -e "\nError creating account profile" 
    exit
fi

# Provide an empty credentials profile for the account
if [[ ! -f ${ACCOUNT_DIR}/credentials.json ]]; then
    echo "{\"Credentials\" : {}}" | jq --indent 4 '.' > ${ACCOUNT_DIR}/credentials.json
fi

# All good
RESULT=0
