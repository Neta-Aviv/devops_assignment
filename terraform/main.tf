provider "aws" {
  region = var.region
}

# --------------------
# VPC & Networking
# --------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow HTTP inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------
# ECS Cluster
# --------------------
resource "aws_ecs_cluster" "main" {
  name = "checkpoint-ecs-cluster"
}

# --------------------
# SQS Queue
# --------------------
resource "aws_sqs_queue" "messages" {
  name = "checkpoint-message-queue"
}

# --------------------
# S3 Bucket
# --------------------
resource "aws_s3_bucket" "storage" {
  bucket        = "checkpoint-s3-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

# --------------------
# SSM Parameter
# --------------------
resource "aws_ssm_parameter" "api_token" {
  name      = "checkpoint-api-token"
  type      = "SecureString"
  value     = var.api_token
  overwrite = true
}

# --------------------
# IAM Role for ECS Task
# --------------------
resource "aws_iam_role" "ecs_task_exec_role" {
  name = "checkpoint-ecs-task-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --------------------
# CloudWatch Logs
# --------------------
resource "aws_cloudwatch_log_group" "api_log_group" {
  name              = "/ecs/api"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "worker_log_group" {
  name              = "/ecs/worker"
  retention_in_days = 7
}

# --------------------
# ECS Task Definitions
# --------------------
resource "aws_ecs_task_definition" "api" {
  family                   = "api-service-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn

  container_definitions = jsonencode([{
    name      = "api"
    image     = "netaaviv100/api-service:latest"
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
    environment = [
      { name = "SSM_TOKEN_NAME", value = aws_ssm_parameter.api_token.name },
      { name = "SQS_QUEUE_URL",  value = aws_sqs_queue.messages.id }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api_log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "worker-service-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn

  container_definitions = jsonencode([{
    name  = "worker"
    image = "netaaviv100/worker-service:latest"
    environment = [
      { name = "SQS_QUEUE_URL", value = aws_sqs_queue.messages.id },
      { name = "S3_BUCKET_NAME", value = aws_s3_bucket.storage.bucket }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.worker_log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# --------------------
# Application Load Balancer
# --------------------
resource "aws_lb" "api_alb" {
  name               = "api-service-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]

  depends_on = [aws_security_group.ecs_sg]
}

resource "aws_lb_target_group" "api_tg" {
  name        = "api-target-group"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}

# --------------------
# ECS Services
# --------------------
resource "aws_ecs_service" "api_service" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.public.id, aws_subnet.public_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_tg.arn
    container_name   = "api"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.api_listener]
}

resource "aws_ecs_service" "worker_service" {
  name            = "worker-service-v2"
  cluster         = aws_ecs_cluster.main.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.public.id, aws_subnet.public_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

