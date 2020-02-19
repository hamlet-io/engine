#!/usr/bin/env bash

echo "###############################################"
echo "# Running template tests for the AWS provider #"
echo "###############################################"

OUTPUT_DIR="${OUTPUT_DIR:-"./cot_tests"}"

if [[ ! -d "${OUTPUT_DIR}" ]]; then
    mkdir -p "${OUTPUT_DIR}"
fi

echo "Output Dir: ${OUTPUT_DIR}"
echo "Generating unit list..."
${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${OUTPUT_DIR}" -l unitlist > /dev/null 2>&1
UNIT_LIST="$(jq -r '.DeploymentUnits | join(" ")' < "${OUTPUT_DIR}/unitlistconfig.json")"

for unit in $UNIT_LIST; do
    echo "Creating templates for $unit ..."
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${OUTPUT_DIR}" -l segment -u $unit > /dev/null 2>&1 || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${OUTPUT_DIR}" -l solution -u $unit > /dev/null 2>&1 || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${OUTPUT_DIR}" -l application -u $unit > /dev/null 2>&1 || true
done

cot test generate --directory "${OUTPUT_DIR}" -o "${OUTPUT_DIR}/test_templates.py"

cd "${OUTPUT_DIR}"
echo "Running Tests..."
cot test run -t "${OUTPUT_DIR}/test_templates.py"
