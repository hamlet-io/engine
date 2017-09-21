#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# Context cleanup is only done from the script that set the context
[[ -z "${GENERATION_CONTEXT_DEFINED_LOCAL}" ]] && return 0

if [[ (-z "${GENERATION_DEBUG}") && (-n "${GENERATION_DATA_DIR}") ]]; then
    find ${GENERATION_DATA_DIR} -name "composite_*" -delete
    find ${GENERATION_DATA_DIR} -name "STATUS.txt" -delete
    find ${GENERATION_DATA_DIR} -name "stripped_*" -delete
    find ${GENERATION_DATA_DIR} -name "ciphertext*" -delete
    find ${GENERATION_DATA_DIR} -name "temp_*" -type f -delete

    # Handle cleanup of temporary directories
    TEMP_DIRS=($(find ${GENERATION_DATA_DIR} -name "temp_*" -type d))
    for TEMP_DIR in "${TEMP_DIRS[@]}"; do
        # Subdir may already have been deleted by parent temporary directory
        if [[ -e "${TEMP_DIR}" ]]; then
            rm -rf "${TEMP_DIR}"
        fi
    done
fi

