variable "region" {
  description = "Tencent Cloud region. Override via TFC env var TENCENTCLOUD_REGION if needed."
  type        = string
  default     = "ap-singapore"
}

variable "demo_bucket" {
  description = "Existing shared COS bucket — same physical bucket as sph-iac-demo, isolation is by CAM-policed prefix not by separate buckets."
  type        = string
  default     = "sph-demo-1365626084"
}

variable "workspace_tag" {
  description = "Workspace identity tag. MUST equal the TFC workspace name `sph-iac-demo-peer` and the workspace segment of OIDC sub."
  type        = string
  default     = "sph-iac-demo-peer"
}

variable "tfc_role_arn" {
  description = "CAM role assumed via TFC OIDC. Inject via TFC workspace env var TENCENTCLOUD_ASSUME_ROLE_ARN. Default is the peer role; intentionally NOT the demo role so a misconfigured workspace fails closed at trust-policy check."
  type        = string
  default     = "qcs::cam::uin/200043019381:roleName/TFCInfraDemoPeerRole"
}
