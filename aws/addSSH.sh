#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

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
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

. "${GENERATION_DIR}/setContext.sh"

# Process the relevant directory
if [[ "product" =~ ${LOCATION} ]]; then
    SSH_ID="${PRODUCT}"
    KEYID=$(getCmk "product")
    CREDENTIALS_DIR="${PRODUCT_CREDENTIALS_DIR}"
elif [[ "segment" =~ ${LOCATION} ]]; then
    SSH_ID="${PRODUCT}-${SEGMENT}"
    KEYID=$(getCmk "segment")
    CREDENTIALS_DIR="${SEGMENT_CREDENTIALS_DIR}"
    SSH_PER_SEGMENT=$(getBluePrintParameter ".Segment.SSH.PerSegment" ".Segment.SSHPerSegment")
    [[ "${SSH_PER_SEGMENT}" != "true" ]] && \
        fatalCantProceed "An SSH key is not required for this segment. Check the SSH PerSegment setting if unsure."
else
    fatalDirectoryProductOrSegment
fi

# Ensure we've got a cmk to encrypt the SSH private key
[[ -z "${KEYID}" ]] && fatal "No cmk defined to encrypt the SSH private key. Create the cmk deployment unit before running this script again"

# Create an SSH certificate at the product level
mkdir -p "${CREDENTIALS_DIR}"
. ${GENERATION_DIR}/createSSHCertificate.sh "${CREDENTIALS_DIR}"

# Check that the SSH certificate has been defined in AWS
${GENERATION_DIR}/manageSSHCertificate.sh -i ${SSH_ID} -p ${CREDENTIALS_DIR}/aws-ssh-crt.pem -r ${REGION}
RESULT=$?
