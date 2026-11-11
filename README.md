# Kanban Dashboard — Docker Jenkins CI/CD on AWS

## Project Overview

This project demonstrates an automated CI/CD pipeline for deploying a React-based Kanban Dashboard using Docker, Jenkins, GitHub, Docker Hub, and AWS EC2.

The pipeline automatically builds, tests deployment health, and deploys a versioned Docker image whenever code is pushed to the GitHub repository.

## Technologies Used

- **Frontend:** React, TypeScript, Vite
- **Containerization:** Docker, multi-stage Dockerfile
- **Web Server:** Nginx
- **CI/CD:** Jenkins Pipeline
- **Version Control:** Git and GitHub
- **Container Registry:** Docker Hub
- **Cloud Infrastructure:** AWS EC2 (Ubuntu)
- **Monitoring:** Docker HEALTHCHECK, Jenkins console logs, Docker logs

## CI/CD Architecture

```text
Developer
    |
    | git push origin main
    v
GitHub Repository
    |
    | GitHub Webhook
    v
Jenkins (AWS EC2 :8080)
    |
    | Checkout Source
    v
Build Docker Image
    |
    | Version Tag: build-N
    v
Push Image to Docker Hub
    |
    v
Deploy Docker Container on EC2
    |
    v
Container Health Check
    |
    +---- Healthy ----> Deployment SUCCESS
    |
    +---- Unhealthy --> Rollback to Previous Image
```

## GitHub Repository

https://github.com/gowthamnaganathan24/kanban-dashboard

## Docker Hub Repository

https://hub.docker.com/r/gowthamdocker24/kanban-dashboard

Docker images are tagged using the Jenkins build number, for example:

`gowthamdocker24/kanban-dashboard:build-7`

## Docker Containerization

The application uses a multi-stage Dockerfile:

1. **Build stage:** Node.js builds the React application.
2. **Runtime stage:** Nginx serves the generated static files.

The Docker configuration includes:

- Non-root runtime container
- `.dockerignore` to exclude unnecessary files
- Port `8080` exposed inside the container
- Docker HEALTHCHECK
- Minimal runtime image
- No credentials stored in the Dockerfile

The application is accessible through EC2 port `8081`.

## Jenkins CI/CD Pipeline

The Jenkins pipeline is defined in the `Jenkinsfile` and contains these stages:

1. **Checkout:** Fetch source code from GitHub.
2. **Build Docker Image:** Create a versioned Docker image.
3. **Push to Docker Hub:** Authenticate using Jenkins credentials and push the image.
4. **Deploy to EC2:** Replace the running application container.
5. **Health Check:** Verify that the new container is healthy.

The pipeline reports SUCCESS or FAILURE based on execution results.

### Automatic Rollback

The deployment stage records the previously deployed Docker image.

If deployment or health validation fails, the pipeline attempts to restore the previous working image.

Rollback behavior was tested by intentionally using an invalid health-check endpoint and verifying that the previous image was restored.

## GitHub Webhook Automation

GitHub webhooks are configured to trigger Jenkins automatically when a commit is pushed to the `main` branch.

The webhook uses the Jenkins endpoint:

`/github-webhook/`

**Verification completed:**

- GitHub webhook delivery returned HTTP 200.
- Jenkins displayed `Started by GitHub push`.
- Jenkins completed the automatically triggered pipeline successfully.

No manual **Build Now** action was required.

## AWS EC2 Infrastructure

The project runs on an AWS EC2 instance with:

| Configuration | Value |
|---|---|
| Instance type | t3.small |
| Operating system | Ubuntu |
| vCPU | 2 |
| RAM | 2 GiB |
| Jenkins port | 8080 |
| Application host port | 8081 |
| Application container port | 8080 |

AWS Security Group rules control inbound access to SSH, Jenkins, and the application.

## Docker Resource Limits

The application container is configured with:

```bash
--memory=512m --cpus=1
```

These limits are applied during deployment and rollback.

This prevents the application container from consuming all resources on the EC2 instance.

## Health Check and Validation

The following commands were used to validate the deployment:

```bash
docker ps --filter name=kanban-app

docker inspect --format='{{.State.Health.Status}}' kanban-app

curl -f http://localhost:8081/health
```

**Verified results:**

- Container status: `running`
- Docker health status: `healthy`
- Health endpoint response: `healthy`

## Logging and Monitoring

Jenkins console output provides visibility into pipeline stages, build failures, deployment status, and rollback behavior.

Docker commands used for monitoring:

```bash
docker logs --tail 30 kanban-app

docker stats --no-stream kanban-app

docker inspect kanban-app
```

Successful and failed Jenkins builds were reviewed during pipeline testing.

## Security Practices

- Non-root Docker runtime
- Multi-stage Docker build
- Jenkins Credentials store for Docker Hub authentication
- No credentials committed to GitHub
- Restricted AWS Security Group access
- Container CPU and memory limits
- Health checks before deployment is considered successful

**Note:** The project demonstration uses an HTTP GitHub webhook with GitHub network allowlisting. Production deployment should use HTTPS, webhook signature verification, and stronger access controls.

## Project Outcome

Successfully implemented an automated CI/CD workflow:

**GitHub → Jenkins → Docker Build → Docker Hub → AWS EC2 → Health Validation**

The workflow supports versioned Docker images, automated deployments, health monitoring, resource limits, and rollback on deployment failure.

## Author

Gowtham N.

**Project:** GUVI Project 02 — Deploy Your Code on a Docker Container using Jenkins on AWS