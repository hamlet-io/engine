#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_BASE_DIR}/execution/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_BASE_DIR}/execution/common.sh"

CERTIFICATE_OPERATION_LIST="list"
CERTIFICATE_OPERATION_DELETE="delete"
CERTIFICATE_OPERATION_UPLOAD="upload"

# Defaults
CERTIFICATE_OPERATION_DEFAULT="${CERTIFICATE_OPERATION_UPLOAD}"

function usage() {
    cat <<EOF

Update SSL certificate details in AWS

Usage: $(basename $0) -i CERTIFICATE_ID -p CERTIFICATE_PUBLIC -v CERTIFICATE_PRIVATE -c CERTIFICATE_CHAIN -r REGION -q
    or $(basename $0) -i CERTIFICATE_ID -d
    or $(basename $0) -l

where

(c) -c CERTIFICATE_CHAIN    is the path to the file containing intermediate certificates, required for upload operation
    -h                      shows this text
(c) -i CERTIFICATE_ID       is the id of the certificate, required for delete and upload operations
(c) -p CERTIFICATE_PUBLIC   is the path to the public certificate file, required for upload operation
(o) -q                      minimal output (quiet)
(c) -r REGION               is the AWS region identifier for the region where the certificate should be updated, required for upload operation
(c) -v CERTIFICATE_PRIVATE  is the path to the private certificate file, required for upload operation
(o) -l (CERTIFICATE_OPERATION=${CERTIFICATE_OPERATION_LIST}) to list the certificates
(o) -d (CERTIFICATE_OPERATION=${CERTIFICATE_OPERATION_DELETE}) to delete the certificate

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

CERTIFICATE_OPERATION = ${CERTIFICATE_OPERATION_DEFAULT}

NOTES:

1. The Id is used as the name of the certificate within AWS
2. The certificate will be loaded for both ELB (/ssl/) and CloudFront (/cloudfront/)

EOF
    exit
}

# Parse options
while getopts ":c:hi:p:qr:v:dl" opt; do
    case $opt in
        c)
            CERTIFICATE_CHAIN="${OPTARG}"
            ;;
        d)
            CERTIFICATE_OPERATION=${CERTIFICATE_OPERATION_DELETE}
            ;;
        l)
            CERTIFICATE_OPERATION=${CERTIFICATE_OPERATION_LIST}
            ;;
        h)
            usage
            ;;
        i)
            CERTIFICATE_ID="${OPTARG}"
            ;;
        p)
            CERTIFICATE_PUBLIC="${OPTARG}"
            ;;
        q)
            QUIET="true"
            ;;
        r)
            REGION="${OPTARG}"
            ;;
        v)
            CERTIFICATE_PRIVATE="${OPTARG}"
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Apply defaults
CERTIFICATE_OPERATION=${CERTIFICATE_OPERATION:-${CERTIFICATE_OPERATION_DEFAULT}}


# Ensure mandatory arguments have been provided
case ${CERTIFICATE_OPERATION} in
    ${CERTIFICATE_OPERATION_LIST})
        ;;
    ${CERTIFICATE_OPERATION_DELETE})
        [[ (-z "${CERTIFICATE_ID}") ]] &&
            fatal "Insufficient arguments for \"${CERTIFICATE_OPERATION}\" operation"
        ;;
    ${CERTIFICATE_OPERATION_UPLOAD})
        [[ (-z "${CERTIFICATE_ID}") ||
            (-z "${CERTIFICATE_PUBLIC}") ||
            (-z "${CERTIFICATE_PRIVATE}") ||
            (-z "${CERTIFICATE_CHAIN}") ||
            (-z "${REGION}") ]] &&
            fatal "Insufficient arguments for \"${CERTIFICATE_OPERATION}\" operation"
        ;;
    *)
        fatal "\"${CERTIFICATE_OPERATION}\" is not one of the known certificate operations."
        ;;
esac

# Set up the context
. "${GENERATION_BASE_DIR}/execution/setContext.sh"

