
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        IMAGE_NAME = 'gowthamdocker24/kanban-dashboard'
        APP_NAME = 'kanban-app'
        APP_URL = 'http://localhost:8081/health'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "build-${env.BUILD_NUMBER}"
                }

                sh '''
                    docker build -t "$IMAGE_NAME:$IMAGE_TAG" .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x

                        export DOCKER_CONFIG="$(mktemp -d)"
                        trap 'docker logout >/dev/null 2>&1 || true; rm -rf "$DOCKER_CONFIG"' EXIT

                        printf '%s' "$DOCKER_TOKEN" |
                          docker login -u "$DOCKER_USER" --password-stdin

                        docker push "$IMAGE_NAME:$IMAGE_TAG"
                    '''
                }
            }
        }

        stage('Deploy and Verify') {
            steps {
                sh '''
                    set -eu

                    PREVIOUS_IMAGE=""
                    if docker container inspect "$APP_NAME" >/dev/null 2>&1; then
                        PREVIOUS_IMAGE=$(docker inspect \
                          --format '{{.Config.Image}}' "$APP_NAME")
                    fi

                    echo "Previous image: ${PREVIOUS_IMAGE:-none}"
                    echo "New image: $IMAGE_NAME:$IMAGE_TAG"

                    rollback() {
                        echo "Deployment failed. Starting rollback..."

                        docker rm -f "$APP_NAME" 2>/dev/null || true

                        if [ -n "$PREVIOUS_IMAGE" ]; then
                            docker run -d \
                              --name "$APP_NAME" \
                              --restart unless-stopped \
                              -p 8081:8080 \
                              --memory=512m \
                              --cpus=1 \
                              "$PREVIOUS_IMAGE"

                            echo "Restored image: $PREVIOUS_IMAGE"

                            if check_health; then
                                echo "Rollback health check PASSED"
                            else
                                echo "WARNING: Rollback health check FAILED"
                            fi
                        else
                            echo "No previous image available for rollback"
                        fi
                    }

                    check_health() {
                        i=1
                        while [ "$i" -le 12 ]; do
                            STATUS=$(docker inspect \
                              --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
                              "$APP_NAME" 2>/dev/null || true)

                            if [ "$STATUS" = "healthy" ] &&
                               curl -fsS "$APP_URL" >/dev/null; then
                                return 0
                            fi

                            echo "Health check $i/12: $STATUS"
                            sleep 5
                            i=$((i + 1))
                        done

                        return 1
                    }

                    trap 'rollback' EXIT

                    docker rm -f "$APP_NAME" 2>/dev/null || true

                    docker run -d \
                      --name "$APP_NAME" \
                      --restart unless-stopped \
                      -p 8081:8080 \
                      --memory=512m \
                      --cpus=1 \
                      "$IMAGE_NAME:$IMAGE_TAG"

                    if ! check_health; then
                        echo "New deployment health check FAILED"
                        exit 1
                    fi

                    trap - EXIT
                    echo "New deployment health check PASSED"
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Deployment completed successfully.'
        }

        failure {
            echo 'FAILURE: Check deployment and rollback logs.'
        }
    }
}