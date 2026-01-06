terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }


  backend "s3" {
    bucket       = "remote-state-venkatesh-dev"
    key          = "dev-iam"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }

}


# Configure the AWS Provider with a specific region
provider "aws" {
  region = "us-east-1"

}






