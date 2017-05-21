#!/bin/bash

# Utility Functions
#
# There are a few uses of this, e.g.
#
# This script is designed to be sourced into other scripts

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi

# -- S3 --

function getBucketName() {
    local key="${1}"

    BUCKET=$(jq -r ".[] | select(.OutputKey==\"${key}\") | .OutputValue | select(.!=null)" < ${COMPOSITE_STACK_OUTPUTS})
}

function getOperationsBucket() {
    getBucketName "s3XsegmentXops"
}

function getCodeBucket() {
    getBucketName "s3XaccountXcode"
}

function getCredentialsBucket() {
    getBucketName "s3XaccountXcredentials"
}

function isBucketAccessible() {
    local region="${1}"
    local bucket="${2}"
    local prefix="${3}"

    aws --region ${1} s3 ls "s3://${2}/${3}${3:+/}" > temp_bucket_access.txt
    return $?
}

function syncFilesToBucket() {
    local region="${1}"
    local bucket="${2}"
    local prefix="${3}"
    local filesArrayName="${4}[@]"
    local dryrunOrDelete="${5} ${6}"

    local filesArray=("${!filesArrayName}")
    local tempDir="./temp_copyfiles"
    
    rm -rf "${tempDir}"
    mkdir  "${tempDir}"
    
    # Copy files locally so we can synch with S3, potentially including deletes
    for file in "${filesArray[@]}" ; do
        if [[ -n "${file}" ]]; then
            case ${file##*.} in
                zip)
                    unzip "${file}" -d "${tempDir}"
                    ;;
                *)
                    cp "${file}" "${tempDir}"
                    ;;
            esac
        fi
    done
    
    # Now synch with s3
    aws --region ${region} s3 sync ${dryrunOrDelete} "${tempDir}/" "s3://${bucket}/${prefix}${prefix:+/}"
}
function deleteTreeFromBucket() {
    local region="${1}"
    local bucket="${2}"
    local prefix="${3}"
    local dryrun="${4}"

    # Delete everything below the prefix
    aws --region ${region} s3 rm --recursive ${dryrun} "s3://${bucket}/${prefix}/"
}

function syncCMDBFilesToOperationsBucket() {
    local sourceBaseDir="${1}"
    local prefix="${2}"
    local dryrun="${3}"

    SYNC_FILES_ARRAY=()

    SYNC_FILES_ARRAY+=(${sourceBaseDir}/${SEGMENT}/asFile/*)
    SYNC_FILES_ARRAY+=(${sourceBaseDir}/${SEGMENT}/${DEPLOYMENT_UNIT}/asFile/*)
    SYNC_FILES_ARRAY+=(${sourceBaseDir}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/asFile/*)

    getOperationsBucket
    syncFilesToBucket ${REGION} ${BUCKET} "${prefix}/${PRODUCT}/${SEGMENT}/${DEPLOYMENT_UNIT}" "SYNC_FILES_ARRAY" ${dryrun} --delete
}

function deleteCMDBFilesFromOperationsBucket() {
    local prefix="${1}"
    local dryrun="${2}"
        
    getOperationsBucket
    deleteTreeFromBucket ${REGION} ${BUCKET}  "${prefix}/${PRODUCT}/${SEGMENT}${DEPLOYMENT_UNIT}" ${dryrun}
}
