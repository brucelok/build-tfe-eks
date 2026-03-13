# Build EKS with external services for Terraform Enterprise (TFE) FDO

The purpose of the repo is for deploying a minimal infrastructure resources required for running self-managed TFE instance on EKS.
This Terraform codex which is forked from [hashicorp/learn-terraform-provision-eks-cluster](https://github.com/hashicorp/learn-terraform-provision-eks-cluster), builds a EKS cluster on AWS with two external services (RDS for PostgreSQL and ElastiCache Redis) requires for deploying TFE on AWS EKS.

## Deploy EKS
The **main.tf** is added with two major resources `aws_db_instance` and `aws_elasticache_cluster` for provisioning AWS RDS and Redis.  So that when Terraform Apply it will be provisioning the minimal resources(EKS, RDS and Redis) on the same VPC for you to deploy TFE instance.  But you still need to reference to your own S3 Bucket for storing Terraform state file so that Terraform destroy won’t delete your state file.

After you successfully provision the EKS, RDS and Redis on AWS, follow the steps from [HashiCorp documentation](https://developer.hashicorp.com/terraform/enterprise/deploy/kubernetes#install-terraform-enterprise-with-helm) to prepare TFE's image pull secre in Kubernetes. 

## Deploy TFE
The example Helm [value.yaml](https://github.com/hashicorp/terraform-enterprise-helm/blob/main/values.yaml). The following sample value file contains the minimal setting required to deploy the TFE instance on EKS
```
replicaCount: 1
tls:
  certData: "PEM_in_base64_format"
  keyData: "PEM_in_base64_format"
  caCertData: "PEM_in_base64_format"

image:
  repository: images.releases.hashicorp.com
  name: hashicorp/terraform-enterprise
  tag: v202503-1

env:
  variables:
    TFE_HOSTNAME: "tfe.example.com"
    TFE_DATABASE_HOST: "YOUR_DB_ADDR:5432"
    TFE_DATABASE_NAME: "tfedb"
    TFE_DATABASE_PARAMETERS: "sslmode=require"
    TFE_DATABASE_USER: "postgres"
    TFE_REDIS_HOST: "YOUR_REDIS_ADDR:6379"
    TFE_OBJECT_STORAGE_TYPE: s3
    TFE_OBJECT_STORAGE_S3_BUCKET: "ap-southeast-2-tfe"
    TFE_OBJECT_STORAGE_S3_REGION: "ap-southeast-2"
    TFE_OBJECT_STORAGE_S3_USE_INSTANCE_PROFILE: true
    TFE_RUN_PIPELINE_KUBERNETES_DEBUG_ENABLE: true
    TFE_CAPACITY_CONCURRENCY: "10"
    TFE_CAPACITY_MEMORY: "1024"
  secrets:
    TFE_DATABASE_PASSWORD: "YOUR_DB_PASSWORD"
    TFE_LICENSE: "PASTE_LICENSE_STRING_HERE"
    TFE_ENCRYPTION_PASSWORD: "YOUR_ENCRYPTION_PASSWORD"

resources:
  requests:
    memory: "2Gi"
    cpu: "750m"
  limits:
    memory: "3Gi"
    cpu: "1000m"

service:
  annotations: {}
  type: LoadBalancer
  port: 443

strategy:
  type: Recreate

tfe:
  metrics:
    enable: true
    httpPort: 9090
    httpsPort: 9091
  privateHttpPort: 8080
  privateHttpsPort: 8443

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

**Attention Required for the Following Data:**
* `certData` ,`keyData` and `caCertData`: These must be a base64 encoded outputs from the certificate and private key PEM files. eg: `base64 -w 0 cert.pem`
* In AWS RDS, the default parameter group of postgres 15 and above are `rds.force_ssl` set to `1`. That means the `TFE_DATABASE_PARAMETERS` must set to `sslmode=require` in Helm value.yaml file
* Ensure your S3 Bucket can be accessed from the pod level
* Remember to pass the RDS password in the seperate variable file`.tfvars` file OR command line option `-var`.
* Redis user must be a default user

Finally you can install TFE with Helm.
For example:
```
helm install terraform-enterprise hashicorp/terraform-enterprise -f value.yaml -n tfe --version "1.2.0" --wait --debug
```

## Post-installation
Once helm install is completed, you need to **[provision your first administrative user](https://developer.hashicorp.com/terraform/enterprise/deploy/initial-admin-user)** before start using TFE.
