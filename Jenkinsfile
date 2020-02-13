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
        stage('Run AWS Template Steps') {
            steps {
                sh '''#!/usr/bin/env bash
                ${WORKSPACE}/test/aws/run_aws_template_tests.sh
                '''
            }
        }
    }
}
