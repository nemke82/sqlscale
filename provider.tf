terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.40.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.27.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.11.2"
    }

  }
}

provider "aws" {
  # Configuration options
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }

}
