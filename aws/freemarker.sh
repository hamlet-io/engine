#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

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

RAW_VARIABLES=()
VARIABLES=()

# Parse options
while getopts ":d:ho:r:t:v:" opt; do
    case $opt in
        d)
            TEMPLATEDIR="${OPTARG}"
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
            echo -e "\nInvalid option: -${OPTARG}" >&2
            exit
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument" >&2
            exit
            ;;
    esac
done

# Ensure mandatory arguments have been provided
if [[ -z "${TEMPLATE}" || 
      -z "${TEMPLATEDIR}" ||
      -z "${OUTPUT}" ]]; then
    echo -e "\nInsufficient arguments" >&2
    exit
fi

if [[ "${#VARIABLES[@]}" -gt 0 ]]; then
  VARIABLES=("-v" "${VARIABLES[@]}")
fi

if [[ "${#RAW_VARIABLES[@]}" -gt 0 ]]; then
  RAW_VARIABLES=("-r" "${RAW_VARIABLES[@]}")
fi

java -jar "${GENERATION_DIR}/freemarker-wrapper-1.2.jar" -i $TEMPLATE -d $TEMPLATEDIR -o $OUTPUT "${VARIABLES[@]}" "${RAW_VARIABLES[@]}"
RESULT=$?

