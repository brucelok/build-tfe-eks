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

variable "rds_username" {
  description = "RDS username"
  type        = string
  default     = "postgres"
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = "tfedb"
}

variable "rds_password" {
  description = "RDS password"
  type        = string
}