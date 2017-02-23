#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults

function usage() {
    cat <<EOF

Add SSH certificate to product/segment

Usage: $(basename $0)

where

    -h shows this text

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. Current directory must be for product or segment

EOF
    exit
}

# Parse options
while getopts ":hn:" opt; do
    case $opt in
        h)
            usage
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

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Process the relevant directory
INFRASTRUCTURE_DIR="${GENERATION_DATA_DIR}/infrastructure/${PRODUCT}"
CREDENTIALS_DIR="${INFRASTRUCTURE_DIR}/credentials"
if [[ "product" =~ ${LOCATION} ]]; then
    SSH_ID="${PRODUCT}"
    KEYID=$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r '.[] | select(.OutputKey=="cmkXproductXcmk") | .OutputValue | select (.!=null)')
elif [[ "segment" =~ ${LOCATION} ]]; then
    CREDENTIALS_DIR="${CREDENTIALS_DIR}/${SEGMENT}"
    SSH_ID="${PRODUCT}-${SEGMENT}"
    KEYID=$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r '.[] | select(.OutputKey=="cmkXsegmentXcmk") | .OutputValue | select (.!=null)')
    SSHPERSEGMENT=$(cat ${COMPOSITE_BLUEPRINT} | jq -r '.Segment.SSHPerSegment | select (.!=null)')
    if [[ "${SSHPERSEGMENT}" != "true" ]]; then
        echo -e "\nAn SSH key is not required for this segment. Check the SSHPerSegment setting if unsure" >&2
        exit
    fi
else
    echo -e "\nWe don't appear to be in the product or segment directory. Are we in the right place?" >&2
    exit
fi

# Ensure we've create a cmk to encrypt the SSH private key
if [[ -z "${KEYID}" ]]; then
    echo -e "\nNo cmk defined to encrypt the SSH private key. Create the cmk slice before running this script again" >&2
    exit
fi

# Create an SSH certificate at the product level
mkdir -p "${CREDENTIALS_DIR}"
. ${GENERATION_DIR}/createSSHCertificate.sh "${CREDENTIALS_DIR}"

# Check that the SSH certificate has been defined in AWS
${GENERATION_DIR}/manageSSHCertificate.sh -i ${SSH_ID} -p ${CREDENTIALS_DIR}/aws-ssh-crt.pem -r ${REGION}
RESULT=$?
