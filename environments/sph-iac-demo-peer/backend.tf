terraform {
  required_version = ">= 1.7.5"

  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.81"
    }
  }

  # ============================================================================
  # COS remote backend for the `sph-iac-demo-peer` workspace.
  #
  # Identical structure to ../sph-iac-demo/backend.tf — only the workspace name
  # differs. This pair of backends is the load-bearing demonstration that COS
  # state is access-controlled per workspace: two TFC workspaces sharing the
  # SAME bucket but having STRICTLY non-overlapping prefixes, with the cross
  # access blocked at the CAM layer (see the explicit deny block in each
  # role's policy).
  # ============================================================================
  backend "cos" {
    region  = "ap-singapore"
    bucket  = "sph-demo-1365626084"
    prefix  = "tfstate/sph-iac-demo-peer/"
    acl     = "private"
    encrypt = true
  }
}
