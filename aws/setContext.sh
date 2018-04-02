#!/usr/bin/env bash

# Based on current directory location and existing environment,
# define additional environment variables to facilitate automation
#
# Key variables are
# AGGREGATOR
# INTEGRATOR
# TENANT
# PRODUCT
# ACCOUNT
# SEGMENT
#
# This script is designed to be sourced into other scripts

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# If the context has already been determined, there is nothing to do
if [[ -n "${GENERATION_CONTEXT_DEFINED}" ]]; then return 0; fi

export GENERATION_CONTEXT_DEFINED="true"
GENERATION_CONTEXT_DEFINED_LOCAL="true"

debug "--- starting setContext.sh ---\n"

# Create a temporary directory for this run
[[ -z "${GENERATION_TMPDIR}" ]] && export GENERATION_TMPDIR="$(getTempDir "cot_XXX" )"
debug "TMPDIR=${GENERATION_TMPDIR}"

# If no files match a glob, return nothing
# Much of the logic in this script relies on this setting
shopt -s nullglob

# Check the root of the context tree can be located
export GENERATION_DATA_DIR=$(findGen3RootDir "$(pwd)") ||
  { fatal "Can't locate the root of the directory tree."; exit 1; }

# Check the cmdb doesn't need upgrading
# upgrade_cmdb "${GENERATION_DATA_DIR}" "dryrun" ||
#  { fatal "CMDB upgrade needed."; exit 1; }

# Generate the list of files constituting the composites based on the contents
# of the account and product trees
# The blueprint is handled specially as its logic is different to the others
TEMPLATE_COMPOSITES=(
    "ACCOUNT" "PRODUCT" "SEGMENT" "SOLUTION" "APPLICATION" \
    "POLICY" "CONTAINER" "ID" "NAME" "RESOURCE")
BLUEPRINT_ARRAY=()
for COMPOSITE in "${TEMPLATE_COMPOSITES[@]}"; do
    # define the array holding the list of composite fragment filenames
    declare -ga "${COMPOSITE}_ARRAY"

    # Check for composite start fragment
    addToArray "${COMPOSITE}_ARRAY" "${GENERATION_DIR}"/templates/"${COMPOSITE,,}"/start*.ftl

    # If no composite specific start fragment, use a generic one
    $(inArray "${COMPOSITE}_ARRAY" "start.ftl") ||
        addToArray "${COMPOSITE}_ARRAY" "${GENERATION_DIR}"/templates/start.ftl
done

# Check if the current directory gives any clue to the context
pushd "$(pwd)" >/dev/null

if [[ (-f "segment.json") ]]; then
    # segment directory
    export LOCATION="${LOCATION:-segment}"
    export SEGMENT_DIR="$(pwd)"
    export SEGMENT="$(fileName "$(pwd)")"

    addToArrayHead "BLUEPRINT_ARRAY" \
        "${SEGMENT_DIR}"/segment*.json \
        "${SEGMENT_DIR}"/solution*.json

    # Segment based composite fragments
    for COMPOSITE in "${TEMPLATE_COMPOSITES[@]}"; do
        addToArray "${COMPOSITE}_ARRAY" "${SEGMENT_DIR}"/"${COMPOSITE,,}"_*.ftl
    done

    cd ..

    # solutions directory
    # only add files if not already present
    export SOLUTIONS_DIR="$(pwd)"
    $(inArray "BLUEPRINT_ARRAY" "solution.json") ||
        addToArrayHead "BLUEPRINT_ARRAY" "${SOLUTIONS_DIR}"/solution*.json

    for COMPOSITE in "${TEMPLATE_COMPOSITES[@]}"; do
        for FRAGMENT in ${COMPOSITE,,}_*.ftl; do
            $(inArray "${COMPOSITE}_ARRAY" "${FRAGMENT}") ||
                addToArray "${COMPOSITE}_ARRAY" "${SOLUTIONS_DIR}/${FRAGMENT}"
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
fi

