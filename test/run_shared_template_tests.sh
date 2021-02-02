#!/usr/bin/env bash
set -euo pipefail

echo "###############################################"
echo "# Running template tests for the AWS provider #"
echo "###############################################"

DEFAULT_TEST_OUTPUT_DIR="$(pwd)/hamlet_tests"
TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-${DEFAULT_TEST_OUTPUT_DIR}}"

if [[ -d "${TEST_OUTPUT_DIR}" ]]; then
    rm -r "${TEST_OUTPUT_DIR}"
    mkdir "${TEST_OUTPUT_DIR}"
else
    mkdir -p "${TEST_OUTPUT_DIR}"
fi

echo " -Output Dir: ${TEST_OUTPUT_DIR}"
echo ""
echo "--- Generating Management Contract ---"
echo ""

default_args=(
    "-o ${TEST_OUTPUT_DIR}"
    '-x'
)

generation_args=(
    '-i mock'
    '-p shared'
    '-p sharedtest'
    '-f default'
)

hamlet entrance ${generation_args[@]} invoke-entrance -e unitlist ${default_args[@]}
UNIT_LIST=`jq -r '.Stages[].Steps[].Parameters | "-l \(.DeploymentGroup) -u \(.DeploymentUnit)"' < ${TEST_OUTPUT_DIR}/unitlist-managementcontract.json`
readarray -t UNIT_LIST <<< "${UNIT_LIST}"

for unit in "${UNIT_LIST[@]}";  do
    echo ""
    echo "--- Generating $unit ---"
    echo ""

    unit_args=("${default_args[@]}" "${unit}")

    hamlet entrance ${generation_args[@]} invoke-entrance -e deploymenttest ${unit_args[@]}
    hamlet entrance ${generation_args[@]} invoke-entrance -e deployment ${unit_args[@]}
done

echo ""
echo "--- Running Tests ---"
echo ""

hamlet test generate --directory "${TEST_OUTPUT_DIR}" -o "${TEST_OUTPUT_DIR}/test_templates.py"

pushd $(pwd)
cd "${TEST_OUTPUT_DIR}"
hamlet test run --pytest-args "--junitxml=junit.xml" -t "./test_templates.py"
popd
