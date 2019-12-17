#!/usr/bin/env bash

[[ -n "${GENERATION_DEBUG}" ]] && set ${GENERATION_DEBUG}
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM
. "${GENERATION_DIR}/common.sh"

# Defaults
JSON_FORMAT_DEFAULT="--indent 4"

function usage() {
    cat <<EOF

Manage JSON files

Usage: $(basename $0) -f JSON_FILTER -o JSON_OUTPUT -c -d JSON_LIST

where

(o) -c              compact rather than pretty output formatting
(o) -d              to default missing attributes
(o) -f JSON_FILTER  is the filter to use
    -h              shows this text
(m) -o JSON_OUTPUT  is the desired output file

(m) mandatory, (o) optional, (d) deprecated

DEFAULTS:

JSON_FILTER = merge files
JSON_FORMAT="${JSON_FORMAT_DEFAULT}"

NOTES:

1. parameters can be provided in an environment variables of the same name
2. Any positional arguments will be appended to the existing value
   (if any) of JSON_LIST
3. If defaulting is turned on, Name attributes will be found where an Id
   attribute exists and no Name attribute exists

EOF
    exit
}


function options() {
    # Parse options
    while getopts ":cdf:hno:" opt; do
        case $opt in
            c)
                JSON_FORMAT="-c"
                ;;
            d)
                JSON_PREDEFINED_FILTER="add_defaults"
                ;;
            f)
                JSON_FILTER="${OPTARG}"
                ;;
            h)
                usage
                ;;
            n)
                JSON_PREDEFINED_FILTER="strip_null"
                ;;
            o)
                JSON_OUTPUT="${OPTARG}"
                ;;
            \?)
                fatalOption
                ;;
            :)
                fatalOptionArgument
                ;;
        esac
    done

    # Set defaults
    JSON_FORMAT="${JSON_FORMAT:-$JSON_FORMAT_DEFAULT}"
}

function main() {

    options "$@" || return $?

    # Determine the file list
    shift $((OPTIND-1))
    JSON_ARRAY=(${JSON_LIST})
    JSON_ARRAY+=("$@")

    # Ensure mandatory arguments have been provided
    [[ (-z "${JSON_OUTPUT}") ||
        ("${#JSON_ARRAY[@]}" -eq 0) ]] && fatalMandatory && exit 255

    # Merge the files
    if [[ -z "${JSON_FILTER}" ]]; then
        FILTER_INDEX=0
        JSON_FILTER=".[${FILTER_INDEX}]"
        for F in "${JSON_ARRAY[@]}"; do
            [[ "${FILTER_INDEX}" > 0 ]] && JSON_FILTER="${JSON_FILTER} * .[$FILTER_INDEX]"
            FILTER_INDEX=$(( $FILTER_INDEX + 1 ))
        done
    fi

    case "${JSON_PREDEFINED_FILTER}" in
        add_defaults )
            runJQ -s "${JSON_FILTER}" "${JSON_ARRAY[@]}" | \
                runJQ ${JSON_FORMAT} -f ${GENERATION_DIR}/addDefaults.jq > ${JSON_OUTPUT} || return $?
            ;;

        strip_null )
            runJQ -s "${JSON_FILTER}" "${JSON_ARRAY[@]}" | \
                runJQ -s -f ${GENERATION_DIR}/nullClean.jq > ${JSON_OUTPUT} || return $?
            ;;

        *)
            runJQ ${JSON_FORMAT} -s "${JSON_FILTER}" "${JSON_ARRAY[@]}" > ${JSON_OUTPUT} || return $?
            ;;
    esac

    dos2unix "${JSON_OUTPUT}" 2> /dev/null
    return $?
}

main "$@"
