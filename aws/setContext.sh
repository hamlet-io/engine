#!/bin/bash

# Based on current directory location and existing environment,
# define additional environment variables to facilitate automation
#
# This script is designed to be sourced into other scripts

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi

# If the context has already been determined, there is nothing to do
if [[ -n "${GENERATION_CONTEXT_DEFINED}" ]]; then return 0; fi
export GENERATION_CONTEXT_DEFINED="true"
GENERATION_CONTEXT_DEFINED_LOCAL="true"

# Utility functions
. ${GENERATION_DIR}/common.sh

[[ -n "${GENERATION_DEBUG}" ]] && echo -e "\n--- starting setContext.sh ---\n"

# If no files match a glob, return nothing
# Many of the file existence for loops in this script rely on this setting
shopt -s nullglob

# Generate the list of files constituting the composites based on the contents
# of the account and product trees
# The blueprint is handled specially as its logic is different to the others
pushd "$(pwd)" >/dev/null
COMPOSITES=("ACCOUNT" "PRODUCT" "SEGMENT" "SOLUTION" "APPLICATION" "POLICY" "CONTAINER" "ID" "NAME")
BLUEPRINT_ARRAY=()
for COMPOSITE in "${COMPOSITES[@]}"; do
    # define the array holding the list of composite fragment filenames
    declare -a "${COMPOSITE}_ARRAY"

    # Check for composite start fragment
    for FRAGMENT in ${GENERATION_DIR}/templates/${COMPOSITE,,}/*start.ftl; do
        eval "${COMPOSITE}_ARRAY+=(\"${FRAGMENT}\")"
    done
    
    # If no composite specific start fragment, use a generic one
    eval "FRAGMENT_COUNT=\"\${#${COMPOSITE}_ARRAY[@]}\""
    if [[ "${FRAGMENT_COUNT}" -eq 0 ]]; then
        eval "${COMPOSITE}_ARRAY+=(\"${GENERATION_DIR}/templates/start.ftl\")"
    fi

done

if [[ (-f "segment.json") || (-f "container.json") ]]; then
    # segment directory
    export LOCATION="${LOCATION:-segment}"
    export SEGMENT_DIR="$(pwd)"
    export SEGMENT="$(basename $(pwd))"

    if [[ -f "segment.json" ]]; then
        BLUEPRINT_ARRAY=("${SEGMENT_DIR}/segment.json" "${BLUEPRINT_ARRAY[@]}")
    fi
    if [[ -f "container.json" ]]; then
        BLUEPRINT_ARRAY=("${SEGMENT_DIR}/container.json" "${BLUEPRINT_ARRAY[@]}")
    fi
    if [[ -f "solution.json" ]]; then
        BLUEPRINT_ARRAY=("${SEGMENT_DIR}/solution.json" "${BLUEPRINT_ARRAY[@]}")
    fi

    # Segment based composite fragments
    for COMPOSITE in "${COMPOSITES[@]}"; do
        for FRAGMENT in ${COMPOSITE,,}_*.ftl; do
            eval "${COMPOSITE}_ARRAY+=(\"${SEGMENT_DIR}/${FRAGMENT}\")"
        done
    done

    cd ..    

    # solutions directory
    # only add files if not already present
    export SOLUTIONS_DIR="$(pwd)"
    if [[ (-f "solution.json") && (!("${BLUEPRINT_ARRAY}" =~ solution.json)) ]]; then
        BLUEPRINT_ARRAY=("${SOLUTIONS_DIR}/solution.json" "${BLUEPRINT_ARRAY[@]}")
    fi
    
    for COMPOSITE in "${COMPOSITES[@]}"; do
        for FRAGMENT in ${COMPOSITE,,}_*.ftl; do
            eval "[[ \"\${${COMPOSITE}_ARRAY[*]}\" =~ ${FRAGMENT} ]]"
            if [[ $? -ne 0 ]]; then
                eval "${COMPOSITE}_ARRAY+=(\"${SOLUTIONS_DIR}/${FRAGMENT}\")"
            fi
        done
    done

    cd ..
fi

if [[ -f "account.json" ]]; then
    # account directory
    # We check it before checking for a product as the account directory
    # also acts as a product directory for shared infrastructure
    # An account directory may also have no product information e.g.
    # in the case of production environments in dedicated accounts.
    export LOCATION="${LOCATION:-account}"
    export GENERATION_DATA_DIR="$(cd ../..;pwd)"
fi

if [[ -f "product.json" ]]; then
    # product directory
    if [[ "${LOCATION}" == "account" ]]; then
        export LOCATION="account|product"
    else
        export LOCATION="${LOCATION:-product}"
    fi
    export PRODUCT_DIR="$(pwd)"
    export PRODUCT="$(basename $(pwd))"

    BLUEPRINT_ARRAY=("${PRODUCT_DIR}/product.json" "${BLUEPRINT_ARRAY[@]}")
    export GENERATION_DATA_DIR="$(cd ../..;pwd)"
fi

if [[ -f "integrator.json" ]]; then
    export LOCATION="${LOCATION:-integrator}"
    export GENERATION_DATA_DIR="$(pwd)"
    export INTEGRATOR="$(basename $(pwd))"
fi

if [[ (-d config) && (-d infrastructure) ]]; then
    export LOCATION="${LOCATION:-root}"
    export GENERATION_DATA_DIR="$(pwd)"
fi

if [[ -z "${GENERATION_DATA_DIR}" ]]; then
    echo -e "\nCan't locate the root of the directory tree. Are we in the right place?" >&2
    exit
fi

# root directory
cd "${GENERATION_DATA_DIR}"
export ACCOUNT="$(basename $(pwd))"
popd >/dev/null

export CONFIG_DIR="${GENERATION_DATA_DIR}/config"
export INFRASTRUCTURE_DIR="${GENERATION_DATA_DIR}/infrastructure"
export TENANT_DIR="${CONFIG_DIR}/${ACCOUNT}"
export ACCOUNT_DIR="${CONFIG_DIR}/${ACCOUNT}"
export ACCOUNT_CREDENTIALS_DIR="${INFRASTRUCTURE_DIR}/${ACCOUNT}/credentials"
export ACCOUNT_APPSETTINGS_DIR="${ACCOUNT_DIR}/appsettings"
export ACCOUNT_CREDENTIALS="${ACCOUNT_CREDENTIALS_DIR}/credentials.json"
    
if [[ -f "${ACCOUNT_DIR}/account.json" ]]; then
    BLUEPRINT_ARRAY=("${ACCOUNT_DIR}/account.json" "${BLUEPRINT_ARRAY[@]}")
fi

if [[ -f "${TENANT_DIR}/tenant.json" ]]; then
    BLUEPRINT_ARRAY=("${TENANT_DIR}/tenant.json" "${BLUEPRINT_ARRAY[@]}")
fi

# Build the composite solution ( aka blueprint)
[[ -n "${GENERATION_DEBUG}" ]] && echo -e "\nBLUEPRINT=${BLUEPRINT_ARRAY[*]}"
export COMPOSITE_BLUEPRINT="${CONFIG_DIR}/composite_blueprint.json"
if [[ "${#BLUEPRINT_ARRAY[@]}" -gt 0 ]]; then
    GENERATION_MASTER_DATA_DIR="${GENERATION_MASTER_DATA_DIR:-${GENERATION_DIR}/data}"
    ${GENERATION_DIR}/manageJSON.sh -d -o "${COMPOSITE_BLUEPRINT}" "${GENERATION_MASTER_DATA_DIR}/masterData.json" "${BLUEPRINT_ARRAY[@]}"
else
    echo "{}" > ${COMPOSITE_BLUEPRINT}
fi
    
# Extract key settings from the composite solution
# Ignore values generated by addition of default Id/Name attribute values
export TID=${TID:-$(jq -r '.Tenant.Id | select(.!="Tenant") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export TENANT=${TENANT:-$(jq -r '.Tenant.Name | select(.!="Tenant") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export AID=${AID:-$(jq -r '.Account.Id | select(.!="Account") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export AWSID=${AWSID:-$(jq -r '.Account.AWSId | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export ACCOUNT_REGION=${ACCOUNT_REGION:-$(jq -r '.Account.Region | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export PID=${PID:-$(jq -r '.Product.Id | select(.!="Product") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export PRODUCT_REGION=${PRODUCT_REGION:-$(jq -r '.Product.Region | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export SID=${SID:-$(jq -r '.Segment.Id | select(.!="Segment") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export REGION="${REGION:-$PRODUCT_REGION}"

# Perform a few consistency checks
if [[ -z "${REGION}" ]]; then
    echo -e "\nThe region must be defined in the Product blueprint section. Nothing to do." >&2
    exit
fi
BLUEPRINT_ACCOUNT=$(jq -r '.Account.Name | select(.!=null)' < ${COMPOSITE_BLUEPRINT})
BLUEPRINT_PRODUCT=$(jq -r '.Product.Name | select(.!=null)' < ${COMPOSITE_BLUEPRINT})
BLUEPRINT_SEGMENT=$(jq -r '.Segment.Name | select(.!=null)' < ${COMPOSITE_BLUEPRINT})
if [[ (-n "${ACCOUNT}") &&
        ("${BLUEPRINT_ACCOUNT}" != "Account") &&
        ("${ACCOUNT}" != "${BLUEPRINT_ACCOUNT}") ]]; then
    echo -e "\nBlueprint account of ${BLUEPRINT_ACCOUNT} doesn't match expected value of ${ACCOUNT}" >&2
    exit
fi
if [[ (-n "${PRODUCT}") &&
        ("${BLUEPRINT_PRODUCT}" != "Product") &&
        ("${PRODUCT}" != "${BLUEPRINT_PRODUCT}") ]]; then
    echo -e "\nBlueprint product of ${BLUEPRINT_PRODUCT} doesn't match expected value of ${PRODUCT}" >&2
    exit
fi
if [[ (-n "${SEGMENT}") &&
        ("${BLUEPRINT_SEGMENT}" != "Segment") &&
        ("${SEGMENT}" != "${BLUEPRINT_SEGMENT}") ]]; then
    echo -e "\nBlueprint segment of ${BLUEPRINT_SEGMENT} doesn't match expected value of ${SEGMENT}" >&2
    exit
fi

# Add default composite fragments including end fragment
for COMPOSITE in "${COMPOSITES[@]}"; do
    for FRAGMENT in ${GENERATION_DIR}/templates/${COMPOSITE,,}/${COMPOSITE,,}_*.ftl; do
        eval "[[ \"x\${${COMPOSITE}_ARRAY[*]}\" =~ x\$(basename ${FRAGMENT}) ]]"
        if [[ $? -ne 0 ]]; then
            eval "${COMPOSITE}_ARRAY+=(\"${FRAGMENT}\")"
        fi
    done
    for FRAGMENT in ${GENERATION_DIR}/templates/${COMPOSITE,,}/*end.ftl; do
        eval "${COMPOSITE}_ARRAY+=(\"${FRAGMENT}\")"
    done
done

# create the composites if one or more fragments have been found
# note that the composite will be created even if only a start and/or end
# fragment has been found
for COMPOSITE in "${COMPOSITES[@]}"; do
    eval "FRAGMENT_COUNT=\"\${#${COMPOSITE}_ARRAY[@]}\""
    if [[ "${FRAGMENT_COUNT}" -gt 1 ]]; then
        [[ -n "${GENERATION_DEBUG}" ]] && eval "echo -e \"\\n${COMPOSITE}=\${${COMPOSITE}_ARRAY[*]}\""
        eval "export COMPOSITE_${COMPOSITE}=\${CONFIG_DIR}/composite_${COMPOSITE,,}.ftl"
        eval "cat \"\${${COMPOSITE}_ARRAY[@]}\" > \${COMPOSITE_${COMPOSITE}}"
    fi
done

# Product specific context if the product is known
APPSETTINGS_ARRAY=()
CREDENTIALS_ARRAY=()
if [[ -n "${PRODUCT}" ]]; then
    export SOLUTIONS_DIR="${CONFIG_DIR}/${PRODUCT}/solutions"
    export APPSETTINGS_DIR="${CONFIG_DIR}/${PRODUCT}/appsettings"
    export CREDENTIALS_DIR="${INFRASTRUCTURE_DIR}/${PRODUCT}/credentials"
    
    # deployment unit level appsettings
    if [[ (-n "${DEPLOYMENT_UNIT}") ]]; then
        # Confirm it is an application deployment unit
        . ${GENERATION_DIR}/validateDeploymentUnit.sh
        if [[ "${IS_APPLICATION_UNIT}" == "true" ]]; then
        
            if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/appsettings.json" ]]; then
                APPSETTINGS_ARRAY=("${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/appsettings.json" "${APPSETTINGS_ARRAY[@]}")
            fi

            export BUILD_DEPLOYMENT_UNIT="${DEPLOYMENT_UNIT}"   
            # Legacy naming to support products using the term "slice" or "unit" instead of "deployment_unit"
            if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/slice.ref" ]]; then
                export BUILD_DEPLOYMENT_UNIT=$(cat "${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/slice.ref")
            fi
            if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/unit.ref" ]]; then
                export BUILD_DEPLOYMENT_UNIT=$(cat "${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/unit.ref")
            fi
            if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/deployment_unit.ref" ]]; then
                export BUILD_DEPLOYMENT_UNIT=$(cat "${APPSETTINGS_DIR}/${SEGMENT}/${DEPLOYMENT_UNIT}/deployment_unit.ref")
            fi
            
            if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/appsettings.json" ]]; then
                APPSETTINGS_ARRAY=("${APPSETTINGS_DIR}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/appsettings.json" "${APPSETTINGS_ARRAY[@]}")
            fi            

            if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/build.json" ]]; then
                export BUILD_REFERENCE=$(cat "${APPSETTINGS_DIR}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/build.json")
            else
                if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/build.ref" ]]; then
                    export BUILD_REFERENCE=$(cat "${APPSETTINGS_DIR}/${SEGMENT}/${BUILD_DEPLOYMENT_UNIT}/build.ref")
                fi
            fi
        fi
    fi
    
    # segment level appsettings/credentials
    if [[ (-n "${SEGMENT}") ]]; then
        if [[ -f "${APPSETTINGS_DIR}/${SEGMENT}/appsettings.json" ]]; then
            APPSETTINGS_ARRAY=("${APPSETTINGS_DIR}/${SEGMENT}/appsettings.json" "${APPSETTINGS_ARRAY[@]}")
        fi

        if [[ -f "${CREDENTIALS_DIR}/${SEGMENT}/credentials.json" ]]; then
        CREDENTIALS_ARRAY=("${CREDENTIALS_DIR}/${SEGMENT}/credentials.json" "${CREDENTIALS_ARRAY[@]}")
        fi
    fi
    
    # product level appsettings
    if [[ -f "${APPSETTINGS_DIR}/appsettings.json" ]]; then
        APPSETTINGS_ARRAY=("${APPSETTINGS_DIR}/appsettings.json" "${APPSETTINGS_ARRAY[@]}")
    fi

    # product level credentials
    if [[ -f "${CREDENTIALS_DIR}/credentials.json" ]]; then
        CREDENTIALS_ARRAY=("${CREDENTIALS_DIR}/credentials.json" "${CREDENTIALS_ARRAY[@]}")
    fi

    # account level appsettings
    if [[ -f "${ACCOUNT_APPSETTINGS_DIR}/appsettings.json" ]]; then
        APPSETTINGS_ARRAY=("${ACCOUNT_APPSETTINGS_DIR}/appsettings.json" "${APPSETTINGS_ARRAY[@]}")
    fi
fi

# Build the composite appsettings
[[ -n "${GENERATION_DEBUG}" ]] && echo -e "\nAPPSETTINGS=${APPSETTINGS_ARRAY[*]}"
export COMPOSITE_APPSETTINGS="${CONFIG_DIR}/composite_appsettings.json"
if [[ "${#APPSETTINGS_ARRAY[@]}" -gt 0 ]]; then
    ${GENERATION_DIR}/manageJSON.sh -c -o ${COMPOSITE_APPSETTINGS} "${APPSETTINGS_ARRAY[@]}"
else
    echo "{}" > ${COMPOSITE_APPSETTINGS}
fi    

# Check for account level credentials
if [[ -f "${ACCOUNT_CREDENTIALS_DIR}/credentials.json" ]]; then
    CREDENTIALS_ARRAY=("${ACCOUNT_CREDENTIALS_DIR}/credentials.json" "${CREDENTIALS_ARRAY[@]}")
fi

# Build the composite credentials
[[ -n "${GENERATION_DEBUG}" ]] && echo -e "\nCREDENTIALS=${CREDENTIALS_ARRAY[*]}"
export COMPOSITE_CREDENTIALS="${INFRASTRUCTURE_DIR}/composite_credentials.json"
if [[ "${#CREDENTIALS_ARRAY[@]}" -gt 0 ]]; then
    ${GENERATION_DIR}/manageJSON.sh -o ${COMPOSITE_CREDENTIALS} "${CREDENTIALS_ARRAY[@]}"
else
    echo "{}" > ${COMPOSITE_CREDENTIALS}
fi    

# Create the composite stack outputs
STACK_ARRAY=()
if [[ (-n "${ACCOUNT}") && (-d "${INFRASTRUCTURE_DIR}/${ACCOUNT}/aws/cf") ]]; then
    STACK_ARRAY+=(${INFRASTRUCTURE_DIR}/${ACCOUNT}/aws/cf/acc*-stack.json)
fi
if [[ (-n "${PRODUCT}") && (-n "${REGION}") && (-d "${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/cf") ]]; then
    STACK_ARRAY+=(${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/cf/product*-${REGION}-stack.json)
fi
if [[ (-n "${SEGMENT}") && (-n "${REGION}") && (-d "${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf") ]]; then
    STACK_ARRAY+=(${INFRASTRUCTURE_DIR}/${PRODUCT}/aws/${SEGMENT}/cf/*-${REGION}-stack.json)
fi

[[ -n "${GENERATION_DEBUG}" ]] && echo -e "\nSTACK_OUTPUTS=${STACK_ARRAY[*]}"
export COMPOSITE_STACK_OUTPUTS="${INFRASTRUCTURE_DIR}/composite_stack_outputs.json"
if [[ "${#STACK_ARRAY[@]}" -gt 0 ]]; then
    ${GENERATION_DIR}/manageJSON.sh -f "[.[].Stacks | select(.!=null) | .[].Outputs | select(.!=null) | .[]]" -o ${COMPOSITE_STACK_OUTPUTS} "${STACK_ARRAY[@]}"
else
    echo "[]" > ${COMPOSITE_STACK_OUTPUTS}
fi

# Set default AWS credentials if available (hook from Jenkins framework)
CHECK_AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-${ACCOUNT_TEMP_AWS_ACCESS_KEY_ID}}"
CHECK_AWS_ACCESS_KEY_ID="${CHECK_AWS_ACCESS_KEY_ID:-${!ACCOUNT_AWS_ACCESS_KEY_ID_VAR}}"
if [[ -n "${CHECK_AWS_ACCESS_KEY_ID}" ]]; then export AWS_ACCESS_KEY_ID="${CHECK_AWS_ACCESS_KEY_ID}"; fi

CHECK_AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-${ACCOUNT_TEMP_AWS_SECRET_ACCESS_KEY}}"
CHECK_AWS_SECRET_ACCESS_KEY="${CHECK_AWS_SECRET_ACCESS_KEY:-${!ACCOUNT_AWS_SECRET_ACCESS_KEY_VAR}}"
if [[ -n "${CHECK_AWS_SECRET_ACCESS_KEY}" ]]; then export AWS_SECRET_ACCESS_KEY="${CHECK_AWS_SECRET_ACCESS_KEY}"; fi

CHECK_AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-${ACCOUNT_TEMP_AWS_SESSION_TOKEN}}"
if [[ -n "${CHECK_AWS_SESSION_TOKEN}" ]]; then export AWS_SESSION_TOKEN="${CHECK_AWS_SESSION_TOKEN}"; fi

# Set the profile for IAM access if AWS credentials not in the environment
# We would normally redirect to /dev/null but this triggers an "unknown encoding"
# bug in python
if [[ ((-z "${AWS_ACCESS_KEY_ID}") || (-z "${AWS_SECRET_ACCESS_KEY}")) ]]; then
    if [[ -n "${ACCOUNT}" ]]; then
        aws configure list --profile "${ACCOUNT}" > temp_profile_status.txt 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${ACCOUNT}"
        fi
    fi
    if [[ -n "${AID}" ]]; then
        aws configure list --profile "${AID}" > temp_profile_status.txt 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${AID}"
        fi
    fi
    if [[ -n "${AWSID}" ]]; then
        aws configure list --profile "${AWSID}" > temp_profile_status.txt 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${AWSID}"
        fi
    fi
fi

# Handle some MINGW peculiarities
uname | grep -i "MINGW64" > /dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
    export MINGW64="true"
fi

# Detect if within a git repo
git status >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    export WITHIN_GIT_REPO="true"
    export FILE_MV="git mv"
    export FILE_RM="git rm"
else
    export FILE_MV="mv"
    export FILE_RM="rm"
fi

[[ -n "${GENERATION_DEBUG}" ]] && echo -e "\n--- finished setContext.sh ---\n"


