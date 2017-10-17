#!/bin/bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# Context cleanup is only done from the script that set the context
[[ -z "${GENERATION_CONTEXT_DEFINED_LOCAL}" ]] && return 0

[[ (-z "${GENERATION_DEBUG}") && (-n "${GENERATION_DATA_DIR}") ]] && cleanup "${GENERATION_DATA_DIR}"
return 0

