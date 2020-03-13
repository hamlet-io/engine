#!groovy

pipeline {
    options {
        timestamps()
        disableConcurrentBuilds()
        quietPeriod(30)
    }

    agent none

    stages {
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
