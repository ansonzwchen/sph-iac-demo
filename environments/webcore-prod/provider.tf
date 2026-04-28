# ============================================================================
# Provider — NO static credentials.
# Reads short-lived TENCENTCLOUD_SECRET_ID / SECRET_KEY / SECURITY_TOKEN from
# the environment. In our setup these are written into $GITHUB_ENV by the
# "Exchange OIDC token" step in .github/workflows/terraform.yml.
# ============================================================================
provider "tencentcloud" {
  region = var.region
  # secret_id / secret_key are deliberately NOT set here.
  # Provider auto-reads:
  #   TENCENTCLOUD_SECRET_ID
  #   TENCENTCLOUD_SECRET_KEY
  #   TENCENTCLOUD_SECURITY_TOKEN
}
