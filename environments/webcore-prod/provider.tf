# ============================================================================
# Provider — HCP Terraform OIDC Workload Identity Federation
#
# When the TFC workspace sets:
#   TFC_WORKLOAD_IDENTITY_AUDIENCE = tfc.cloud.tencent.com
# HCP auto-mints a short-lived OIDC JWT for every Run phase (plan/apply) with
# that audience and exposes it in the Run sandbox env:
#   TFC_WORKLOAD_IDENTITY_TOKEN      = <the JWT, bare string>
#   TFC_WORKLOAD_IDENTITY_TOKEN_PATH = <path to a file holding the JWT>
#
# tencentcloud provider (v1.81.111+) supports `assume_role_with_web_identity`
# block natively. It calls sts:AssumeRoleWithWebIdentity on the Tencent Cloud
# STS endpoint, passing the JWT, target role ARN, and IdP name; STS validates
# the JWT signature against the public keys stored on CAM OIDC provider
# "TerraformCloud" and returns short-lived AK/SK/Token (≤ 1h) used for all
# subsequent provider API calls.
# ============================================================================
provider "tencentcloud" {
  region = var.region

  assume_role_with_web_identity {
    provider_id        = "TerraformCloud"
    role_arn           = var.tfc_role_arn
    session_name       = "tfc-${terraform.workspace}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
    session_duration   = 3600
    web_identity_token = data.external.tfc_jwt.result["jwt"]
  }
}
