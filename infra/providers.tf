terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
    awscc = {
      source = "opentofu/awscc"
      version = "1.100.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.terratest_tags
  }
}

provider "kubernetes" {
  host                   = module.copebit_terraform_eks.endpoint
  cluster_ca_certificate = base64decode(module.copebit_terraform_eks.certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.copebit_terraform_eks.cluster_name]
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.copebit_terraform_eks.endpoint
  cluster_ca_certificate = base64decode(module.copebit_terraform_eks.certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.copebit_terraform_eks.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.copebit_terraform_eks.endpoint
    cluster_ca_certificate = base64decode(module.copebit_terraform_eks.certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.copebit_terraform_eks.cluster_name]
    }
  }
}
