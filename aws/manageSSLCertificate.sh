#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
    echo -e "\nUpdate SSL certificate details in AWS" 
    echo -e "\nUsage: $(basename $0) -i CERTIFICATE_ID -p CERTIFICATE_PUBLIC -v CERTIFICATE_PRIVATE -c CERTIFICATE_CHAIN -r REGION -q"
    echo -e "\nwhere\n"
    echo -e "(m) -c CERTIFICATE_CHAIN is the path to the file containing intermediate certificates"
    echo -e "    -h shows this text"
    echo -e "(m) -i CERTIFICATE_ID is the id of the certificate"
    echo -e "(m) -p CERTIFICATE_PUBLIC is the path to the public certificate file"
    echo -e "(o) -q minimal output (quiet)"
    echo -e "(m) -r REGION is the AWS region identifier for the region where the certificate should be updated"
    echo -e "(m) -v CERTIFICATE_PRIVATE is the path to the private certificate file"
    echo -e "\nNOTES:\n"
    echo -e "1. The Id is used as the name of the certificate within AWS"
    echo -e "2. The certificate will be loaded for both ELB (/ssl/) and CloudFront (/cloudfront/)"
    echo -e ""
    exit
}

# Parse options
while getopts ":c:hi:p:qr:v:" opt; do
    case $opt in
        c)
            CERTIFICATE_CHAIN="${OPTARG}"
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
if [[ (-z "${CERTIFICATE_ID}") ||
      (-z "${CERTIFICATE_PUBLIC}") ||
      (-z "${CERTIFICATE_PRIVATE}") ||
      (-z "${CERTIFICATE_CHAIN}") ||
      (-z "${REGION}") ]]; then
  echo -e "\nInsufficient arguments"
  usage
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

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

