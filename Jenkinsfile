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
                ${GENERATION_DIR}/createTemplate.sh -p aws -p awstest -o ~/cot_tests/ -l unitlist
                cat ~/cot_tests/unitlist.json
                '''
            }
        }
    }
}
