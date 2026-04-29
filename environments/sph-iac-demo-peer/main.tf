# ============================================================================
# Environment composition for workspace `sph-iac-demo-peer`.
#
# DIFF AGAINST ../sph-iac-demo/main.tf: ZERO lines.
# Everything that distinguishes peer from demo lives in:
#   1. backend.tf prefix (different COS path)
#   2. variables.tf workspace_tag default (different CAM-allowed path)
#   3. TFC workspace name + OIDC sub (different identity)
#   4. The CAM role this workspace is allowed to assume (different blast radius)
#
# This intentional code-identity is the demo's load-bearing point: the
# customer requirement "state backend access-controlled per workspace" is
# satisfied by the IDENTITY layer, not by the application code.
# ============================================================================
module "canary" {
  source = "../../modules/webcore-canary"

  demo_bucket   = var.demo_bucket
  workspace_tag = var.workspace_tag
}
