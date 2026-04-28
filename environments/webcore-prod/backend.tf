terraform {
  required_version = ">= 1.7.5"

  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.81" # v1.81.111+ required for assume_role_with_web_identity
    }
  }

  backend "cos" {
    region  = "ap-singapore"
    bucket  = "sph-demo-1365626084"
    prefix  = "tfstate/sph-iac-demo/"
    acl     = "private"
    encrypt = true
  }
}
