# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = var.vpc_name

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    "Name" = var.vpc_name
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  name                                     = var.cluster_name
  kubernetes_version                       = var.cluster_version
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets

  endpoint_public_access                   = true
  endpoint_private_access                  = true
  enable_irsa                              = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = false

  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    tfe-nodegroup = {
      name = "node-group-1"
      #ami_type                   = "AL2_x86_64"
      instance_types = ["t3.xlarge"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      disk_size      = 20
      iam_role_attach_cni_policy = true
      iam_role_additional_policies = {
        AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      }
    }
  }
}

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "tfedb-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

# PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier             = "tfedb-instance"
  engine                 = "postgres"
  engine_version         = "17"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.rds_username
  password               = var.rds_password
  db_name                = var.rds_db_name
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# Security Group for PostgreSQL
resource "aws_security_group" "db_sg" {
  name        = "tfedb-sg"
  description = "Allow internal VPC access to PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "tfecache-instance"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}

# Subnet Group for Redis
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "tfecache-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

# Security Group for Redis 
resource "aws_security_group" "redis_sg" {
  name        = "tfecache-sg"
  description = "Allow internal VPC access to Redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
