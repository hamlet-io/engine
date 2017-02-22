#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults

function usage() {
    cat <<-EOF
  		Update SSH certificate details in AWS
  		Usage: $(basename $0) -i CERTIFICATE_ID -p CERTIFICATE_PUBLIC -r REGION -q
  		where
  		    -h shows this text
  		(m) -i CERTIFICATE_ID is the id of the certificate
  		(m) -p CERTIFICATE_PUBLIC is the path to the public certificate file
  		(o) -q minimal output (quiet)
  		(m) -r REGION is the AWS region identifier for the region where the certificate should be updated
  		NOTES:
  		1. The Id is used as the name of the certificate within AWS
	EOF
    exit
}

# Parse options
while getopts ":hi:p:qr:" opt; do
    case $opt in
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
      (-z "${REGION}") ]]; then
  echo -e "\nInsufficient arguments"
  usage
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Copy files locally to keep aws call simple
LOCAL_CERTIFICATE_PUBLIC="temp_$(basename ${CERTIFICATE_PUBLIC})"
cp "${CERTIFICATE_PUBLIC}"  "${LOCAL_CERTIFICATE_PUBLIC}"

aws --region ${REGION} ec2 describe-key-pairs --key-name ${CERTIFICATE_ID} > temp_ssh_check.out 2>&1
RESULT=$?
if [[ "${QUIET}" != "true" ]]; then cat temp_ssh_check.out; fi
if [[ "${RESULT}" -ne 0 ]]; then
    CRT=$(cat "${LOCAL_CERTIFICATE_PUBLIC}" | dos2unix | awk 'BEGIN {RS="\n"} /^[^-]/ {printf $1}')
    aws --region ${REGION} ec2 import-key-pair --key-name ${CERTIFICATE_ID} --public-key-material $CRT
    RESULT=$?
fi

