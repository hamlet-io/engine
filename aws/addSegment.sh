#!/bin/bash

if [[ -n "${GENERATION_DEBUG}" ]]; then set ${GENERATION_DEBUG}; fi
trap '. ${GENERATION_DIR}/cleanupContext.sh; exit ${RESULT:-1}' EXIT SIGHUP SIGINT SIGTERM

# Defaults

function usage() {
    cat <<-EOF
		Add a new segment
		Usage: $(basename $0) -l TITLE -n SEGMENT -d DESCRIPTION -s SID -e EID -o DOMAIN -r AWS_REGION -u
		where
		(o) -d DESCRIPTION is the segment description
		(o) -e EID is the ID of the environment of which this segment is part
		    -h shows this text
		(o) -l TITLE is the segment title
		(m) -n SEGMENT is the human readable form (one word, lowercase and no spaces) of the segment id
		(o) -o DOMAIN is the default DNS domain to be used for the segment
		(o) -r AWS_REGION is the default AWS region for the segment
		(o) -s SID is the segment id
		(o) -u if details should be updated
		DEFAULTS (creation only):
		EID=SID
		SID=EID
		TITLE from environment master data for EID
		NOTES:
		1. Subdirectories are created in the config and infrastructure subtrees
		2. The segment information is saved in the segment profile
		3. To update the details, the update option must be explicitly set
		4. The environment must exist in the masterData
		5. EID or SID are required if creating a segment
	EOF
    exit
}

# Parse options
while getopts ":d:e:hl:n:o:r:s:u" opt; do
    case $opt in
        d)
            DESCRIPTION="${OPTARG}"
            ;;
        e)
            EID="${OPTARG}"
            ;;
        h)
            usage
            ;;
        l)
            TITLE="${OPTARG}"
            ;;
        n)
            SEGMENT="${OPTARG}"
            ;;
        o)
            DOMAIN="${OPTARG}"
            ;;
        r)
            AWS_REGION="${OPTARG}"
            ;;
        s)
            SID="${OPTARG}"
            ;;
        u)
            UPDATE_SEGMENT="true"
            ;;
        \?)
            echo -e "\nInvalid option: -${OPTARG}" >&2
            usage
            ;;
        :)
            echo -e "\nOption -${OPTARG} requires an argument" >&2
            usage
            ;;
    esac
done

# Ensure mandatory arguments have been provided
if [[ (-z "${SEGMENT}") ]]; then
    echo -e "\nInsufficient arguments" >&2
    usage
fi

# Set up the context
. ${GENERATION_DIR}/setContext.sh

# Ensure we are in the root of the product tree
if [[ ! ("product" =~ ${LOCATION}) ]]; then
    echo -e "\nWe don't appear to be in the product directory. Are we in the right place?" >&2
    usage
fi

# Create the directories for the segment
SEGMENT_SOLUTIONS_DIR="${SOLUTIONS_DIR}/${SEGMENT}"
SEGMENT_APPSETTINGS_DIR="${APPSETTINGS_DIR}/${SEGMENT}"
SEGMENT_CREDENTIALS_DIR="${CREDENTIALS_DIR}/${SEGMENT}"
mkdir -p ${SEGMENT_SOLUTIONS_DIR}
if [[ ! -d ${SEGMENT_APPSETTINGS_DIR} ]]; then
    mkdir -p ${SEGMENT_APPSETTINGS_DIR}
    echo "{}" > ${SEGMENT_APPSETTINGS_DIR}/appsettings.json
fi
mkdir -p ${SEGMENT_CREDENTIALS_DIR}

# Check whether the segment profile is already in place
SEGMENT_PROFILE=${SEGMENT_SOLUTIONS_DIR}/segment.json
if [[ -f ${SEGMENT_PROFILE} ]]; then
    if [[ "${UPDATE_SEGMENT}" != "true" ]]; then
        echo -e "\nSegment profile already exists. Maybe try using update option?" >&2
        usage
    fi
else
    if [[ (-z "${EID}") && (-z "${SID}") ]]; then
        echo -e "\nOne of EID and SID required for segment creation" >&2
        usage
    fi
    echo "{\"Segment\":{}}" > ${SEGMENT_PROFILE}
    EID=${EID:-${SID}}
    SID=${SID:-${EID}}
    ENVIRONMENT_TITLE=$(cat ${COMPOSITE_BLUEPRINT} | jq -r ".Environments[\"${EID}\"].Title | select(.!=null)")
    if [[ -z "${ENVIRONMENT_TITLE}" ]]; then 
        echo -e "\nEnvironment not defined in masterData.json. Was SID or EID provided?" >&2
        usage
    fi
    TITLE=${TITLE:-$ENVIRONMENT_TITLE}
fi

# Generate the filter
CERTIFICATE_ID="${PRODUCT}-${SEGMENT}"
FILTER="."
if [[ -n "${SID}" ]]; then FILTER="${FILTER} | .Segment.Id=\$SID"; fi
if [[ -n "${SEGMENT}" ]]; then FILTER="${FILTER} | .Segment.Name=\$SEGMENT"; fi
if [[ -n "${TITLE}" ]]; then FILTER="${FILTER} | .Segment.Title=\$TITLE"; fi
if [[ -n "${DESCRIPTION}" ]]; then FILTER="${FILTER} | .Segment.Description=\$DESCRIPTION"; fi
if [[ -n "${EID}" ]]; then FILTER="${FILTER} | .Segment.Environment=\$EID"; fi
if [[ -n "${AWS_REGION}" ]]; then FILTER="${FILTER} | .Product.Region=\$AWS_REGION"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Stem=\$DOMAIN"; fi
if [[ -n "${DOMAIN}" ]]; then FILTER="${FILTER} | .Product.Domain.Certificate.Id=\$CERTIFICATE_ID"; fi

# Generate the segment profile
cat ${SEGMENT_PROFILE} | jq --indent 4 \
--arg SID "${SID}" \
--arg SEGMENT "${SEGMENT}" \
--arg TITLE "${TITLE}" \
--arg DESCRIPTION "${DESCRIPTION}" \
--arg EID "${EID}" \
--arg AWS_REGION "${AWS_REGION}" \
--arg DOMAIN "${DOMAIN}" \
--arg CERTIFICATE_ID "${CERTIFICATE_ID}" \
"${FILTER}" > ${SEGMENT_SOLUTIONS_DIR}/temp_segment.json
RESULT=$?

if [[ ${RESULT} -eq 0 ]]; then
    mv ${SEGMENT_SOLUTIONS_DIR}/temp_segment.json ${SEGMENT_SOLUTIONS_DIR}/segment.json
else
    echo -e "\nError creating segment profile" >&2
    exit
fi

# Provide an empty credentials profile for the segment
if [[ ! -f ${SEGMENT_CREDENTIALS_DIR}/credentials.json ]]; then
    echo "{\"Credentials\" : {}}" | jq --indent 4 '.' > ${SEGMENT_CREDENTIALS_DIR}/credentials.json
fi

# All good
RESULT=0


