# Build EKS with external services for Terraform Enterprise FDO

This Terraform code which is forked from hashicorp/learn-terraform-provision-eks-cluster, builds a EKS cluster on AWS with two external services (PostgreSQL and Redis) requires for deploying Terraform Enterprise on Kubernetes platforms

The main.tf is added with two major resources `aws_db_instance` and `aws_elasticache_cluster` for provisioning AWS RDS and Redis.  So that when Terraform Apply it will be provisioning the minimal resources(EKS, RDS and Redis) for you to deploy Terraform Enterprise instance.  But you still need to reference to your own S3 Bucket for storing Terraform state file.

Remember to pass the RDS password in the seperate variable file`.tfvars` file OR command line option `-var`.