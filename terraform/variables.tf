variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type for the k3s node"
  type        = string
  default     = "t3.small"
}

variable "ssh_public_key_path" {
  description = "Path to local SSH public key"
  type        = string
  default     = "~/.ssh/resume-live-key-new.pub"
}

variable "allowed_cidr" {
  description = "Your IP in CIDR notation for SSH and kubectl access (e.g. 1.2.3.4/32)"
  type        = string
}
