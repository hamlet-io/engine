#!/usr/bin/env bash

# Based on current directory location and existing environment,
# define additional environment variables to facilitate automation
#
# Key variables are
# AGGREGATOR
# INTEGRATOR
# TENANT
# PRODUCT
# ENVIRONMENT
# SEGMENT
# ACCOUNT
#
# This script is designed to be sourced into other scripts

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# If the context has already been determined, there is nothing to do
if [[ -n "${GENERATION_CONTEXT_DEFINED}" ]]; then return 0; fi

export GENERATION_CONTEXT_DEFINED="true"
GENERATION_CONTEXT_DEFINED_LOCAL="true"

debug "--- starting setContext.sh ---\n"

# Create a temporary directory for this run
if [[ -z "${GENERATION_TMPDIR}" ]]; then
  pushTempDir "cot_XXXXXX"
  export GENERATION_TMPDIR="$( getTopTempDir )"
fi
debug "TMPDIR=${GENERATION_TMPDIR}"

# If no files match a glob, return nothing
# Much of the logic in this script relies on this setting
shopt -s nullglob

# Check the root of the context tree can be located
export GENERATION_DATA_DIR=$(findGen3RootDir "${ROOT_DIR:-$(pwd)}") ||
  { fatal "Can't locate the root of the directory tree."; exit 1; }

# Check the cmdb doesn't need upgrading
if [[ "${GENERATION_NO_CMDB_CHECK}" != "true" ]]; then
    debug "Checking if cmdb upgrade needed ..."
    upgrade_cmdb "${GENERATION_DATA_DIR}" ||
        { fatal "CMDB upgrade failed."; exit 1; }
    cleanup_cmdb "${GENERATION_DATA_DIR}" ||
        { fatal "CMDB cleanup failed."; exit 1; }
fi

# Ensure the cache directory exists
export CACHE_DIR="${GENERATION_DATA_DIR}/cache"
mkdir -p "${CACHE_DIR}"

# Generate the list of files constituting the composites based on the contents
# of the account and product trees
# The blueprint is handled specially as its logic is different to the others
TEMPLATE_COMPOSITES=(
    "account" "product" "segment" "solution" "application" \
    "policy" "fragment" "id" "name" "resource")
for composite in "${TEMPLATE_COMPOSITES[@]}"; do
    # Define the composite
    declare -gx COMPOSITE_${composite^^}="${CACHE_DIR}/composite_${composite}.ftl"

    if [[ (("${GENERATION_USE_CACHE}" != "true")  &&
            ("${GENERATION_USE_FRAGMENTS_CACHE}" != "true")) ||
          (! -f "${CACHE_DIR}/composite_account.ftl") ]]; then
        # define the array holding the list of composite fragment filenames
        declare -ga "${composite}_array"

        # Check for composite start fragment
        addToArray "${composite}_array" "${GENERATION_DIR}"/templates/"${composite}"/start*.ftl

        # If no composite specific start fragment, use a generic one
        $(inArray "${composite}_array" "start.ftl") ||
            addToArray "${composite}_array" "${GENERATION_DIR}"/templates/start.ftl
    fi
done

# Check if the current directory gives any clue to the context
pushd "$(pwd)" >/dev/null

if [[ (-f "segment.json") ]]; then
    export LOCATION="${LOCATION:-segment}"
    export SEGMENT="$(fileName "$(pwd)")"
    if [[ -f "../environment.json" ]]; then
      cd ..
    else
        export ENVIRONMENT="${SEGMENT}"
        export SEGMENT="default"
        cd ../..
    fi
fi

if [[ (-f "environment.json") ]]; then
    export LOCATION="${LOCATION:-environment}"
    export ENVIRONMENT="$(fileName "$(pwd)")"

    cd ../..
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
    export PRODUCT="$(fileName "$(pwd)")"
    [[ "${PRODUCT}" == "config" ]] &&
      export PRODUCT="$(cd ..; fileName "$(pwd)")"
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

# Build the composite solution ( aka blueprint)
blueprint_alternate_dirs=( \
  "${SEGMENT_SOLUTIONS_DIR}" \
  "${ENVIRONMENT_SHARED_SOLUTIONS_DIR}" \
  "${SEGMENT_SHARED_SOLUTIONS_DIR}" \
  "${PRODUCT_SHARED_SOLUTIONS_DIR}" )

