#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults

function usage() {
    cat <<EOF

Add a product

Usage: $(basename $0) -l TITLE -n PRODUCT -d DESCRIPTION -p PID -o DOMAIN -r AWS_REGION  -u

where

(o) -d DESCRIPTION  is the product description
    -h              shows this text
(o) -l TITLE        is the product title
(m) -n PRODUCT      is the human readable form (one word, lowercase and no spaces) of the product id
(o) -o DOMAIN       is the default DNS domain to be used for the product
(o) -p PID          is the product id
(o) -r AWS_REGION   is the default AWS region for the product
(o) -u              if details should be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS (creation only):

PID=PRODUCT

NOTES:

1. Subdirectories are created in the config and infrastructure subtrees
2. The product information is saved in the product profile
3. To update the details, the update option must be explicitly set

EOF
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
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Ensure mandatory arguments have been provided
[[ (-z "${PRODUCT}") ]] && fatalMandatory

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

# Ensure we are in the root of the account tree
checkInRootDirectory

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
    [[ "${UPDATE_PRODUCT}" != "true" ]] && \
        fatal "Product profile already exists. Maybe try using update option?"
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
jq --indent 4 \
--arg PID "${PID}" \
--arg PRODUCT "${PRODUCT}" \
--arg TITLE "${TITLE}" \
--arg DESCRIPTION "${DESCRIPTION}" \
--arg AWS_REGION "${AWS_REGION}" \
--arg DOMAIN "${DOMAIN}" \
--arg CERTIFICATE_ID "${CERTIFICATE_ID}" \
"${FILTER}" < ${PRODUCT_PROFILE} > ${PRODUCT_DIR}/temp_product.json
RESULT=$?
[[ ${RESULT} -ne 0 ]] && fatal "Error creating product profile"

mv ${PRODUCT_DIR}/temp_product.json ${PRODUCT_DIR}/product.json

# Provide an empty credentials profile for the product
if [[ ! -f ${CREDENTIALS_DIR}/credentials.json ]]; then
    jq --indent 4 '.' <<< "{\"Credentials\" : {}}" > ${CREDENTIALS_DIR}/credentials.json
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
