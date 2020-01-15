#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

# Defaults
ACL_DEFAULT="private"
PREFIX_DEFAULT="/"
DISPLAY_ACLS_DEFAULT="false"

function usage() {
    cat <<EOF

Update the ACL associated with all objects in a bucket

Usage: $(basename $0) -b BUCKET -p PREFIX -a ACL -d

where

(o) -a ACL      is the canned ACL to apply to all objects in the bucket
(m) -b BUCKET   is the bucket to be updated
    -d          displays the ACLs but does not update them
    -h          shows this text
(o) -p PREFIX   is the key prefix for objects to be updated

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

ACL    = "${ACL_DEFAULT}"
PREFIX = "${PREFIX_DEFAULT}"
DISPLAY_ACLS = "${DISPLAY_ACLS_DEFAULT}"

NOTES:

1. PREFIX must start and end with a /

EOF
    exit
}

# Parse options
while getopts ":a:b:dhp:" opt; do
    case $opt in
        a)
            ACL="${OPTARG}"
            ;;
        b)
            BUCKET="${OPTARG}"
            ;;
        d)
            DISPLAY_ACLS="true"
            ;;
        h)
            usage
            ;;
        p)
            PREFIX="${OPTARG}"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Defaults
ACL="${ACL:-${ACL_DEFAULT}}"
PREFIX="${PREFIX:-${PREFIX_DEFAULT}}"
DISPLAY_ACLS="${DISPLAY_ACLS:-${DISPLAY_ACLS_DEFAULT}}"

# Ensure mandatory arguments have been provided
[[ -z "${BUCKET}" ]] && fatalMandatory

# Set up the context
. "${GENERATION_BASE_DIR}/execution/setContext.sh"

# Get the list of ECS clusters
for KEY in $(aws --region ${REGION} s3 ls s3://${BUCKET}${PREFIX} --recursive  | tr -s " " | tr -d "\r" | cut -d " " -f4); do
    if [[ "${DISPLAY_ACLS}" == "true" ]]; then
        # Show current ACL
        echo "Key=${KEY}"
        aws --region ${REGION} s3api get-object-acl --bucket "${BUCKET}" --key "${KEY}"
    else
        # Update the ACL
        aws --region ${REGION} s3api put-object-acl --bucket "${BUCKET}" --key "${KEY}" --acl "${ACL}"
    fi
done

# All good
RESULT=0
