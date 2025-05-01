variable "region" {
  default = "us-east-1"
}

variable "api_token" {
  description = "The token used to validate requests to the API service"
  type        = string
}

variable "create_listener" {
  description = "Whether to create the ALB listener on first apply; afterwards leave false to skip if it already exists."
  type        = bool
  default     = true
}

