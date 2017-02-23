#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults

function usage() {
    cat <<EOF

Synchronise the contents of the code and credentials buckets to the local values

Usage: $(basename $0) -q -x -y

where

    -h shows this text
(o) -q for no check (quick) - don't check bucket access before attempting to synchronise
(o) -x for no delete - by default files in the buckets that are absent locally are deleted
(o) -y for a dryrun - show what will happen without actually transferring any files

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

EOF
    exit
}

DRYRUN=
DELETE="--delete"
CHECK="true"

# Parse options
while getopts ":hqxy" opt; do
    case $opt in
        h)
            usage
            ;;
        q)
            CHECK=
            ;;
        x)
            DELETE=
            ;;
        y)
            DRYRUN="--dryrun"
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

if [[ ! ("root" =~ ${LOCATION}) ]]; then
    echo -e "\nNeed to be in the root directory. Nothing to do." >&2
    exit
fi

# Locate the bucket names
CODE_BUCKET=$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r ".[] | select(.OutputKey==\"s3XaccountXcode\") | .OutputValue | select(.!=null)")
CREDENTIALS_BUCKET=$(cat ${COMPOSITE_STACK_OUTPUTS} | jq -r ".[] | select(.OutputKey==\"s3XaccountXcredentials\") | .OutputValue | select(.!=null)")

if [[ (-z "${CODE_BUCKET}") ||
        (-z "${CREDENTIALS_BUCKET}") ||
        (-z "${ACCOUNT_REGION}") ]]; then
    echo -e "\nBuckets don't appear to have been created. Maybe create the Account stack first?" >&2
    exit
fi
pushd ${ACCOUNT_DIR}  > /dev/null 2>&1

# Confirm access to the code bucket
if [[ "${CHECK}" == "true" ]]; then
    aws --region ${ACCOUNT_REGION} s3 ls s3://${CODE_BUCKET}/ > temp_code_access.txt
    RESULT=$?
    if [[ "$RESULT" -ne 0 ]]; then
        echo -e "\nCan't access the code bucket. Does the service role for the server include access to the \"${ACCOUNT}\" code bucket? If windows, is a profile matching the account been set up? Nothing to do." >&2
        exit
    fi
fi

if [[ -d ${GENERATION_STARTUP_DIR} ]]; then
    cd ${GENERATION_STARTUP_DIR}
    aws --region ${ACCOUNT_REGION} s3 sync ${DRYRUN} ${DELETE} --exclude=".git*" bootstrap/ s3://${CODE_BUCKET}/bootstrap/
    RESULT=$?
    if [[ "$RESULT" -ne 0 ]]; then
        echo -e "\nCan't update the code bucket" >&2
        exit
    fi
else
    echo -e "\nStartup directory not found" >&2
    exit
fi

# Confirm access to the credentials bucket
if [[ "${CHECK}" == "true" ]]; then
    aws --region ${ACCOUNT_REGION} s3 ls s3://${CREDENTIALS_BUCKET}/ > temp_credential_access.txt
    RESULT=$?
    if [[ "$RESULT" -ne 0 ]]; then
        echo -e "\nCan't access the credentials bucket. Does the service role for the server include access to the \"${ACCOUNT}\" credentials bucket? If windows, is a profile matching the account been set up? Nothing to do." >&2
        exit
    fi
fi

if [[ -d ${ACCOUNT_CREDENTIALS_DIR}/alm/docker ]]; then
    cd ${ACCOUNT_CREDENTIALS_DIR}/alm/docker
    aws --region ${ACCOUNT_REGION} s3 sync ${DRYRUN} ${DELETE} . s3://${CREDENTIALS_BUCKET}/${ACCOUNT}/alm/docker/
    RESULT=$?
    if [[ "$RESULT" -ne 0 ]]; then
        echo -e "\nCan't update the code bucket" >&2
        exit
    fi
else
    echo -e "\nDocker directory not found - ignoring docker credentials"
fi

