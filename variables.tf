variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "tfe-eks"
}

variable "cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "tfe-eks-vpc"
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "ap-southeast-2"
}

#variable "ssh_public_key" {
#  description = "Your SSH public key"
#  type        = string
#  default     = ""
#}