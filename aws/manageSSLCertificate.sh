#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

CERTIFICATE_OPERATION_DEFAULT="upload"

function usage() {
    echo -e "\nUpdate SSL certificate details in AWS" 
    echo -e "\nUsage: $(basename $0) -i CERTIFICATE_ID -p CERTIFICATE_PUBLIC -v CERTIFICATE_PRIVATE -c CERTIFICATE_CHAIN -r REGION -q"
    echo -e "\nor $(basename $0) -i CERTIFICATE_ID -d"
    echo -e "\nor $(basename $0) -l"
    echo -e "\nwhere\n"
    echo -e "(c) -c CERTIFICATE_CHAIN is the path to the file containing intermediate certificates, required for upload operation"
    echo -e "    -h shows this text"
    echo -e "(c) -i CERTIFICATE_ID is the id of the certificate, required for delete and upload operations"
    echo -e "(c) -p CERTIFICATE_PUBLIC is the path to the public certificate file, required for upload operation"
    echo -e "(o) -q minimal output (quiet)"
    echo -e "(c) -r REGION is the AWS region identifier for the region where the certificate should be updated, required for upload operation"
    echo -e "(c) -v CERTIFICATE_PRIVATE is the path to the private certificate file, required for upload operation"
    echo -e "(o) -l (CERTIFICATE_OPERATION=list) to list the certificates"
    echo -e "(o) -d (CERTIFICATE_OPERATION=delete) to delete the certificate"
    echo -e "\nDEFAULTS:\n"
    echo -e "CERTIFICATE_OPERATION = ${CERTIFICATE_OPERATION_DEFAULT}"
    echo -e "\nNOTES:\n"
    echo -e "1. The Id is used as the name of the certificate within AWS"
    echo -e "2. The certificate will be loaded for both ELB (/ssl/) and CloudFront (/cloudfront/)"
    echo -e ""
    exit
}

# Parse options
while getopts ":c:hi:p:qr:v:dl" opt; do
    case $opt in
        c)
            CERTIFICATE_CHAIN="${OPTARG}"
            ;;
        d)
            CERTIFICATE_OPERATION=delete
            ;;
        l)
            CERTIFICATE_OPERATION=list
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

# Apply defaults
CERTIFICATE_OPERATION=${CERTIFICATE_OPERATION:-${CERTIFICATE_OPERATION_DEFAULT}}


# Ensure mandatory arguments have been provided
case ${CERTIFICATE_OPERATION} in
	list)
		;;
	delete)
		if [[ (-z "${CERTIFICATE_ID}") ]]; then
		  echo -e "\nInsufficient arguments for \"${CERTIFICATE_OPERATION}\" operation"
		  usage
		fi
		;;
	upload)
		if [[ (-z "${CERTIFICATE_ID}") ||
			  (-z "${CERTIFICATE_PUBLIC}") ||
			  (-z "${CERTIFICATE_PRIVATE}") ||
			  (-z "${CERTIFICATE_CHAIN}") ||
			  (-z "${REGION}") ]]; then
		  echo -e "\nInsufficient arguments for \"${CERTIFICATE_OPERATION}\" operation"
		  usage
		fi
		;;
	*)
		echo -e "\n\"${CERTIFICATE_OPERATION}\" is not one of the known certificate operations."
		usage
		;;
esac

# Set up the context
. ${GENERATION_DIR}/setContext.sh

case ${CERTIFICATE_OPERATION} in
	list)
		aws --region ${REGION} iam list-server-certificates > temp_ssl_list.out 2>&1
		RESULT=$?
		if [[ ("${QUIET}" != "true")  || ( "${RESULT}" -ne 0 ) ]]; then cat temp_ssl_list.out; fi
        # For list - ?
		;;
	delete)
		aws --region ${REGION} iam delete-server-certificate --server-certificate-name ${CERTIFICATE_ID}-ssl > temp_ssl_delete.out 2>&1
		RESULT=$?
		if [[ ("${QUIET}" != "true")  || ( "${RESULT}" -ne 0 ) ]]; then cat temp_ssl_delete.out; fi
		aws --region ${REGION} iam delete-server-certificate --server-certificate-name ${CERTIFICATE_ID}-cloudfront > temp_cloudfront_delete.out 2>&1
		RESULT=$?
		if [[ ("${QUIET}" != "true")  || ( "${RESULT}" -ne 0 ) ]]; then cat temp_cloudfront_delete.out; fi
		# For delete - ?
		;;
	upload)
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


