#!/usr/bin/env bash

echo "###############################################"
echo "# Running template tests for the AWS provider #"
echo "###############################################"

TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-"./cot_tests"}"

if [[ -d "${TEST_OUTPUT_DIR}" ]]; then
    rm -r "${TEST_OUTPUT_DIR}"
    mrkdir "${TEST_OUTPUT_DIR}"
else
    mkdir -p "${TEST_OUTPUT_DIR}"
fi

echo "Output Dir: ${TEST_OUTPUT_DIR}"
echo "Generating unit list..."
${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${TEST_OUTPUT_DIR}" -l unitlist
UNIT_LIST="$(jq -r '.DeploymentUnits | join(" ")' < "${TEST_OUTPUT_DIR}/unitlistconfig.json")"

for unit in $UNIT_LIST; do
    echo "Creating templates for $unit ..."
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${TEST_OUTPUT_DIR}" -l segment -u $unit > /dev/null 2>&1 || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${TEST_OUTPUT_DIR}" -l solution -u $unit > /dev/null 2>&1 || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o "${TEST_OUTPUT_DIR}" -l application -u $unit > /dev/null 2>&1 || true
done

cot test generate --directory "${TEST_OUTPUT_DIR}" -o "${TEST_OUTPUT_DIR}/test_templates.py"

cd "${TEST_OUTPUT_DIR}"
echo "Running Tests..."
cot test run -t "./test_templates.py"
