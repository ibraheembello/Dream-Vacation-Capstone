# Inputs. Everything has a sane default except ssh_public_key, which the pipeline
# supplies via TF_VAR_ssh_public_key (sourced from a GitHub secret).
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH public key registered on the instance for the ubuntu user"
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to reach SSH (22). Defaults to open; tighten if wanted."
  type        = string
  default     = "0.0.0.0/0"
}

variable "domain_name" {
  description = "Domain served by the app. A Route 53 public hosted zone and an apex A record to the EC2 Elastic IP are created for it."
  type        = string
  default     = "dream-vacations.duckdns.org"
}
