#!groovy

def slackChannel = '#devops-framework'

pipeline {
    options {
        durabilityHint('PERFORMANCE_OPTIMIZED')
    }

    agent {
        label 'hamlet-latest'
    }

    stages {

        stage('Run Schemas Generation as Test') {
            environment {
                GENERATION_ENGINE_DIR="${WORKSPACE}"
                SCHEMA_OUTPUT_DIR="${WORKSPACE}"
            }

            steps {
                sh '''#!/usr/bin/env bash
                    hamlet -i mock -p shared -p aws -p azure schema create-schemas -o "${SCHEMA_OUTPUT_DIR}"
                '''
            }
        }

        stage('Run Shared Provider Tests') {
            environment {
                GENERATION_ENGINE_DIR="${WORKSPACE}"
                TEST_OUTPUT_DIR='./hamlet_tests'
            }
            steps {
                sh '''#!/usr/bin/env bash
                    ./test/run_shared_template_tests.sh
                '''
            }
            post {
                always {
                    junit 'hamlet_tests/junit.xml'
                }
            }
        }

        stage('Trigger Docker Build') {
            when {
                branch 'master'
            }

            steps {
                build (
                    job: '../docker-hamlet/master',
                    wait: false
                )
            }
        }
    }

    post {
        failure {
            slackSend (
                message: "*Failure* | <${BUILD_URL}|${JOB_NAME}>",
                channel: "${slackChannel}",
                color: "#D20F2A"
            )
        }
    }
}
