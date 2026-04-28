# ============================================================================
# Remote state backend: Tencent COS, isolated per workspace by `prefix`.
# CAM policy further enforces per-workspace deny on sibling prefixes.
# ============================================================================
terraform {
  required_version = ">= 1.7.5"

  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.81"
    }
  }

  backend "cos" {
    region  = "ap-singapore"
    bucket  = "sph-demo-1365626084"
    prefix  = "tfstate/webcore-prod/"   # ← per-workspace prefix; CAM policy allows only this prefix and denies sibling ones
    acl     = "private"
    encrypt = true
  }
}