case ${CERTIFICATE_OPERATION} in
    ${CERTIFICATE_OPERATION_LIST})
        aws --region ${REGION} iam list-server-certificates > temp_ssl_list.out 2>&1
        RESULT=$?
        if [[ ("${QUIET}" != "true")  || ( "${RESULT}" -ne 0 ) ]]; then cat temp_ssl_list.out; fi
        # For list - ?
        ;;
    ${CERTIFICATE_OPERATION_DELETE})
        aws --region ${REGION} iam delete-server-certificate --server-certificate-name ${CERTIFICATE_ID}-ssl > temp_ssl_delete.out 2>&1
        RESULT=$?
        if [[ ("${QUIET}" != "true")  || ( "${RESULT}" -ne 0 ) ]]; then cat temp_ssl_delete.out; fi
        aws --region ${REGION} iam delete-server-certificate --server-certificate-name ${CERTIFICATE_ID}-cloudfront > temp_cloudfront_delete.out 2>&1
        RESULT=$?
        if [[ ("${QUIET}" != "true")  || ( "${RESULT}" -ne 0 ) ]]; then cat temp_cloudfront_delete.out; fi
        # For delete - ?
        ;;
    ${CERTIFICATE_OPERATION_UPLOAD})
        # Copy files locally to keep aws call simple
        LOCAL_CERTIFICATE_PUBLIC="temp_$(basename ${CERTIFICATE_PUBLIC})"
        LOCAL_CERTIFICATE_PRIVATE="temp_$(basename ${CERTIFICATE_PRIVATE})"
        LOCAL_CERTIFICATE_CHAIN="temp_$(basename ${CERTIFICATE_CHAIN})"
        cp "${CERTIFICATE_PUBLIC}"  "${LOCAL_CERTIFICATE_PUBLIC}"
        cp "${CERTIFICATE_PRIVATE}" "${LOCAL_CERTIFICATE_PRIVATE}"
        cp "${CERTIFICATE_CHAIN}"   "${LOCAL_CERTIFICATE_CHAIN}"


        aws --region ${REGION} iam get-server-certificate --server-certificate-name ${CERTIFICATE_ID}-ssl > temp_ssl_check.out 2>&1
        RESULT=$?
        if [[ "${QUIET}" != "true" ]]; then cat temp_ssl_check.out; fi
        if [[ "${RESULT}" -ne 0 ]]; then
            if [[ "${MINGW64}" == "true" ]]; then
                MSYS_NO_PATHCONV=1 aws --region ${REGION} iam upload-server-certificate \
                                                  --server-certificate-name ${CERTIFICATE_ID}-ssl \
                                                  --path "/ssl/${CERTIFICATE_ID}/" \
                                                  --certificate-body file://${LOCAL_CERTIFICATE_PUBLIC} \
                                                  --private-key file://${LOCAL_CERTIFICATE_PRIVATE} \
                                                  --certificate-chain file://${LOCAL_CERTIFICATE_CHAIN}
            else
                aws --region ${REGION} iam upload-server-certificate \
                                                  --server-certificate-name ${CERTIFICATE_ID}-ssl \
                                                  --path "/ssl/${CERTIFICATE_ID}/" \
                                                  --certificate-body file://${LOCAL_CERTIFICATE_PUBLIC} \
                                                  --private-key file://${LOCAL_CERTIFICATE_PRIVATE} \
                                                  --certificate-chain file://${LOCAL_CERTIFICATE_CHAIN}
            fi
            RESULT=$?
            if [[ "${RESULT}" -ne 0 ]]; then exit; fi
        fi

        aws --region ${REGION} iam get-server-certificate --server-certificate-name ${CERTIFICATE_ID}-cloudfront > temp_cloudfront_check.out 2>&1
        RESULT=$?
        if [[ "${QUIET}" != "true" ]]; then cat temp_cloudfront_check.out; fi
        if [[ "${RESULT}" -ne 0 ]]; then
            if [[ "${MINGW64}" == "true" ]]; then
                MSYS_NO_PATHCONV=1  aws --region ${REGION} iam upload-server-certificate \
                                                   --server-certificate-name ${CERTIFICATE_ID}-cloudfront \
                                                   --path "/cloudfront/${CERTIFICATE_ID}/" \
                                                   --certificate-body file://${LOCAL_CERTIFICATE_PUBLIC} \
                                                   --private-key file://${LOCAL_CERTIFICATE_PRIVATE} \
                                                   --certificate-chain file://${LOCAL_CERTIFICATE_CHAIN}
            else
                aws --region ${REGION} iam upload-server-certificate
                                                   --server-certificate-name ${CERTIFICATE_ID}-cloudfront \
                                                   --path "/cloudfront/${CERTIFICATE_ID}/" \
                                                   --certificate-body file://${LOCAL_CERTIFICATE_PUBLIC} \
                                                   --private-key file://${LOCAL_CERTIFICATE_PRIVATE} \
                                                   --certificate-chain file://${LOCAL_CERTIFICATE_CHAIN}
            fi
            RESULT=$?
        fi
        ;;
esac
