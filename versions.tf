terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2"
    }
    uname = {
      source  = "julienlevasseur/uname"
      version = "0.2.3"
    }
  }
}