if [[ -f "product.json" ]]; then
    # product directory
    if [[ "${LOCATION}" == "account" ]]; then
        export LOCATION="account|product"
    else
        export LOCATION="${LOCATION:-product}"
    fi
    export PRODUCT_DIR="$(pwd)"
    if [[ $(fileName "${PRODUCT_DIR}") == "config" ]]; then
        export PRODUCT="$(cd ..; fileName "$(pwd)")"
    else
        export PRODUCT="$(fileName "$(pwd)")"
    fi

    addToArrayHead "BLUEPRINT_ARRAY" \
        "${PRODUCT_DIR}"/domains*.json \
        "${PRODUCT_DIR}"/ipaddressgroups*.json \
        "${PRODUCT_DIR}"/countrygroups*.json \
        "${PRODUCT_DIR}"/product.json
fi

if [[ -f "integrator.json" ]]; then
    export LOCATION="${LOCATION:-integrator}"
    export INTEGRATOR="$(fileName "$(pwd)")"
fi

if [[ (-f "root.json") ||
        ((-d config) && (-d infrastructure)) ]]; then
    export LOCATION="${LOCATION:-root}"
fi

cd "${GENERATION_DATA_DIR}"
[[ -z "${ACCOUNT}" ]] && export ACCOUNT="$(fileName "${GENERATION_DATA_DIR}")"

# Back to where we started
popd >/dev/null

# Analyse directory structure
findGen3Dirs "${GENERATION_DATA_DIR}" || exit

addToArrayHead "BLUEPRINT_ARRAY" \
    "${ACCOUNT_DIR}"/domains*.json \
    "${ACCOUNT_DIR}"/ipaddressgroups*.json \
    "${ACCOUNT_DIR}"/countrygroups*.json \
    "${ACCOUNT_DIR}"/account.json \
    "${TENANT_DIR}"/domains*.json \
    "${TENANT_DIR}"/ipaddressgroups*.json \
    "${TENANT_DIR}"/countrygroups*.json \
    "${TENANT_DIR}"/tenant.json

# Build the composite solution ( aka blueprint)
debug "BLUEPRINT=${BLUEPRINT_ARRAY[*]}"
export COMPOSITE_BLUEPRINT="${ROOT_DIR}/composite_blueprint.json"
if [[ ! $(arrayIsEmpty "BLUEPRINT_ARRAY") ]]; then
    addToArrayHead "BLUEPRINT_ARRAY" "${GENERATION_MASTER_DATA_DIR:-${GENERATION_DIR}/data}"/masterData.json
    ${GENERATION_DIR}/manageJSON.sh -d -o "${COMPOSITE_BLUEPRINT}" "${BLUEPRINT_ARRAY[@]}"
else
    echo "{}" > ${COMPOSITE_BLUEPRINT}
fi

