variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "local_ip_cidr" {
  description = "Your public IP in CIDR notation for SSH access (e.g. 203.0.113.10/32)"
  type        = string
}

variable "key_pair_name" {
  description = "Name of an existing EC2 Key Pair used to SSH as ec2-user / admin"
  type        = string
}

variable "deploy_public_key" {
  description = "SSH public key content for the deploy user (used by GitHub Actions)"
  type        = string
}

variable "domain" {
  description = "Fully qualified domain name for the app (e.g. gs-rest-service.igor-aws.link)"
  type        = string
  default     = "gs-rest-service.igor-aws.link"
}

variable "certbot_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}
