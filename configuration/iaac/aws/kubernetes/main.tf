# aws --version
# aws eks --region us-east-1 update-kubeconfig --name in28minutes-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-in28minutes-123
# AKIA4AHVNOD7OOO6T4KI


terraform {
  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "eu-north-1"
  }
}

resource "aws_default_vpc" "default" {

}

# data "aws_subnet_ids" "subnets" {
#   vpc_id = aws_default_vpc.default.id
# }

data "aws_eks_cluster" "cluster" { 
  name = "my-cluster_in_aws_eks"
}

data "aws_eks_cluster_auth" "cluster" { 
  name = "my-cluster_in_aws_eks"
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
#   load_config_file       = false
 # version                = "~> 1.21"
}

# module "my-cluster" {
#   source          =  "terraform-aws-modules/eks/aws"
#   cluster_name    = "local.my-cluster"
#   cluster_version = "1.14"

module "my-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-cluster_in_aws_eks"
#   cluster_version = "1.14"
  subnet_ids = ["subnet-02936de47e6a8ed9a", "subnet-0b49263fc566e6873"] 
  #subnets         = ["subnet-01f9ebf3562398329", "subnet-0291156351ccb436b"] #CHANGE
  #subnets = data.aws_subnet_ids.subnets.ids
  vpc_id          = aws_default_vpc.default.id

  #vpc_id         = "vpc-1234556abcdef"

#   node_groups = [
  eks_managed_node_groups = {
    one = {
      instance_type = "t2.micro"
      max_capacity  = 5
      desired_capacity = 3
      min_capacity  = 3
    }
  }
}



# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments 
# and services in default namespace
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }
}

# Needed to set the default region
provider "aws" {
  region  = "eu-north-1"
}
