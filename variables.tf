variable "aws_access_key" {
  description = "AWS access key for authentication"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for authentication"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-north-1"
}

variable "aws_image_id" {
  description = "AMI ID for the primary Ubuntu EC2 instance"
  type        = string
  default     = "ami-0aba19e56f3eaec05"
}

variable "aws_image_id_2" {
  description = "AMI ID for the secondary Amazon Linux EC2 instance"
  type        = string
  default     = "ami-07b8fb6bd3e9627a6"
}

variable "aws_instance_type" {
  description = "EC2 instance type for both instances"
  type        = string
  default     = "t3.small"
}

variable "aws_key_name" {
  description = "Name of the existing EC2 key pair for SSH access"
  type        = string
  default     = "Stockholm_3"
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "cmd521-alb"
}

variable "alb_health_check_path" {
  description = "Health check path for the ALB target group"
  type        = string
  default     = "/"
}

variable "common_tags" {
  description = "Tags applied to every resource that supports tagging"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "CMD521"
  }
}
