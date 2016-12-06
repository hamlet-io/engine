#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi

# Defaults
AINDEX_DEFAULT="01"

function usage() {
  echo -e "\nInitialise the account/ALM level credentials information" 
  echo -e "\nUsage: $(basename $0) -o TID -i AINDEX"
  echo -e "\nwhere\n"
  echo -e "    -h shows this text"
  echo -e "(o) -i AINDEX is the 2 digit tenant account index e.g. \"01\", \"02\""
  echo -e "(m) -o TID is the tenant id e.g. \"env\""
  echo -e "\nDEFAULTS:\n"
  echo -e "AINDEX =\"${AINDEX_DEFAULT}\""
  echo -e "\nNOTES:\n"
  echo -e "1) The tenant account id (AID) is formed by concatenating the TID and the AINDEX"
  echo -e "2) The AID needs to match the root of the directory structure"
  echo -e ""
  exit 1
}

AINDEX="${AINDEX_DEFAULT}"

# Parse options
while getopts ":hi:o:" opt; do
  case $opt in
    h)
      usage
      ;;
    i)
      AINDEX="${OPTARG}"
      ;;
    o)
      TID="${OPTARG}"
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
if [[ "${TID}"  == "" ||
      "${AINDEX}" == "" ]]; then
  echo -e "\nInsufficient arguments"
  usage
fi

AID="${TID}${AINDEX}"

BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

GENERATION_DATA_DIR="$(../..;pwd)"
ROOT="$(basename ${GENERATION_DATA_DIR})"

CREDS_DIR="${GENERATION_DATA_DIR}/infrastructure/credentials"
PRODUCT_DIR="${CREDS_DIR}/${AID}"
ALM_DIR="${PRODUCT_DIR}/alm"
DOCKER_DIR="${ALM_DIR}/docker"

if [[ "${AID}" != "${ROOT}" ]]; then
    echo -e "\nThe provided AID (${AID}) doesn't match the root directory (${ROOT}). Nothing to do."
    usage
fi

if [[ -e ${PRODUCT_DIR} ]]; then
    echo -e "\nLooks like this script has already been run. Don't want to overwrite passwords. Nothing to do."
    usage
fi

# Generate initial passwords
ROOTPASSWORD="$(curl -s 'https://www.random.org/passwords/?num=1&len=20&format=plain&rnd=new')"
LDAPPASSWORD="$(curl -s 'https://www.random.org/passwords/?num=1&len=20&format=plain&rnd=new')"
BINDPASSWORD="$(curl -s 'https://www.random.org/passwords/?num=1&len=20&format=plain&rnd=new')"

# Create the "account" level credentials directory
if [[ ! -e ${PRODUCT_DIR} ]]; then
    mkdir ${PRODUCT_DIR}
fi

# Generate the account level credentials
TEMPLATE="accountCredentials.ftl"
TEMPLATEDIR="${BIN}/templates"
OUTPUT="${PRODUCT_DIR}/credentials.json"

ARGS="-v password=${ROOTPASSWORD}"

CMD="${BIN}/gsgen.sh -t $TEMPLATE -d $TEMPLATEDIR -o $OUTPUT $ARGS"
eval $CMD

if [[ ! -e ${ALM_DIR} ]]; then
    mkdir ${ALM_DIR}
fi

# Generate the alm level credentials
TEMPLATE="almCredentials.ftl"
TEMPLATEDIR="${BIN}/templates"
OUTPUT="${ALM_DIR}/credentials.json"

ARGS="-v tenantId=${TID}"
ARGS="${ARGS} -v accountId=${AID}"
ARGS="${ARGS} -v ldapPassword=${LDAPPASSWORD}"
ARGS="${ARGS} -v bindPassword=${BINDPASSWORD}"

CMD="${BIN}/gsgen.sh -t $TEMPLATE -d $TEMPLATEDIR -o $OUTPUT $ARGS"
eval $CMD

if [[ ! -e ${DOCKER_DIR} ]]; then
    mkdir ${DOCKER_DIR}
fi

# Generate the ECS credentials for docker access
TEMPLATE="ecsConfig.ftl"
TEMPLATEDIR="${BIN}/templates"
OUTPUT="${DOCKER_DIR}/ecs.config"

ARGS="-v accountId=${AID}"
ARGS="${ARGS} -v ldapPassword=${LDAPPASSWORD}"

CMD="${BIN}/gsgen.sh -t $TEMPLATE -d $TEMPLATEDIR -o $OUTPUT $ARGS"
eval $CMD

cd ${CREDS_DIR}

# Remove the placeholder file
if [[ -e .placeholder ]]; then
    git rm .placeholder
fi

# Commit the results
git add *
git commit -m "Configure account/ALM credentials"

