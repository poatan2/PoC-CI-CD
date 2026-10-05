pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        IMAGE_REPO = 'goguma1/demo-app'
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
                withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-access-token',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_REPO}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            sh 'docker rmi ${IMAGE_REPO}:${IMAGE_TAG} || true'
        }
        failure {
            echo "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}