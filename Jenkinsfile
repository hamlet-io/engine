#!groovy

pipeline {
    options {
        timestamps()
    }

    agent none

    stages {
        stage('Run AWS Template Tests') {
            agent {
                label 'codeontaplatest'
            }
            environment {
                GENERATION_DIR="${WORKSPACE}/aws"
                GENERATION_BASE_DIR="${WORKSPACE}"
            }
            steps {
                sh '''#!/usr/bin/env bash
                ${WORKSPACE}/test/aws/run_aws_template_tests.sh
                '''
            }
        }

        stage('Trigger Docker Build') {
            when {
                branch 'master'
                beforeAgent true
            }
            agent none
            steps {
                build (
                    job: '../docker-gen3/master'
                )
            }
        }
    }
}
