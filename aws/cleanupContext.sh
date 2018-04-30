#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}

# Context cleanup is only done from the script that set the context
[[ -z "${GENERATION_CONTEXT_DEFINED_LOCAL}" ]] && return 0

if [[ -z "${GENERATION_DEBUG}" ]]; then
  [[ -n "${GENERATION_TMPDIR}" ]] && rm -rf "${GENERATION_TMPDIR}"
fi

return 0
