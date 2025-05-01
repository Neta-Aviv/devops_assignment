# DevOps Assignment – AWS Microservices Deployment with CI/CD

## 📦 Project Overview

This project showcases a production-style deployment of two microservices (API & Worker) on AWS using:

- Terraform for infrastructure provisioning  
- ECS Fargate for containerized deployment  
- Application Load Balancer (ALB) for traffic routing 
- S3, SQS, and SSM for service integrations  
- GitHub Actions for CI/CD pipeline

---

## 🛠️ Infrastructure Components

- **VPC, Subnets, IGW** – Custom network setup with public subnets in 2 AZs  
- **ECS Cluster** – Runs both services using Fargate  
- **ALB + Target Group** – Routes traffic to the API service on port 5000  
- **S3** – Used by the worker to store data  
- **SQS** – Message queue for async communication  
- **SSM Parameter Store** – Secure storage for the API token  
- **IAM Roles** – ECS task roles with least-privilege permissions

---

## 🚀 CI/CD Pipeline

Using **GitHub Actions**, the pipeline includes:

### ✅ build.yml

- Builds and pushes Docker images for both services to Docker Hub  
- Triggered on push to `main`

### ✅ deploy.yml

- Runs `terraform apply` to deploy or update infrastructure and ECS services  
- Requires AWS credentials and DockerHub secrets in GitHub repository

---

## 🔐 Required GitHub Secrets

| Secret Name             | Description                            |
|-------------------------|----------------------------------------|
| AWS_ACCESS_KEY_ID       | IAM user access key                    |
| AWS_SECRET_ACCESS_KEY   | IAM user secret                        |
| DOCKERHUB_USERNAME      | Docker Hub username                    |
| DOCKERHUB_PASSWORD      | Docker Hub password or access token    |

---

## 📡 API Usage

After deployment, get your **Load Balancer DNS** from Terraform output or AWS Console.

### Test if API is live:

curl -X POST http://<your-lb-dns>/message
-H "Authorization: checkpoint123"
-H "Content-Type: application/json"
-d '{"message": "Hello from Neta!"}'

Expected response:

{ "status": "Message sent to SQS" }

---

## 🔁 Redeploying

To trigger a full redeploy:  
1. Push any code change to `main`  
2. GitHub Actions will rebuild images and redeploy ECS services

---

## 🧹 Teardown

To remove all resources:

cd terraform 
terraform destroy


---
## 📁 Project Structure

api-service/         # Flask app with SSM + SQS integration  
worker-service/      # Python service that polls SQS and writes to S3  
terraform/           # Infrastructure as Code  
.github/workflows/   # CI/CD pipeline definitions  
README.md            # Project documentation

---

## 🧠 Notes

- Your app uses Flask and Boto3  
- The API reads a secret token from SSM Parameter Store  
- Worker listens to the SQS queue and saves messages to S3

---

## 📍 Author

Neta Aviv – DevOps Engineer
