# ============================================================================
# Canary resource — write a timestamped object to the shared COS bucket to
# prove the OIDC -> STS -> COS chain works end-to-end.
#
# DIFF AGAINST ../sph-iac-demo-peer/main.tf: ZERO lines.
# This intentional code-identity is the demo's load-bearing point: the
# customer requirement "state backend access-controlled per workspace" is
# satisfied by the IDENTITY layer (OIDC sub claim + CAM trust policy + CAM
# resource policy), not by the application code.
#
# Per-workspace blast radius is enforced by:
#   - backend.tf  prefix    -> different COS state path per workspace
#   - var.workspace_tag     -> different COS canary path per workspace
#   - var.tfc_role_arn      -> different CAM role per workspace
#   - CAM trust policy      -> oidc:sub locked to this workspace name
#   - CAM resource policy   -> allow own paths + explicit deny on sibling paths
#
# Each apply destroys-and-recreates the canary because key contains timestamp()
# (a ForceNew field). This is intentional: a single apply exercises five COS
# actions (PutObject / GetObject / HeadObject / GetObjectACL / DeleteObject),
# proving the assumed short-lived role covers the full object lifecycle.
# ============================================================================
resource "tencentcloud_cos_bucket_object" "canary" {
  bucket  = var.demo_bucket
  key     = "tfc-canary/${var.workspace_tag}/${formatdate("YYYYMMDDhhmmss", timestamp())}.txt"
  content = "terraform-oidc-tfc-ok @ ${var.workspace_tag} @ ${timestamp()}"
  acl     = "private"
}
