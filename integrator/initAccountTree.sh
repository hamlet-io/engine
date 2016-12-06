#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
    
function usage() {
    echo -e "\nPopulate the account tree for an account"
    echo -e "\nUsage: $(basename $0) -t TENANT -a ACCOUNT -u"
    echo -e "\nwhere\n"
    echo -e "(m) -a ACCOUNT is the tenant account name"
    echo -e "    -h shows this text"
    echo -e "(m) -t TENANT is the tenant name"
    echo -e "(o) -u if details should be updated"
    echo -e "\nDEFAULTS:\n"
    echo -e "\nNOTES:\n"
    echo -e "1. The script must be run from the root of the integrator tree"
    echo -e "2. The account tree is expected to be present at the same level"
    echo -e "   as the integrator tree"
    echo -e "2. To update the details, the update option must be explicitly set"
    echo -e ""
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

# Ensure the tenant/account already exists
TENANT_DIR="$(pwd)/tenants/${TENANT}"
TENANT_ACCOUNT_DIR="${TENANT_DIR}/accounts/${ACCOUNT}"
if [[ ! -d "${TENANT_ACCOUNT_DIR}" ]]; then
    echo -e "\nThe account doesn't appear to exist in the integrator tree. Nothing to do."
    usage
fi

# Ensure the account tree exists
ACCOUNT_DIR="$(cd ../${ACCOUNT} && pwd)"
if [[ ! -d "${ACCOUNT_DIR}" ]]; then
    echo -e "\nThe account tree doesn't appear to exist at the same level as the integrator tree. Nothing to do."
    usage
fi

# Check whether the tree is already in place
CONFIG_DIR="${ACCOUNT_DIR}/config/${ACCOUNT}"
INFRASTRUCTURE_DIR="${ACCOUNT_DIR}/infrastructure/${ACCOUNT}"
if [[ (-e "${CONFIG_DIR}/account.json") ]]; then
    if [[ ("${UPDATE_TREE}" != "true") ]]; then
        echo -e "\nAccount tree already exists. Maybe try using the update option?"
        usage
    fi
fi

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
cat ${ACCOUNT_APPSETTINGS} | jq --indent 4 \
"${FILTER}" > temp_appsettings.json
RESULT=$?

if [[ ${RESULT} -eq 0 ]]; then
    mv temp_appsettings.json appsettings.json
else
    echo -e "\nError creating account appsettings" 
    exit
fi

# Populate the infrastructure tree
mkdir -p ${INFRASTRUCTURE_DIR}
cd ${INFRASTRUCTURE_DIR}

# Generate default credentials 
CREDENTIALS_DIR=${INFRASTRUCTURE_DIR}/credentials
mkdir -p ${CREDENTIALS_DIR}
cd ${CREDENTIALS_DIR}

if [[ ! -f credentials.json ]]; then
    echo "{\"Credentials\" : {}}" | jq --indent 4 '.' > credentials.json
fi

# All good
RESULT=0
