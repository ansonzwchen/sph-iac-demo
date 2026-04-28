variable "region" {
  description = "Tencent Cloud region"
  type        = string
  default     = "ap-singapore"
}

variable "demo_bucket" {
  description = "Existing demo COS bucket. This plan only writes a small canary object to it."
  type        = string
  default     = "sph-demo-1365626084"
}

variable "workspace_tag" {
  description = "Used in canary object key for audit traceability."
  type        = string
  default     = "webcore-prod"
}
