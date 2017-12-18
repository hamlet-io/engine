#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
. "${GENERATION_DIR}/common.sh"

# Defaults
AINDEX_DEFAULT="01"

function usage() {
    cat <<EOF

Initialise the account/ALM level credentials information

Usage: $(basename $0) -o TID -i AINDEX

where

    -h          shows this text
(o) -i AINDEX   is the 2 digit tenant account index e.g. "01", "02"
(m) -o TID      is the tenant id e.g. "env"

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

AINDEX ="${AINDEX_DEFAULT}"

NOTES:

1) The tenant account id (AID) is formed by concatenating the TID and the AINDEX
2) The AID needs to match the root of the directory structure

EOF
    exit
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
      fatalOption
      ;;
    :)
      fatalOptionArgument
      ;;
   esac
done

# Ensure mandatory arguments have been provided
[[ (-z "${TID}") ||
    (-z "${AINDEX}") ]] && fatalMandatory

AID="${TID}${AINDEX}"

BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

GENERATION_DATA_DIR="$(../..;pwd)"
ROOT="$(basename ${GENERATION_DATA_DIR})"

CREDS_DIR="${GENERATION_DATA_DIR}/infrastructure/credentials"
PRODUCT_DIR="${CREDS_DIR}/${AID}"
ALM_DIR="${PRODUCT_DIR}/alm"
DOCKER_DIR="${ALM_DIR}/docker"

[[ "${AID}" != "${ROOT}" ]] &&
    fatalCantProceed "The provided AID (${AID}) doesn't match the root directory (${ROOT})."

[[ -e ${PRODUCT_DIR} ]] &&
    fatalCantProceed "Looks like this script has already been run. Don't want to overwrite passwords."

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

