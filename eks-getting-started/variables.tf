#
# Variables Configuration
#

variable "cluster_name" {
  default = "terraform-eks-demo"
  type    = "string"
}

variable "eks_worker_instance_type" {
default = "m4.large"
}

variable "eks_worker_desired_capacity" {
default = "2"
}

variable "aws_region" {
default = "us-west-2"
}
