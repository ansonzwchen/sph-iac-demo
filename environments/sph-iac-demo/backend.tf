terraform {
  required_version = ">= 1.7.5"

  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.81" # v1.81.111+ required for assume_role_with_web_identity
    }
  }

  # ============================================================================
  # COS remote backend for the `sph-iac-demo` workspace.
  #
  # The `prefix` is hard-coded to the workspace name. Terraform forbids using
  # any variable, local or expression inside a backend block (init runs before
  # variables are loaded), so directory-per-workspace + literal prefix is the
  # canonical pattern. This redundancy is a feature, not a bug — it forces the
  # workspace name to be hard-coded in four independent places (OIDC sub claim,
  # CAM policy resource path, this prefix, and the directory name itself), so a
  # single typo fails closed at init time instead of silently crossing scopes.
  # ============================================================================
  backend "cos" {
    region  = "ap-singapore"
    bucket  = "sph-demo-1365626084"
    prefix  = "tfstate/sph-iac-demo/"
    acl     = "private"
    encrypt = true
  }
}
