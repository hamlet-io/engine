#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap '. ${GENERATION_DIR}/cleanupContext.sh' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
REFERENCE_OUTPUT_DIR_DEFAULT="${GENERATION_BASE_DIR}/dist/reference/"

# Create a dir for some temporary files
dockerstagedir="$(getTempDir "cota_docker_XXXXXX" "${DOCKER_STAGE_DIR}")"
chmod a+rwx "${dockerstagedir}"

function usage() {
  cat <<EOF

Create a Codeontap Component Reference

Usage: $(basename $0) -l REFERENCE_TYPE -o OUTPUT_FILE

where

(m) -t REFERENCE_TYPE           is the type of object you need the reference for
(o) -o REFERENCE_OUTPUT_DIR     is the output directory
(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

REFERENCE_OUTPUT_DIR              = "${REFERENCE_OUTPUT_DIR_DEFAULT}"

NOTES:


EOF
}

function options() {

  # Parse options
  while getopts ":o:t:" option; do
      case "${option}" in
          t) REFERENCE_TYPE="${OPTARG}" ;;
          o) REFERENCE_OUTPUT_DIR="${OPTARG}" ;;
          \?) fatalOption; return 1 ;;
          :) fatalOptionArgument; return 1 ;;
      esac
  done

  # Defaults
  REFERENCE_OUTPUT_DIR="${REFERENCE_OUTPUT_DIR:-${REFERENCE_OUTPUT_DIR_DEFAULT}}"

  return 0
}

