variable "region" {
  description = "Tencent Cloud region. Override via TFC env var TENCENTCLOUD_REGION if needed."
  type        = string
  default     = "ap-singapore"
}

variable "demo_bucket" {
  description = "Existing shared COS bucket for both state backend and canary output. Per-workspace isolation is enforced via CAM policy paths, not separate buckets."
  type        = string
  default     = "sph-demo-1365626084"
}

variable "workspace_tag" {
  description = "Workspace identity tag. MUST equal the TFC workspace name and the workspace segment of OIDC sub. Hard-coded here so a stale TFC variable cannot silently shift the canary path away from what CAM policy allows."
  type        = string
  default     = "sph-iac-demo"
}

variable "tfc_role_arn" {
  description = "CAM role assumed via TFC OIDC. Inject via TFC workspace env var TENCENTCLOUD_ASSUME_ROLE_ARN to keep this file workspace-neutral."
  type        = string
  default     = "qcs::cam::uin/200043019381:roleName/TFCInfraDeployRole"
}
