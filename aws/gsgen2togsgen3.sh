#!/bin/bash

trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
    echo -e "\nConvert config/infrastructure trees used for gsgen2 to the format required for gsgen3" 
    echo -e "\nUsage: $(basename $0) -a AID -p PID"
    echo -e "\nwhere\n"
    echo -e "(m) -a AID is the tenant account id e.g. \"env01\""
    echo -e "    -h shows this text"
    echo -e "(m) -p PID is the product id for the product e.g. \"eticket\""
    echo -e "\nNOTES:\n"
    echo -e "1. GSGEN3 expects product directories to be the immediate children of the config and infrastructure directories"
    echo -e "2. It is assumed we are in the config or infrastructure directory under the AID directory when the script is run"
    echo -e ""
    exit
}

# Parse options
while getopts ":a:hl:p:r:s:t:" opt; do
    case $opt in
        a)
            AID="${OPTARG}"
            ;;
        h)
            usage
            ;;
        p)
            PID="${OPTARG}"
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
if [[ "${AID}" == "" ||
      "${PID}"  == "" ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

AID_DIR="$(basename $(cd ..;pwd))"
CURRENT_DIR="$(basename $(pwd))"

if [[ "${AID}" != "${AID_DIR}" ]]; then
    echo -e "\nThe provided AID (${AID}) doesn't match the root directory (${ROOT}). Nothing to do."
    usage
fi

# If in a repo, save the results of the rearrangement
if [[ -d .git ]]; then
    MVCMD="git mv"
else
    MVCMD="mv"
fi

# Deal with the aws/startup and aws/cf directories
# They shouldn't be treated as a product
# We also combine the account and product level cf directories for AID
if [[ -d aws ]]; then
    mkdir -p ${AID}/aws/
    pushd aws
    for DIRECTORY in startup cf ; do
        if [[ -d ${DIRECTORY} ]]; then
            ${MVCMD} ${DIRECTORY} ../${AID}/aws
        fi
    done
    if [[ -d ${AID}/cf ]]; then
        ${MVCMD} ${AID}/cf/* ../${AID}/aws/cf
        rm -rf ${AID}/cf
    fi
    popd
fi

# Move each product to its own directory
# This will pick up the alm as a "product" as well
for TREE in solutions deployments credentials aws; do
    if [[ -d ${TREE} ]]; then
        pushd ${TREE}
        for PRODUCT in $(ls -d */ 2>/dev/null); do
            mkdir -p ../${PRODUCT}/${TREE}
            ${MVCMD} ${PRODUCT}/* ../${PRODUCT}/${TREE}
            rm -rf ${PRODUCT}
        done
        popd
    fi
done

# Move the tenant.json and account.json files to the AID directory
for FILE in $(ls solutions/*.json  2>/dev/null); do
    ${MVCMD} ${FILE} ${AID}
done

# Move the product.json files to their respective product directories
for PRODUCT in $(ls -d */ 2>/dev/null); do
    if [[ -f ${PRODUCT}/solutions/project.json ]]; then
    ${MVCMD} ${PRODUCT}/solutions/project.json ${PRODUCT}/${TREE}/product.json
    fi
done

# Move the ALM solution file into the alm directory
if [[ -f ${AID}/solutions/solution.json ]]; then
    ${MVCMD} ${AID}/solutions/solution.json ${AID}/solutions/alm
fi

# Final cleanup
for TREE in solutions deployments credentials aws; do
    if [[ -d ${TREE} ]]; then
        rm -rf ${TREE}
    fi
done

# Commit the results if necessary 
if [[ -d .git ]]; then
    git commit -m "Convert directory structure to format required for gsgen3"
fi

# All good
RESULT=0
