#!/usr/bin/env bash

echo "###############################################"
echo "# Running template tests for the AWS provider #"
echo "###############################################"

echo "Generating unit list..."
${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l unitlist > /dev/null 2>&1
UNIT_LIST="$(jq -r '.DeploymentUnits | join(" ")' < ~/cot_tests/unitlistconfig.json)"

for unit in $UNIT_LIST; do
    echo "Creating templates for $unit ..."
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l segment -u $unit > /dev/null 2>&1 || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l solution -u $unit > /dev/null 2>&1 || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l application -u $unit > /dev/null 2>&1 || true
done

cot test generate --directory ~/cot_tests/ -o ~/cot_tests/test_templates.py

cd ~/cot_tests
echo "Running Tests..."
cot test run -t ~/cot_tests/test_templates.py
