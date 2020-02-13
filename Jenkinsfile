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
                UNIT_LIST="$(jq '.DeploymentUnits | @csv' < ~/cot_tests/unitlistconfig.json)"

                echo "Generating units for ${UNIT_LIST}
                '''
            }
        }
    }
}
