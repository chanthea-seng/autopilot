pipeline {
    agent any
    environment {
        // Fixed Harbor registry URL format (no http:// in image name)
        HARBOR_REGISTRY = "harbor.local:8082"  // Only domain:port
        HARBOR_PROJECT = "nextjs-app"          // Your Harbor project name
        IMAGE_NAME = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/nextjs"
        IMAGE_TAG = "${env.BUILD_NUMBER}"      // Better than 'latest' for tracking
        HARBOR_CREDENTIALS_ID = "harbor-cred-id"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/chanthea-seng/autopilot.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Added --no-cache for clean builds
                    dockerImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "--no-cache .")
                }
            }
        }
        
        stage('Login to Harbor') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${HARBOR_CREDENTIALS_ID}",
                    usernameVariable: 'HARBOR_USER',
                    passwordVariable: 'HARBOR_PASS'
                )]) {
                    sh """
                        docker login ${HARBOR_REGISTRY} \
                        -u $HARBOR_USER \
                        --password-stdin <<< '$HARBOR_PASS'
                    """
                }
            }
        }
        
        stage('Push Image to Harbor') {
            steps {
                script {
                    // Add retry logic for network issues
                    retry(3) {
                        dockerImage.push()
                    }
                }
            }
        }
        
        stage('Logout from Harbor') {
            steps {
                sh "docker logout ${HARBOR_REGISTRY}"
            }
        }
        
        // Added new stage for Portainer deployment
        stage('Deploy to Portainer') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'portainer-api-key', variable: 'PORTAINER_TOKEN')]) {
                        sh """
                            curl -X POST \
                            "http://portainer.local:9000/api/endpoints/1/docker/containers/create?name=nextjs-${IMAGE_TAG}" \
                            -H "Authorization: Bearer $PORTAINER_TOKEN" \
                            -H "Content-Type: application/json" \
                            -d '{
                                "Image": "${IMAGE_NAME}:${IMAGE_TAG}",
                                "HostConfig": {
                                    "PortBindings": {
                                        "3000/tcp": [{"HostPort": "3000"}]
                                    }
                                }
                            }'
                        """
                    }
                }
            }
        }
    }
    
    // Added post-build actions
    post {
        always {
            cleanWs()  // Clean workspace after build
        }
        success {
            slackSend color: 'good', message: "SUCCESS: ${IMAGE_NAME}:${IMAGE_TAG} deployed to Harbor and Portainer"
        }
        failure {
            slackSend color: 'danger', message: "FAILED: Build #${env.BUILD_NUMBER}"
        }
    }
}