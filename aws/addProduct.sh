#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
    echo -e "\nAdd a new product"
    echo -e "\nUsage: $(basename $0) -l TITLE -n PRODUCT -d DESCRIPTION -p PID -o DOMAIN -r AWS_REGION  -u"
    echo -e "\nwhere\n"
    echo -e "(o) -d DESCRIPTION is the product description"
    echo -e "    -h shows this text"
    echo -e "(o) -l TITLE is the product title"
    echo -e "(m) -n PRODUCT is the human readable form (one word, lowercase and no spaces) of the product id"
    echo -e "(o) -o DOMAIN is the default DNS domain to be used for the product"
    echo -e "(o) -p PID is the product id"
    echo -e "(o) -r AWS_REGION is the default AWS region for the product"
    echo -e "(o) -u if details should be updated"
    echo -e "\nDEFAULTS (creation only):\n"
    echo -e "PID=PRODUCT"
    echo -e "\nNOTES:\n"
    echo -e "1. Subdirectories are created in the config and infrastructure subtrees"
    echo -e "2. The product information is saved in the product profile"
    echo -e "3. To update the details, the update option must be explicitly set"
    echo -e ""
    exit
}

# Parse options
while getopts ":d:hl:n:o:p:r:u" opt; do
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
            PRODUCT="${OPTARG}"
            ;;
        o)
            DOMAIN="${OPTARG}"
            ;;
        p)
            PID="${OPTARG}"
            ;;
        r)
            AWS_REGION="${OPTARG}"
            ;;
        u)
            UPDATE_PRODUCT="true"
            ;;
        \?)
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG}" requires an argument"
            usage
            ;;
    esac
done

# Ensure mandatory arguments have been provided
if [[ (-z "${PRODUCT}") ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the root of the account tree
if [[ "${LOCATION}" != "root" ]]; then
    echo -e "\nWe don't appear to be in the root of the account tree. Are we in the right place?"
    usage
fi

# Create the directories for the product
PRODUCT_DIR="${GENERATION_DATA_DIR}/config/${PRODUCT}"
SOLUTIONS_DIR="${PRODUCT_DIR}/solutions"
APPSETTINGS_DIR="${PRODUCT_DIR}/appsettings"
INFRASTRUCTURE_DIR="${GENERATION_DATA_DIR}/infrastructure/${PRODUCT}"
CREDENTIALS_DIR="${INFRASTRUCTURE_DIR}/credentials"

if [[ ! -d ${APPSETTINGS_DIR} ]]; then
    mkdir -p ${APPSETTINGS_DIR}
    echo "{}" > ${APPSETTINGS_DIR}/appsettings.json
fi
mkdir -p ${CREDENTIALS_DIR}

# Check whether the product profile is already in place
PRODUCT_PROFILE=${PRODUCT_DIR}/product.json
if [[ -f ${PRODUCT_PROFILE} ]]; then
    if [[ "${UPDATE_PRODUCT}" != "true" ]]; then
        echo -e "\nProduct profile already exists. Maybe try using update option?"
        usage
    fi
else
    echo "{\"Product\":{}}" > ${PRODUCT_PROFILE}
    PID="${PID:-${PRODUCT}}"
fi

# Generate the filter
CERTIFICATE_ID="${PRODUCT}"
FILTER="."
if [[ -n "${PID}" ]]; then FILTER="${FILTER} | .Product.Id=\$PID"; fi
if [[ -n "${PRODUCT}" ]]; then FILTER="${FILTER} | .Product.Name=\$PRODUCT"; fi
if [[ -n "${TITLE}" ]]; then FILTER="${FILTER} | .Product.Title=\$TITLE"; fi
if [[ -n "${DESCRIPTION}" ]]; then FILTER="${FILTER} | .Product.Description=\$DESCRIPTION"; fi
if [[ -n "${AWS_REGION}" ]]; then FILTER="${FILTER} | .Product.Region=\$AWS_REGION"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Stem=\$DOMAIN"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Certificate.Id=\$CERTIFICATE_ID"; fi

# Generate the product profile
cat ${PRODUCT_PROFILE} | jq --indent 4 \
--arg PID "${PID}" \
--arg PRODUCT "${PRODUCT}" \
--arg TITLE "${TITLE}" \
--arg DESCRIPTION "${DESCRIPTION}" \
--arg AWS_REGION "${AWS_REGION}" \
--arg DOMAIN "${DOMAIN}" \
--arg CERTIFICATE_ID "${CERTIFICATE_ID}" \
"${FILTER}" > ${PRODUCT_DIR}/temp_product.json
RESULT=$?

if [[ ${RESULT} -eq 0 ]]; then
    mv ${PRODUCT_DIR}/temp_product.json ${PRODUCT_DIR}/product.json
else
    echo -e "\nError creating product profile" 
    exit
fi

# Provide an empty credentials profile for the product
if [[ ! -f ${CREDENTIALS_DIR}/credentials.json ]]; then
    echo "{\"Credentials\" : {}}" | jq --indent 4 '.' > ${CREDENTIALS_DIR}/credentials.json
fi

# Ignore local files
if [[ ! -f ${INFRASTRUCTURE_DIR}/.gitignore ]]; then
    cat > ${INFRASTRUCTURE_DIR}/.gitignore << EOF
*.decrypted
*.ppk
EOF
fi

# Control line endings
if [[ ! -f ${INFRASTRUCTURE_DIR}/.gitattributes ]]; then
    cat > ${INFRASTRUCTURE_DIR}/.gitattributes << EOF
# Set the default behavior, in case people don't have core.autocrlf set.
* text=auto

# scripts and pem files should stay with LF
*.sh text eol=lf
*.pem text eol=lf
EOF
fi

# All good
RESULT=0
