pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        IMAGE_REPO = 'ghcr.io/poatan2/demo-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    def shortSha = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${shortSha}"
                }
            }
        }

        stage('Test') {
            steps {
                sh 'chmod +x gradlew && ./gradlew test --no-daemon'
            }
            post {
                always {
                    junit 'build/test-results/test/*.xml'
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${IMAGE_REPO}:${IMAGE_TAG} .'
            }
        }

        stage('Docker Push') {
            when {
                anyOf {
                    branch 'main'                                   // Multibranch Pipeline
                    expression { env.GIT_BRANCH == 'origin/main' }  // 일반 Pipeline(SCM)
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'ghcr-token', usernameVariable: 'GHCR_USER', passwordVariable: 'GHCR_TOKEN')]) {
                    sh 'echo $GHCR_TOKEN | docker login ghcr.io -u $GHCR_USER --password-stdin'
                    sh 'docker push ${IMAGE_REPO}:${IMAGE_TAG}'
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout ghcr.io || true'
            sh 'docker rmi ${IMAGE_REPO}:${IMAGE_TAG} || true'
        }
        failure {
            echo "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}