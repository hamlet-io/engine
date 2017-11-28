#!/bin/bash

# Generation framework common definitions
#
# This script is designed to be sourced into other scripts

. ${GENERATION_DIR}/utility.sh
. ${GENERATION_DIR}/contextTree.sh

function getLogLevel() {
  echo -n "${GENERATION_LOG_LEVEL}"
}

# Override default implementation
function getTempRootDir() {
  echo -n "${GENERATION_TMPDIR}"
}

function buildAppSettings () {
    local ROOT_DIR="${1}"; shift
    local FILE_PATTERN="${1}"; shift
    local ANCESTORS=("$@")
    
    local NULLGLOB=$(shopt -p nullglob)
    shopt -s nullglob
    
    for FILE in "${ROOT_DIR}"/${FILE_PATTERN}; do
        echo Processing ${FILE} to "$(filePath "${FILE}")/temp_$(fileName "${FILE}")"
        addJSONAncestorObjects "${FILE}" "${PARENTS[@]}" > "$(filePath "${FILE}")/temp_$(fileName "${FILE}")"
    done

    ${NULLGLOB}

    local CHILDREN=($(find "${ROOT_DIR}" -maxdepth 1 -type d ! -path "${ROOT_DIR}"))
#    echo CHILDREN="${CHILDREN[@]}"
    for CHILD in "${CHILDREN[@]}"; do
        addJSONParentDirs "${CHILD}" "${FILE_PATTERN}" "${PARENTS[@]}" "$(fileName "${CHILD}")"
    done
    
}

