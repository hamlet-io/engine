#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults

function usage() {
    cat <<EOF

Generate a document using the Freemarker template engine

Usage: $(basename $0) -t TEMPLATE -d TEMPLATEDIR -o OUTPUT (-v VARIABLE=VALUE)*

where

(m) -d TEMPLATEDIR    is the directory containing the template
    -h                shows this text
(m) -o OUTPUT         is the path of the resulting document
(o) -r VARIABLE=VALUE defines a variable and corresponding value to be made available in the template
(m) -t TEMPLATE       is the filename of the Freemarker template to use
(o) -v VARIABLE=VALUE defines a variable and corresponding value to be made available in the template

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

NOTES:

1. If the value of a variable defines a path to an existing file, the contents of the file are provided to the engine
2. Values that do not correspond to existing files are provided as is to the engine
3. Values containing spaces need to be quoted to ensure they are passed in as a single argument
4. -r and -v are equivalent except that -r will not check if the provided value
   is a valid filename

EOF
    exit
}

TEMPLATEDIRS=()
RAW_VARIABLES=()
VARIABLES=()

# Parse options
while getopts ":d:ho:r:t:v:" opt; do
    case $opt in
        d)
            TEMPLATEDIRS+=("${OPTARG}")
            ;;
        h)
            usage
            ;;
        o)
            OUTPUT="${OPTARG}"
            ;;
        r)
            RAW_VARIABLES+=("${OPTARG}")
            ;;
        t)
            TEMPLATE="${OPTARG}"
            ;;
        v)
            VARIABLES+=("${OPTARG}")
            ;;
        \?)
            fatalOption
            ;;
        :)
            fatalOptionArgument
            ;;
    esac
done

# Ensure mandatory arguments have been provided
[[ (-z "${TEMPLATE}") ||
    ("${#TEMPLATEDIRS[@]}" -eq 0) ||
    (-z "${OUTPUT}") ]] && fatalMandatory && exit 1

if [[ "${#TEMPLATEDIRS[@]}" -gt 0 ]]; then
  TEMPLATEDIRS=("-d" "${TEMPLATEDIRS[@]}")
fi

if [[ "${#VARIABLES[@]}" -gt 0 ]]; then
  VARIABLES=("-v" "${VARIABLES[@]}")
fi

if [[ "${#RAW_VARIABLES[@]}" -gt 0 ]]; then
  RAW_VARIABLES=("-r" "${RAW_VARIABLES[@]}")
fi

java -jar "${GENERATION_DIR}/freemarker-wrapper-1.8.1.jar" -i $TEMPLATE "${TEMPLATEDIRS[@]}" -o $OUTPUT "${VARIABLES[@]}" "${RAW_VARIABLES[@]}"
RESULT=$?