export COMPOSITE_BLUEPRINT="${CACHE_DIR}/composite_blueprint.json"
if [[ (("${GENERATION_USE_CACHE}" != "true") &&
        ("${GENERATION_USE_BLUEPRINT_CACHE}" != "true")) ||
      (! -f "${COMPOSITE_BLUEPRINT}") ]]; then

    blueprint_array=()

    for blueprint_alternate_dir in "${blueprint_alternate_dirs[@]}"; do
      [[ (-z "${blueprint_alternate_dir}") || (! -d "${blueprint_alternate_dir}") ]] && continue

      addToArrayHead "blueprint_array" \
          "${blueprint_alternate_dir}"/segment*.json \
          "${blueprint_alternate_dir}"/environment*.json \
          "${blueprint_alternate_dir}"/solution*.json \
          "${blueprint_alternate_dir}"/domains*.json \
          "${blueprint_alternate_dir}"/ipaddressgroups*.json \
          "${blueprint_alternate_dir}"/countrygroups*.json
    done

    [[ -n "${PRODUCT_DIR}" ]] && addToArrayHead "blueprint_array" \
        "${PRODUCT_DIR}"/domains*.json \
        "${PRODUCT_DIR}"/ipaddressgroups*.json \
        "${PRODUCT_DIR}"/countrygroups*.json \
        "${PRODUCT_DIR}"/product.json

    addToArrayHead "blueprint_array" \
        "${ACCOUNT_DIR}"/domains*.json \
        "${ACCOUNT_DIR}"/ipaddressgroups*.json \
        "${ACCOUNT_DIR}"/countrygroups*.json \
        "${ACCOUNT_DIR}"/account.json \
        "${TENANT_DIR}"/domains*.json \
        "${TENANT_DIR}"/ipaddressgroups*.json \
        "${TENANT_DIR}"/countrygroups*.json \
        "${TENANT_DIR}"/tenant.json

    debug "BLUEPRINT=${blueprint_array[*]}"
    if [[ ! $(arrayIsEmpty "blueprint_array") ]]; then
        addToArrayHead "blueprint_array" "${GENERATION_MASTER_DATA_DIR:-${GENERATION_DIR}/data}"/masterData.json
        ${GENERATION_DIR}/manageJSON.sh -d -o "${COMPOSITE_BLUEPRINT}" "${blueprint_array[@]}"
    else
        echo "{}" > "${COMPOSITE_BLUEPRINT}"
    fi
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
export DEPLOYMENTUNIT_REGION=${DEPLOYMENTUNIT_REGION:-$(runJQ --arg du ${DEPLOYMENT_UNIT} -r '.Product[$du].Region | select(.!=null)' <${COMPOSITE_BLUEPRINT} )}
export SID=${SID:-$(runJQ -r '.Segment.Id | select(.!="Segment") | select(.!=null)' < ${COMPOSITE_BLUEPRINT})}

export COMPONENT_REGION="${DEPLOYMENTUNIT_REGION:-$PRODUCT_REGION}"
export REGION="${REGION:-$COMPONENT_REGION}"

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
if [[ (("${GENERATION_USE_CACHE}" != "true")  &&
        ("${GENERATION_USE_FRAGMENTS_CACHE}" != "true")) ||
      (! -f "${CACHE_DIR}/composite_account.ftl") ]]; then
    for composite in "${TEMPLATE_COMPOSITES[@]}"; do
        for blueprint_alternate_dir in "${blueprint_alternate_dirs[@]}"; do
            [[ (-z "${blueprint_alternate_dir}") || (! -d "${blueprint_alternate_dir}") ]] && continue
            for fragment in "${blueprint_alternate_dir}"/${composite}_*.ftl; do
                fragment_name="$(fileName "${fragment}")"
                $(inArray "${composite}_array" "${fragment_name}") ||
                    addToArray "${composite}_array" "${fragment}"
            done
        done

        for fragment in ${GENERATION_DIR}/templates/${composite}/${composite}_*.ftl; do
                $(inArray "${composite}_array" $(fileName "${fragment}")) ||
                    addToArray "${composite}_array" "${fragment}"
        done
        for fragment in ${GENERATION_DIR}/templates/${composite}/*end.ftl; do
            addToArray "${composite}_array" "${fragment}"
        done
    done

    # create the template composites
    for composite in "${TEMPLATE_COMPOSITES[@]}"; do
        namedef_supported &&
          declare -n composite_array="${composite}_array" ||
          eval "declare composite_array=(\"\${${composite}_array[@]}\")"
        debug "${composite^^}=${composite_array[*]}"
        cat "${composite_array[@]}" > "${CACHE_DIR}/composite_${composite}.ftl"
    done
fi

# Assemble settings
export COMPOSITE_SETTINGS="${CACHE_DIR}/composite_settings.json"
if [[ (("${GENERATION_USE_CACHE}" != "true") &&
        ("${GENERATION_USE_SETTINGS_CACHE}" != "true")) ||
      (! -f "${COMPOSITE_SETTINGS}") ]]; then
    debug "Generating composite settings ..."
    assemble_settings "${GENERATION_DATA_DIR}" "${COMPOSITE_SETTINGS}"
fi

# Create the composite definitions
export COMPOSITE_DEFINITIONS="${CACHE_DIR}/composite_definitions.json"
if [[ (("${GENERATION_USE_CACHE}" != "true") &&
        ("${GENERATION_USE_DEFINITIONS_CACHE}" != "true")) ||
      (! -f "${COMPOSITE_DEFINITIONS}") ]]; then
    assemble_composite_definitions
fi

# Create the composite stack outputs
export COMPOSITE_STACK_OUTPUTS="${CACHE_DIR}/composite_stack_outputs.json"
if [[ (("${GENERATION_USE_CACHE}" != "true") &&
        ("${GENERATION_USE_STACK_OUTPUTS_CACHE}" != "true")) ||
      (! -f "${COMPOSITE_STACK_OUTPUTS}") ]]; then
    assemble_composite_stack_outputs
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
        aws configure list --profile "${ACCOUNT}" > $(getTempFile "account_profile_status_XXXXXX.txt") 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${ACCOUNT}"
        fi
    fi
    if [[ -n "${AID}" ]]; then
        aws configure list --profile "${AID}" > $(getTempFile "id_profile_status_XXXXXX.txt") 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${AID}"
        fi
    fi
    if [[ -n "${AWSID}" ]]; then
        aws configure list --profile "${AWSID}" > $(getTempFile "awsid_profile_status_XXXXXX.txt") 2>&1
        if [[ $? -eq 0 ]]; then
            export AWS_DEFAULT_PROFILE="${AWSID}"
        fi
    fi
fi

# Handle some MINGW peculiarities
uname | grep -iq "MINGW64" && export MINGW64="true"

debug "--- finished setContext.sh ---\n"
