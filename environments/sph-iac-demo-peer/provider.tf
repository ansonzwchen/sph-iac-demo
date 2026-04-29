# ============================================================================
# Provider for the peer workspace. Same OIDC plumbing as sph-iac-demo, only
# session_name differs to ease audit-log diffing in CloudAudit.
#
# IMPORTANT: var.tfc_role_arn defaults to TFCInfraDemoPeerRole here (NOT the
# demo role). It will be overridden by the TFC env var
# TENCENTCLOUD_ASSUME_ROLE_ARN in the peer workspace, which MUST be set to the
# peer role ARN. If left to the default, the role's CAM trust policy still
# rejects the assume-role attempt because oidc:sub will not match — fail-close.
# ============================================================================
provider "tencentcloud" {
  region = var.region

  assume_role_with_web_identity {
    provider_id        = "TerraformCloud"
    role_arn           = var.tfc_role_arn
    session_name       = "tfc_sph_iac_demo_peer"
    session_duration   = 3600
    web_identity_token = data.external.tfc_jwt.result["jwt"]
  }
}
