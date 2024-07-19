# Build EKS with external services for Terraform Enterprise FDO

This Terraform code which is forked from [hashicorp/learn-terraform-provision-eks-cluster](https://github.com/hashicorp/learn-terraform-provision-eks-cluster), builds a EKS cluster on AWS with two external services (PostgreSQL and Redis) requires for deploying Terraform Enterprise on Kubernetes platforms

The **main.tf** is added with two major resources `aws_db_instance` and `aws_elasticache_cluster` for provisioning AWS RDS and Redis.  So that when Terraform Apply it will be provisioning the minimal resources(EKS, RDS and Redis) for you to deploy Terraform Enterprise instance.  But you still need to reference to your own S3 Bucket for storing Terraform state file.

* `certData` ,`keyData` and `caCertData`: These are base64 encoded outputs from the certificate and private key PEM files. eg: `cat privkey.pem | base64`
* In AWS RDS, the default parameter group of postgres15 and 16 are `rds.force_ssl` set to `1`. That means the `TFE_DATABASE_PARAMETERS` must set to `sslmode=require` in Helm value.yaml file
* Ensure your S3 Bucket can be accessed from the pod level
* Remember to pass the RDS password in the seperate variable file`.tfvars` file OR command line option `-var`.

After you successfully provision the EKS, RDS and Redis on AWS, follow the steps from [HashiCorp documentation](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/kubernetes/install#2-pull-image) to prepare Terraform Enterprise image in Kubernetes. 

Then you can install Terraform Enterprise with Helm.
For example:
```
helm install terraform-enterprise hashicorp/terraform-enterprise -f value.yaml -n tfe --version "1.2.0" --wait --debug
```

Minimal Helm value.yaml
```
replicaCount: 1
tls:
  certData: "..........."
  keyData: "..........."
  caCertData: "........."

image:
  repository: images.releases.hashicorp.com
  name: hashicorp/terraform-enterprise
  tag: v202404-2

env:
  variables:
    TFE_HOSTNAME: "YOUR_NAME.tf-support.hashicorpdemo.com"
    TFE_DATABASE_HOST: "tfedb-instance.xxxxxxxx.ap-southeast-2.rds.amazonaws.com:5432"
    TFE_DATABASE_NAME: "tfedb"
    TFE_DATABASE_PARAMETERS: "sslmode=require"
    TFE_DATABASE_USER: "postgres"
    TFE_REDIS_HOST: "tfecache-instance.xxxxxx.0001.apse2.cache.amazonaws.com:6379"
    TFE_OBJECT_STORAGE_TYPE: s3
    TFE_OBJECT_STORAGE_S3_BUCKET: "ap-southeast-2-state"
    TFE_OBJECT_STORAGE_S3_REGION: "ap-southeast-2"
    TFE_OBJECT_STORAGE_S3_USE_INSTANCE_PROFILE: true
    TFE_RUN_PIPELINE_KUBERNETES_DEBUG_ENABLE: true
  secrets:
    TFE_DATABASE_PASSWORD: "PASSWORD"
    TFE_LICENSE: "LICENSE..."
    TFE_ENCRYPTION_PASSWORD: "PASSWORD"

service:
  annotations: {}
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
  type: LoadBalancer
  port: 443
```
