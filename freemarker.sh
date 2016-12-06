#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

function usage() {
    echo -e "\nGenerate a document using the Freemarker template engine" 
    echo -e "\nUsage: $(basename $0) -t TEMPLATE -d TEMPLATEDIR -o OUTPUT (-v VARIABLE=VALUE)*"
    echo -e "\nwhere\n"
    echo -e "(m) -d TEMPLATEDIR is the directory containing the template"
    echo -e "    -h shows this text"
    echo -e "(m) -o OUTPUT is the path of the resulting document"
    echo -e "(o) -r VARIABLE=VALUE (o) defines a variable and corresponding value to be made available in the template"
    echo -e "(m) -t TEMPLATE is the filename of the Freemarker template to use"
    echo -e "(o) -v VARIABLE=VALUE (o) defines a variable and corresponding value to be made available in the template"
    echo -e "\nNOTES:\n"
    echo -e "1. If the value of a variable defines a path to an existing file, the contents of the file are provided to the engine"
    echo -e "2. Values that do not correspond to existing files are provided as is to the engine"
    echo -e "3. Values containing spaces need to be quoted to ensure they are passed in as a single argument"
    echo -e "4. -r and -v are equivalent except that -r will not check if the provided "
    echo -e "   is a valid filename"
    echo -e ""
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
            echo -e "\nInvalid option: -${OPTARG}"
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument"
            usage
            ;;
    esac
done

# Ensure mandatory arguments have been provided
if [[ -z "${TEMPLATE}" || 
      -z "${TEMPLATEDIR}" ||
      -z "${OUTPUT}" ]]; then
    echo -e "\nInsufficient arguments"
    usage
fi

if [[ "${#VARIABLES[@]}" -gt 0 ]]; then
  VARIABLES=("-v" "${VARIABLES[@]}")
fi

if [[ "${#RAW_VARIABLES[@]}" -gt 0 ]]; then
  RAW_VARIABLES=("-r" "${RAW_VARIABLES[@]}")
fi

java -jar "${GENERATION_DIR}/freemarker-wrapper-1.2.jar" -i $TEMPLATE -d $TEMPLATEDIR -o $OUTPUT "${VARIABLES[@]}" "${RAW_VARIABLES[@]}"
RESULT=$?