function process_template() {
  local type="${1,,}"; shift
  local output_dir="${1,,}"; shift

  # Generate the list of files constituting the composites based on the contents
  # of the account and product trees
  # The blueprint is handled specially as its logic is different to the others

  local GENERATION_DATA_DIR="${GENERATION_BASE_DIR}/build/"
  local CACHE_DIR="${GENERATION_BASE_DIR}/cache"
  mkdir -p "${CACHE_DIR}"

  export COMPOSITE_BLUEPRINT="${CACHE_DIR}/composite_blueprint.json"
  debug "BLUEPRINT=${blueprint_array[*]}"
  if [[ ! $(arrayIsEmpty "blueprint_array") ]]; then
      addToArrayHead "blueprint_array" "${GENERATION_MASTER_DATA_DIR:-${GENERATION_DIR}/data}"/masterData.json
      ${GENERATION_DIR}/manageJSON.sh -d -o "${COMPOSITE_BLUEPRINT}" "${blueprint_array[@]}"
  else
      echo "{}" > "${COMPOSITE_BLUEPRINT}"
  fi

  TEMPLATE_COMPOSITES=( "id" "name" "policy" "resource" )
  for composite in "${TEMPLATE_COMPOSITES[@]}"; do
      # Define the composite
      declare -gx COMPOSITE_${composite^^}="${CACHE_DIR}/composite_${composite}.ftl"

      if [[ (("${GENERATION_USE_CACHE}" != "true")  &&
              ("${GENERATION_USE_FRAGMENTS_CACHE}" != "true")) ||
            (! -f "${CACHE_DIR}/composite_id.ftl") ]]; then
          # define the array holding the list of composite fragment filenames
          declare -ga "${composite}_array"

          # Check for composite start fragment
          addToArray "${composite}_array" "${GENERATION_DIR}"/templates/"${composite}"/start*.ftl

          # If no composite specific start fragment, use a generic one
          $(inArray "${composite}_array" "start.ftl") ||
              addToArray "${composite}_array" "${GENERATION_DIR}"/templates/start.ftl
      fi
  done

  # Add default composite fragments including end fragment
  if [[ (("${GENERATION_USE_CACHE}" != "true")  &&
          ("${GENERATION_USE_FRAGMENTS_CACHE}" != "true")) ||
        (! -f "${CACHE_DIR}/composite_id.ftl") ]]; then

      for composite in "${TEMPLATE_COMPOSITES[@]}"; do
          for fragment in ${GENERATION_DIR}/templates/${composite}/${composite}_*.ftl; do
                  $(inArray "${composite}_array" $(fileName "${fragment}")) ||
                      addToArray "${composite}_array" "${fragment}"
          done
          for fragment in ${GENERATION_DIR}/templates/${composite}/*end.ftl; do
              addToArray "${composite}_array" "${fragment}"
          done
      done

      info "Composite Array = ${id_array}"


      # create the template composites
      for composite in "${TEMPLATE_COMPOSITES[@]}"; do

        info "Cache DIR ${CACHE_DIR}"

          namedef_supported &&
            declare -n composite_array="${composite}_array" ||
            eval "declare composite_array=(\"\${${composite}_array[@]}\")"
          debug "${composite^^}=${composite_array[*]}"
          cat "${composite_array[@]}" > "${CACHE_DIR}/composite_${composite}.ftl"

      done
  fi

  # Filename parts
  local type_prefix="${type}-"

  # Set up the level specific template information
  local template_dir="${GENERATION_DIR}/templates"
  local template="create${type^}Reference.ftl"
  [[ ! -f "${template_dir}/${template}" ]] && template="create${type^}.ftl"
  local template_composites=("POLICY" "ID" "NAME" "RESOURCE")

  case "${type}" in
    component)
      cf_dir="${PRODUCT_INFRASTRUCTURE_DIR}/cot/${ENVIRONMENT}/${SEGMENT}"
      passes=("reference")

      pass_level_prefix["reference"]="component-reference"
      pass_description["reference"]="component-reference"
      pass_suffix["reference"]=".md"
      ;;

    *)
      fatalCantProceed "\"${LEVEL}\" is not one of the known stack levels."
      ;;
  esac

  # Include the template composites
  # Removal of drive letter (/?/) is specifically for MINGW
  # It shouldn't affect other platforms as it won't be matched
  for composite in "${template_composites[@]}"; do
    composite_var="COMPOSITE_${composite^^}"
    args+=("-r" "${composite,,}List=${!composite_var#/?/}")
    info "${composite_var}"
  done

  args+=("-v" "blueprint=${COMPOSITE_BLUEPRINT}")
  args+=("-v" "settings={}")
  args+=("-v" "region=ap-southeast-2")

  # Directory for temporary files
  pushTempDir "create_template_XXXXXX"
  local tmp_dir="$(getTopTempDir)"

  # Perform each pass
  for pass in "${passes[@]}"; do

    local output_prefix="${pass_level_prefix[${pass}]}"

    # Determine output file
    info "Generating ${type} reference file ...\n"

    local output_file="${output_dir}/${output_prefix}${pass_suffix[${pass}]}"
    local template_result_filename="${output_prefix}${pass_alternative_prefix}${pass_suffix[${pass}]}"
    local template_result_file="${tmp_dir}/${template_result_filename}"

    pass_args=("${args[@]}")

    ${GENERATION_DIR}/freemarker.sh \
      -d "${template_dir}" -t "${template}" -o "${template_result_file}" "${pass_args[@]}" || return $?
    
    # Ignore whitespace only files
    if [[ $(tr -d " \t\n\r\f" < "${template_result_file}" | wc -m) -eq 0 ]]; then
      info "Ignoring empty ${file_description} file ...\n"

      # Remove any previous version
      [[ -f "${output_file}" ]] && rm "${output_file}"

      continue
    fi

    # Check for exception strings in the output
    grep "COTException:" < "${template_result_file}" > "${template_result_file}-exceptionstrings"
    if [[ -s "${template_result_file}-exceptionstrings"  ]]; then
      fatal "Exceptions occurred during template generation. Details follow...\n"
      case "$(fileExtension "${template_result_file}")" in
        json)
          jq --indent 2 '.' < "${template_result_file}-exceptionstrings" >&2
          ;;
        *)
          cat "${template_result_file}-exceptionstrings" >&2
          ;;
      esac
      return 1
    fi

    case "$(fileExtension "${template_result_file}")" in
      md)
        info "${output_file}"
        if [[ ! -d "${output_dir}" ]]; then
          mkdir -p "${output_dir}"
        fi
    
        mkdir -p "${dockerstagedir}/in/"
        mkdir -p "${dockerstagedir}/out/"

        cp "${template_result_file}" "${dockerstagedir}/in/${template_result_filename}"

        docker run --rm \
          -v "${dockerstagedir}/in:/app/indir" \
          -v "${dockerstagedir}/out:/app/outdir" \
          codeontap/utilities \
            remark "/app/indir/${template_result_filename}" -o "/app/outdir/${template_result_filename}" 

        if [[ -f "${dockerstagedir}/out/${template_result_filename}" ]]; then 
          cp "${dockerstagedir}/out/${template_result_filename}" "${output_file}"
        else 
          fatal "Could not find result file"
          return 1
        fi

        ;;
    esac
  done

  return 0
}

function main() {

  options "$@" || return $?

  pushTempDir "create_template_XXXXXX"
  tmp_dir="$(getTopTempDir)"
  
  info "Starting work on ${REFERENCE_TYPE} Reference"

  process_template \
    "${REFERENCE_TYPE}" \
    "${REFERENCE_OUTPUT_DIR}"
}

main "$@"
