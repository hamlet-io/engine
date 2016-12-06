#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
    echo -e "\nAdd a new tenant"
    echo -e "\nUsage: $(basename $0) -l TITLE -n TENANT -d DESCRIPTION -t TID -o DOMAIN -r AWS_REGION -s AWS_SES_REGION -u"
    echo -e "\nwhere\n"
    echo -e "(o) -d DESCRIPTION is the tenant description"
    echo -e "    -h shows this text"
    echo -e "(o) -l TITLE is the tenant title"
    echo -e "(m) -n TENANT is the human readable form (one word, lowercase and no spaces) of the tenant id"
    echo -e "(o) -o DOMAIN is the default DNS domain to be used for tenant products and accounts"
    echo -e "(o) -r AWS_REGION is the default AWS region for the tenant"
    echo -e "(o) -s AWS_SES_REGION is the default AWS region for use of the SES service"
    echo -e "(o) -t TID is the tenant id"
    echo -e "(o) -u if details should be updated"
    echo -e "\nDEFAULTS (creation only):\n"
    echo -e "TID=TENANT"
    echo -e "\nNOTES:\n"
    echo -e "1. The script must be run from the root of the integrator tree"
    echo -e "2. A sub-directory is created for the tenant"
    echo -e "3. The tenant information is saved in the tenant profile"
    echo -e "4. The integrator profile forms the basis for the tenant profile" 
    echo -e "5. To update the details, the update option must be explicitly set"
    echo -e "6. The domain will default on tenant creation to {TENANT}.{integrator domain}"
    echo -e ""
    exit
}

# Parse options
while getopts ":d:hl:n:o:r:s:t:u" opt; do
    case $opt in
        d)
            DESCRIPTION="${OPTARG}"
            ;;
        h)
            usage
            ;;
        l)
            TITLE="${OPTARG}"
            ;;
        n)
            TENANT="${OPTARG}"
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
            TID="${OPTARG}"
            ;;
        u)
            UPDATE_TENANT="true"
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
if [[ (-z "${TENANT}") ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

# Ensure we are in the integrator tree
INTEGRATOR_PROFILE=integrator.json
if [[ ! -f "${INTEGRATOR_PROFILE}" ]]; then
    echo -e "\nWe don't appear to be in the root of the integrator tree. Are we in the right place?"
    usage
fi

# Create the directory for the tenant
TENANT_DIR="$(pwd)/tenants/${TENANT}"
mkdir -p ${TENANT_DIR}

# Check whether the tenant profile is already in place
TENANT_PROFILE=${TENANT_DIR}/tenant.json
if [[ -f ${TENANT_PROFILE} ]]; then
    if [[ "${UPDATE_TENANT}" != "true" ]]; then
        echo -e "\nTenant profile already exists. Maybe try using update option?"
        usage
    fi
else
    jq 'del(.Integrator)' ${INTEGRATOR_PROFILE} > ${TENANT_PROFILE}
    INTEGRATOR_DOMAIN=$(jq -r '.Integrator.Domain.Stem | select(.!=null)' ${INTEGRATOR_PROFILE})
    DOMAIN=${DOMAIN:-${TENANT}.${INTEGRATOR_DOMAIN}}
    TID="${TID:-${TENANT}}"
fi

# Generate the filter
FILTER="."
if [[ -n "${TID}" ]]; then FILTER="${FILTER} | .Tenant.Id=\$TID"; fi
if [[ -n "${TENANT}" ]]; then FILTER="${FILTER} | .Tenant.Name=\$TENANT"; fi
if [[ -n "${TITLE}" ]]; then FILTER="${FILTER} | .Tenant.Title=\$TITLE"; fi
if [[ -n "${DESCRIPTION}" ]]; then FILTER="${FILTER} | .Tenant.Description=\$DESCRIPTION"; fi
if [[ -n "${VALIDATION_DOMAIN}" ]]; then FILTER="${FILTER} | .Tenant.Domain.Validation=\$VALIDATION_DOMAIN"; fi
if [[ -n "${AWS_REGION}" ]]; then FILTER="${FILTER} | .Account.Region=\$AWS_REGION"; fi
if [[ -n "${AWS_REGION}" ]]; then FILTER="${FILTER} | .Product.Region=\$AWS_REGION"; fi
if [[ -n "${AWS_SES_REGION}" ]]; then FILTER="${FILTER} | .Product.SES.Region=\$AWS_SES_REGION"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Account.Domain.Stem=\$DOMAIN"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Stem=\$DOMAIN"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Account.Domain.Certificate.Id=\$TID"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Certificate.Id=\$TID"; fi
if [[ -n "${IP_ADDRESS_BLOCKS}" ]]; then FILTER="${FILTER} | .Segment.IPAddressBlocks.global=\$IP_ADDRESS_BLOCKS"; fi

# Generate the tenant profile
cat ${TENANT_PROFILE} | jq --indent 4 \
--arg TID "${TID}" \
--arg TENANT "${TENANT}" \
--arg TITLE "${TITLE}" \
--arg DESCRIPTION "${DESCRIPTION}" \
--arg AWS_REGION "${AWS_REGION}" \
--arg AWS_SES_REGION "${AWS_SES_REGION}" \
--arg DOMAIN "${DOMAIN}" \
--arg VALIDATION_DOMAIN "${VALIDATION_DOMAIN}" \
--arg IP_ADDRESS_BLOCKS "${IP_ADDRESS_BLOCKS}" \
"${FILTER}" > ${TENANT_DIR}/temp_tenant.json
RESULT=$?

if [[ ${RESULT} -eq 0 ]]; then
    mv ${TENANT_DIR}/temp_tenant.json ${TENANT_DIR}/tenant.json
else
    echo -e "\nError creating tenant profile" 
    exit
fi

# Provide an empty credentials profile for the tenant
if [[ ! -f ${TENANT_DIR}/credentials.json ]]; then
    echo "{\"Credentials\" : {}}" | jq --indent 4 '.' > ${TENANT_DIR}/credentials.json
fi