# Extract key settings from the composite solution
# Ignore values generated by addition of default Id/Name attribute values
export TID=${TID:-$(runJQ -r '.Tenant.Id | select(.!="Tenant") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export TENANT=${TENANT:-$(runJQ -r '.Tenant.Name | select(.!="Tenant") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export AID=${AID:-$(runJQ -r '.Account.Id | select(.!="Account") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export AWSID=${AWSID:-$(runJQ -r '.Account.AWSId | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export ACCOUNT_REGION=${ACCOUNT_REGION:-$(runJQ -r '.Account.Region | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export PID=${PID:-$(runJQ -r '.Product.Id | select(.!="Product") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export PRODUCT_REGION=${PRODUCT_REGION:-$(runJQ -r '.Product.Region | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export SID=${SID:-$(runJQ -r '.Segment.Id | select(.!="Segment") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}
export REGION="${REGION:-$PRODUCT_REGION}"

# Perform a few consistency checks
[[ -z "${REGION}" ]] && fatalCantProceed "The region must be defined in the Product blueprint section." && exit 1

BLUEPRINT_ACCOUNT=$(runJQ -r '.Account.Name | select(.!=null)' < ${COMPOSITE_BLUEPRINT})
BLUEPRINT_PRODUCT=$(runJQ -r '.Product.Name | select(.!=null)' < ${COMPOSITE_BLUEPRINT})
BLUEPRINT_SEGMENT=$(runJQ -r '.Segment.Name | select(.!=null)' < ${COMPOSITE_BLUEPRINT})
[[ (-n "${ACCOUNT}") &&
    ("${BLUEPRINT_ACCOUNT}" != "Account") &&
    ("${ACCOUNT}" != "${BLUEPRINT_ACCOUNT}") ]] &&
        fatalCantProceed "Blueprint account of ${BLUEPRINT_ACCOUNT} doesn't match expected value of ${ACCOUNT}" && exit 1

[[ (-n "${PRODUCT}") &&
    ("${BLUEPRINT_PRODUCT}" != "Product") &&
    ("${PRODUCT}" != "${BLUEPRINT_PRODUCT}") ]] &&
        fatalCantProceed "Blueprint product of ${BLUEPRINT_PRODUCT} doesn't match expected value of ${PRODUCT}" && exit 1

[[ (-n "${SEGMENT}") &&
    ("${BLUEPRINT_SEGMENT}" != "Segment") &&
    ("${SEGMENT}" != "${BLUEPRINT_SEGMENT}") ]] &&
        fatalCantProceed "Blueprint segment of ${BLUEPRINT_SEGMENT} doesn't match expected value of ${SEGMENT}" && exit 1

# Add default composite fragments including end fragment
for COMPOSITE in "${TEMPLATE_COMPOSITES[@]}"; do
    for FRAGMENT in ${GENERATION_DIR}/templates/${COMPOSITE,,}/${COMPOSITE,,}_*.ftl; do
            $(inArray "${COMPOSITE}_ARRAY" $(fileName "${FRAGMENT}")) ||
                addToArray "${COMPOSITE}_ARRAY" "${FRAGMENT}"
    done
    for FRAGMENT in ${GENERATION_DIR}/templates/${COMPOSITE,,}/*end.ftl; do
        addToArray "${COMPOSITE}_ARRAY" "${FRAGMENT}"
    done
done

# create the template composites
for COMPOSITE in "${TEMPLATE_COMPOSITES[@]}"; do
    COMPOSITE_FILE="${ROOT_DIR}/composite_${COMPOSITE,,}.ftl"
    namedef_supported &&
      declare -n COMPOSITE_ARRAY="${COMPOSITE}_ARRAY" ||
      eval "declare COMPOSITE_ARRAY=(\"\${${COMPOSITE}_ARRAY[@]}\")"
    declare -gx COMPOSITE_${COMPOSITE}="${COMPOSITE_FILE}"
    debug "${COMPOSITE}=${COMPOSITE_ARRAY[*]}"
    cat "${COMPOSITE_ARRAY[@]}" > "${COMPOSITE_FILE}"
done

# Assemble appsettings
export COMPOSITE_SETTINGS="${ROOT_DIR}/composite_settings.json"
assemble_settings "${COMPOSITE_SETTINGS}"

# Product specific context if the product is known
APPSETTINGS_ARRAY=()
CREDENTIALS_ARRAY=()
if [[ -n "${PRODUCT}" ]]; then

    # deployment unit specific appsettings
    if [[ (-n "${DEPLOYMENT_UNIT}") ]]; then
        # Confirm it is an solution or application level deployment unit before checking appsettings
        if isValidUnit "application" "${DEPLOYMENT_UNIT}" || isValidUnit "solution" "${DEPLOYMENT_UNIT}"; then
            export BUILD_DEPLOYMENT_UNIT="${DEPLOYMENT_UNIT}"

            # Legacy naming to support products using the term "slice" or "unit" instead of "deployment_unit"
            fileContentsInEnv "BUILD_DEPLOYMENT_UNIT" \
                "${SEGMENT_APPSETTINGS_DIR}/${DEPLOYMENT_UNIT}"/deployment_unit*.ref \
                "${SEGMENT_APPSETTINGS_DIR}/${DEPLOYMENT_UNIT}"/unit*.ref \
                "${SEGMENT_APPSETTINGS_DIR}/${DEPLOYMENT_UNIT}"/slice*.ref

            addToArrayHead "APPSETTINGS_ARRAY" "${SEGMENT_APPSETTINGS_DIR}/${DEPLOYMENT_UNIT}"/appsettings*.json
            [[ "${DEPLOYMENT_UNIT}" != "${BUILD_DEPLOYMENT_UNIT}" ]] &&
                addToArrayHead "APPSETTINGS_ARRAY" "${SEGMENT_APPSETTINGS_DIR}/${BUILD_DEPLOYMENT_UNIT}"/appsettings*.json

            addToArrayHead "CREDENTIALS_ARRAY" "${SEGMENT_CREDENTIALS_DIR}/${DEPLOYMENT_UNIT}"/credentials*.json
            [[ "${DEPLOYMENT_UNIT}" != "${BUILD_DEPLOYMENT_UNIT}" ]] &&
                addToArrayHead "CREDENTIALS_ARRAY"  "${SEGMENT_CREDENTIALS_DIR}/${BUILD_DEPLOYMENT_UNIT}"/credentials*.json

            fileContentsInEnv "BUILD_REFERENCE" \
                "${SEGMENT_APPSETTINGS_DIR}/${BUILD_DEPLOYMENT_UNIT}"/build*.json \
                "${SEGMENT_APPSETTINGS_DIR}/${BUILD_DEPLOYMENT_UNIT}"/build*.ref
        fi
    fi

    # segment/product/account specific appsettings/credentials
    addToArrayHead "APPSETTINGS_ARRAY" \
        "${SEGMENT_APPSETTINGS_DIR}"/appsettings*.json \
        "${PRODUCT_APPSETTINGS_DIR}"/appsettings*.json \
        "${ACCOUNT_APPSETTINGS_DIR}"/appsettings*.json

    addToArrayHead "CREDENTIALS_ARRAY" \
        "${SEGMENT_CREDENTIALS_DIR}"/credentials*.json \
        "${PRODUCT_CREDENTIALS_DIR}"/credentials*.json \
        "${ACCOUNT_CREDENTIALS_DIR}"/credentials*.json
fi

# Build the composite appsettings
debug "APPSETTINGS=${APPSETTINGS_ARRAY[*]}"
export COMPOSITE_APPSETTINGS="${ROOT_DIR}/composite_appsettings.json"
$(arrayIsEmpty "APPSETTINGS_ARRAY") &&
    echo "{}" > ${COMPOSITE_APPSETTINGS} ||
    ${GENERATION_DIR}/manageJSON.sh -c -o ${COMPOSITE_APPSETTINGS} "${APPSETTINGS_ARRAY[@]}"

# Build the composite credentials
debug "CREDENTIALS=${CREDENTIALS_ARRAY[*]}"
export COMPOSITE_CREDENTIALS="${ROOT_DIR}/composite_credentials.json"
$(arrayIsEmpty "CREDENTIALS_ARRAY") &&
    echo "{\"Credentials\" : {}}" > ${COMPOSITE_CREDENTIALS} ||
    ${GENERATION_DIR}/manageJSON.sh -o ${COMPOSITE_CREDENTIALS} "${CREDENTIALS_ARRAY[@]}"

# Create the composite stack outputs
assemble_composite_stack_outputs

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
        aws configure list --profile "${ACCOUNT}" > $(getTempFile "account_profile_status_XXX.txt") 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${ACCOUNT}"
        fi
    fi
    if [[ -n "${AID}" ]]; then
        aws configure list --profile "${AID}" > $(getTempFile "id_profile_status_XXX.txt") 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${AID}"
        fi
    fi
    if [[ -n "${AWSID}" ]]; then
        aws configure list --profile "${AWSID}" > $(getTempFile "awsid_profile_status_XXX.txt") 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${AWSID}"
        fi
    fi
fi

# Handle some MINGW peculiarities
uname | grep -iq "MINGW64" && export MINGW64="true"

debug "--- finished setContext.sh ---\n"
