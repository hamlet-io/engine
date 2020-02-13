#!groovy

pipeline {
    options {
        timestamps()
    }

    agent {
        label 'codeontaplatest'
    }

    environment {
        GENERATION_DIR="${WORKSPACE}/aws"
        GENERATION_BASE_DIR="${WORKSPACE}"
    }

    stages {
        stage('Generate test cases') {
            steps {
                sh '''#!/usr/bin/env bash
                ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l unitlist
                UNIT_LIST="$(jq -r '.DeploymentUnits[]' < ~/cot_tests/unitlistconfig.json)"

                for unit in "${UNIT_LIST}"
                do
                    echo "Running templates for $unit"
                    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l segment -u $unit || true
                    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l solution -u $unit || true
                    ${GENERATION_DIR}/createTemplate.sh -i mock -p aws -p awstest -o ~/cot_tests/ -l application -u $unit || true
                done

                ls -l ~/cot_tests/
                '''
            }
        }
    }
}
