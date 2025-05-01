variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "api_token" {
  description = "API token used for secure communication with services"
  type        = string
  sensitive   = true
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "checkpoint-ecs-cluster"
}

variable "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution IAM role"
  type        = string
  default     = "checkpoint-ecs-task-exec-role"
}

variable "ecs_task_role_name" {
  description = "Name of the ECS task IAM role"
  type        = string
  default     = "checkpoint-ecs-task-role"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "checkpoint-s3-bucket"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "checkpoint-sqs-queue"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "container_images" {
  description = "Mapping of service names to their container images"
  type        = map(string)
  default = {
    "api"    = "netaaviv100/api-service:latest"
    "worker" = "netaaviv100/worker-service:latest"
  }
}
