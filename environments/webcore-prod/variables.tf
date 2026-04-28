variable "region" {
  description = "Tencent Cloud region"
  type        = string
  default     = "ap-singapore"
}

variable "demo_bucket" {
  description = "Existing COS bucket for both state backend and canary output"
  type        = string
  default     = "sph-demo-1365626084"
}

variable "workspace_tag" {
  description = "Tag used in canary key for audit traceability. Must match TFC workspace name (and the workspace segment in OIDC sub claim) so a single identity string flows through identity, state path, and workload path."
  type        = string
  default     = "sph-iac-demo"
}

variable "tfc_role_arn" {
  description = "CAM role to assume via TFC OIDC. See doc §3.5."
  type        = string
  default     = "qcs::cam::uin/200043019381:roleName/TFCInfraDeployRole"
}
