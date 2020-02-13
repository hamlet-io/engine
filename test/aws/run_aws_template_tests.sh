#!/usr/bin/env bash
${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l unitlist
UNIT_LIST="$(jq -r '.DeploymentUnits | join(" ")' < ~/cot_tests/unitlistconfig.json)"

for unit in $UNIT_LIST; do
    echo "Running templates for $unit"
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l segment -u $unit || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l solution -u $unit || true
    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l application -u $unit || true
done

cot test generate --directory ~/cot_tests/ -o ~/cot_tests/test_templates.py

cd ~/cot_tests
echo "Running Tests..."
cot test run -t ~/cot_tests/test_templates.py
