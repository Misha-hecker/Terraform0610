output "instance_public_ip_primary" {
  description = "Public IP address of the primary Ubuntu EC2 instance"
  value       = aws_instance.primary.public_ip
}

output "instance_public_ip_secondary" {
  description = "Public IP address of the secondary Amazon Linux EC2 instance"
  value       = aws_instance.secondary.public_ip
}

output "security_group_instances_id" {
  description = "ID of the EC2 instances security group"
  value       = aws_security_group.instances.id
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "Full HTTP URL of the Application Load Balancer"
  value       = "http://${aws_lb.this.dns_name}"
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}
