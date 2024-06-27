provider "aws" {
  region = var.region
}
# retrieve my existing existing VPC and subnets
data "aws_vpc" "eks_vpc" {
  id = "vpc-0cc3c139f96487cc0"
}

data "aws_subnet" "private1" {
  id = "subnet-00b7ff348bf4313f0"
}

data "aws_subnet" "private2" {
  id = "subnet-04885171f6bb0c980"
}

data "aws_subnet" "public1" {
  id = "subnet-02bcd6c250d6e284f"
}

data "aws_subnet" "public2" {
  id = "subnet-00b4aace2090ba378"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.14.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 3
    }
#    two = {
#      name = "node-group-2"
#
#      instance_types = ["t3.small"]
#
#      min_size     = 1
#      max_size     = 2
#      desired_size = 1
#    }
  }
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}
