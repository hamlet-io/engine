#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults

function usage() {
    cat <<EOF

Populate the account tree for an account

Usage: $(basename $0) -t TENANT -a ACCOUNT -u

where

(m) -a ACCOUNT  is the tenant account name
    -h          shows this text
(m) -t TENANT   is the tenant name
(o) -u          if details should be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. The script must be run from the root of the integrator tree
2. The account tree is expected to be present at the same level
   as the integrator tree
3. To update the details, the update option must be explicitly set

EOF
    exit
}

# Parse options
while getopts ":a:ht:u" opt; do
  case $opt in
    a)
      ACCOUNT="${OPTARG}"
      ;;
    h)
      usage
      ;;
    t)
      TENANT="${OPTARG}"
      ;;
    u)
      UPDATE_TREE="true"
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
[[ (-z "${TENANT}") ||
    (-z "${ACCOUNT}") ]] && fatalMandatory

# Ensure we are in the integrator tree
INTEGRATOR_PROFILE=integrator.json
[[ ! -f "${INTEGRATOR_PROFILE}" ]] &&
    fatalLocation "We don't appear to be in the root of the integrator tree."

# Ensure the tenant/account already exists
TENANT_DIR="$(pwd)/tenants/${TENANT}"
TENANT_ACCOUNT_DIR="${TENANT_DIR}/accounts/${ACCOUNT}"
[[ ! -d "${TENANT_ACCOUNT_DIR}" ]] &&
    fatalCantProceed "The account doesn't appear to exist in the integrator tree."

# Ensure the account tree exists
ACCOUNT_DIR="$(cd ../${ACCOUNT} && pwd)"
[[ ! -d "${ACCOUNT_DIR}" ]] &&
    fatalCantProceed "The account tree doesn't appear to exist at the same level as the integrator tree."

# Check whether the tree is already in place
CONFIG_DIR="${ACCOUNT_DIR}/config/${ACCOUNT}"
INFRASTRUCTURE_DIR="${ACCOUNT_DIR}/infrastructure/${ACCOUNT}"
[[ (-e "${CONFIG_DIR}/account.json") &&
    ("${UPDATE_TREE}" != "true") ]] &&
    fatal "Account tree already exists. Maybe try using the update option?"

# Populate the config tree
mkdir -p ${CONFIG_DIR}
cd ${CONFIG_DIR}

# Copy across key files
cp -p ${TENANT_DIR}/tenant.json .
cp -p ${TENANT_ACCOUNT_DIR}/account.json .

# Extract account information
AWS_ID=$(jq -r '.[0] * .[1] | .Account.AWSId | select(.!=null)' -s tenant.json account.json)
AWS_REGION=$(jq -r '.[0] * .[1] | .Account.Region | select(.!=null)' -s tenant.json account.json)

# Provide the docker registry endpoint by default
APPSETTINGS_DIR=${CONFIG_DIR}/appsettings
mkdir -p ${APPSETTINGS_DIR}
cd ${APPSETTINGS_DIR}

ACCOUNT_APPSETTINGS=appsettings.json
if [[ ! -f ${ACCOUNT_APPSETTINGS} ]]; then
    echo "{}" > ${ACCOUNT_APPSETTINGS}
fi

# Generate the filter
FILTER=". | .Docker.Registry=\"${AWS_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com\""

# Generate the account appsettings
jq --indent 4 \
"${FILTER}" < ${ACCOUNT_APPSETTINGS} > temp_appsettings.json
RESULT=$?
[[ ${RESULT} -ne 0 ]] && fatal "\nError creating account appsettings"

mv temp_appsettings.json appsettings.json

# Populate the infrastructure tree
mkdir -p ${INFRASTRUCTURE_DIR}
cd ${INFRASTRUCTURE_DIR}

# Generate default credentials 
CREDENTIALS_DIR=${INFRASTRUCTURE_DIR}/credentials
mkdir -p ${CREDENTIALS_DIR}
cd ${CREDENTIALS_DIR}

if [[ ! -f credentials.json ]]; then
    jq --indent 4 '.' <<< "{\"Credentials\" : {}}" > credentials.json
fi

# All good
RESULT=0
