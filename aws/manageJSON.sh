#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap 'exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

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

# Parse options
while getopts ":cdf:ho:" opt; do
  case $opt in
    c)
      JSON_FORMAT="-c"
      ;;
    d)
      JSON_ADD_DEFAULTS="true"
      ;;
    f)
      JSON_FILTER="${OPTARG}"
      ;;
    h)
      usage
      ;;
    o)
      JSON_OUTPUT="${OPTARG}"
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

# Set defaults
JSON_FORMAT="${JSON_FORMAT:-$JSON_FORMAT_DEFAULT}"

# Determine the file list
shift $((OPTIND-1))
JSON_ARRAY=(${JSON_LIST})
JSON_ARRAY+=("$@")

# Ensure mandatory arguments have been provided
if [[ (-z "${JSON_OUTPUT}") || ("${#JSON_ARRAY[@]}" -eq 0) ]]; then
  echo -e "\nInsufficient arguments" >&2
  exit
fi

# Temporary hack to get around segmentation fault
# Hopefully fixed in next official release after 1.5
JSON_ARRAY_SHORT=()
JSON_INDEX=0
for F in "${JSON_ARRAY[@]}"; do
    TEMP="./temp_${JSON_INDEX}.json"
    cp $F "${TEMP}"
    JSON_ARRAY_SHORT+=("$TEMP")
    JSON_INDEX=$(( $JSON_INDEX + 1 ))
done


# Merge the files
if [[ -z "${JSON_FILTER}" ]]; then
    FILTER_INDEX=0
    JSON_FILTER=".[${FILTER_INDEX}]"
    for F in "${JSON_ARRAY[@]}"; do
        if [[ "${FILTER_INDEX}" > 0 ]]; then
            JSON_FILTER="${JSON_FILTER} * .[$FILTER_INDEX]"
        fi
        FILTER_INDEX=$(( $FILTER_INDEX + 1 ))
    done
fi
if [[ "${JSON_ADD_DEFAULTS}" == "true" ]]; then
    jq ${JSON_FORMAT} -s "${JSON_FILTER}" "${JSON_ARRAY_SHORT[@]}" | jq -f ${GENERATION_DIR}/addDefaults.jq > ${JSON_OUTPUT}
else
    jq ${JSON_FORMAT} -s "${JSON_FILTER}" "${JSON_ARRAY_SHORT[@]}" > ${JSON_OUTPUT}
fi
RESULT=$?
if [[ "${RESULT}" -eq 0 ]]; then dos2unix "${JSON_OUTPUT}" 2> /dev/null; fi
if [[ ! -n "${GENERATION_DEBUG}" ]]; then rm -f "${JSON_ARRAY_SHORT[@]}"; fi
#