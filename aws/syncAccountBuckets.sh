#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults

function usage() {
    cat <<EOF

Synchronise the contents of the code and credentials buckets to the local values

Usage: $(basename $0) -q -x -y

where

    -h  shows this text
(o) -q  for no check (quick) - don't check bucket access before attempting to synchronise
(o) -x  for no delete - by default files in the buckets that are absent locally are deleted
(o) -y  for a dryrun - show what will happen without actually transferring any files

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
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Set up the context
. "${GENERATION_DIR}/setContext.sh"

checkInAccountDirectory

# Locate the bucket names
CODE_BUCKET=$(getCompositeStackOutput "${COMPOSITE_STACK_OUTPUTS}" "s3XaccountXcode")
CREDENTIALS_BUCKET=$(getCompositeStackOutput "${COMPOSITE_STACK_OUTPUTS}" "s3XaccountXcredentials")

[[ (-z "${CODE_BUCKET}") ||
    (-z "${CREDENTIALS_BUCKET}") ||
    (-z "${ACCOUNT_REGION}") ]] &&
    fatal "Buckets don't appear to have been created. Maybe create the Account stack first?"

pushd ${ACCOUNT_DIR}  > /dev/null 2>&1

# Confirm access to the code bucket
if [[ "${CHECK}" == "true" ]]; then
    aws --region ${ACCOUNT_REGION} s3 ls s3://${CODE_BUCKET}/ > temp_code_access.txt
    RESULT=$?
    [[ "$RESULT" -ne 0 ]] &&
        fatal "Can't access the code bucket. Does the service role for the server include access to the \"${ACCOUNT}\" code bucket? If windows, is a profile matching the account been set up?"
fi

if [[ -d ${GENERATION_STARTUP_DIR} ]]; then
    cd ${GENERATION_STARTUP_DIR}
    aws --region ${ACCOUNT_REGION} s3 sync ${DRYRUN} ${DELETE} --exclude=".git*" bootstrap/ s3://${CODE_BUCKET}/bootstrap/
    RESULT=$?
    [[ "$RESULT" -ne 0 ]] && fatal "Can't update the code bucket"

else
    fatal "Startup directory not found"
fi

# Confirm access to the credentials bucket
if [[ "${CHECK}" == "true" ]]; then
    aws --region ${ACCOUNT_REGION} s3 ls s3://${CREDENTIALS_BUCKET}/ > temp_credential_access.txt
    RESULT=$?
    [[ "$RESULT" -ne 0 ]] &&
        fatal "Can't access the credentials bucket. Does the service role for the server include access to the \"${ACCOUNT}\" credentials bucket? If windows, is a profile matching the account been set up?"
fi

if [[ -d ${ACCOUNT_CREDENTIALS_DIR}/alm/docker ]]; then
    cd ${ACCOUNT_CREDENTIALS_DIR}/alm/docker
    aws --region ${ACCOUNT_REGION} s3 sync ${DRYRUN} ${DELETE} . s3://${CREDENTIALS_BUCKET}/${ACCOUNT}/alm/docker/
    RESULT=$?
    [[ "$RESULT" -ne 0 ]] && fatal "Can't update the code bucket"
else
    info "Docker directory not found - ignoring docker credentials"
fi

