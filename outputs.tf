# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "postgres_server_details" {
  description = "Postgres server details"
  value = {
    hostname      = aws_db_instance.postgres.address
    port          = aws_db_instance.postgres.port
    username      = aws_db_instance.postgres.username
    password      = aws_db_instance.postgres.password
    database_name = aws_db_instance.postgres.db_name
  }
  sensitive = true
}

output "redis_cache_details" {
  description = "Redis cache details"
  value = {
    hostname = aws_elasticache_cluster.redis.cache_nodes[0].address
    port     = aws_elasticache_cluster.redis.cache_nodes[0].port
  }
}