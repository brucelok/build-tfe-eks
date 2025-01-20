# Build EKS with external services for Terraform Enterprise FDO

This Terraform code which is forked from [hashicorp/learn-terraform-provision-eks-cluster](https://github.com/hashicorp/learn-terraform-provision-eks-cluster), builds a EKS cluster on AWS with two external services (RDS for PostgreSQL and ElastiCache Redis) requires for deploying Terraform Enterprise on AWS EKS.

## Deploy EKS
The **main.tf** is added with two major resources `aws_db_instance` and `aws_elasticache_cluster` for provisioning AWS RDS and Redis.  So that when Terraform Apply it will be provisioning the minimal resources(EKS, RDS and Redis) on the same VPC for you to deploy Terraform Enterprise instance.  But you still need to reference to your own S3 Bucket for storing Terraform state file so that Terraform destroy won’t delete your state file.

After you successfully provision the EKS, RDS and Redis on AWS, follow the steps from [HashiCorp documentation](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/kubernetes/install#2-pull-image) to prepare Terraform Enterprise image in Kubernetes. 

## Deploy Terraform Enterprise
The example Helm [value.yaml](https://github.com/brucelok/build-tfe-eks/blob/main/value.yaml) file contains the minimal setting required to deploy the Terraform Enterprise instance on EKS.

**Attention Required for the Following Data:**
* `certData` ,`keyData` and `caCertData`: These must be a base64 encoded outputs from the certificate and private key PEM files. eg: `base64 -w 0 cert.pem`
* In AWS RDS, the default parameter group of postgres15 and 16 are `rds.force_ssl` set to `1`. That means the `TFE_DATABASE_PARAMETERS` must set to `sslmode=require` in Helm value.yaml file
* Ensure your S3 Bucket can be accessed from the pod level
* Remember to pass the RDS password in the seperate variable file`.tfvars` file OR command line option `-var`.
* Redis user must be a default user

Finally you can install Terraform Enterprise with Helm.
For example:
```
helm install terraform-enterprise hashicorp/terraform-enterprise -f value.yaml -n tfe --version "1.2.0" --wait --debug
```

## Post-installation
Once helm install is completed, you need to **[provision your first administrative user](https://developer.hashicorp.com/terraform/enterprise/deploy/initial-admin-user)** before start using Terraform Enterprise.
