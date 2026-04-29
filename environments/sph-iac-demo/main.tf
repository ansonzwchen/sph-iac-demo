# ============================================================================
# Environment composition for workspace `sph-iac-demo`.
# Business logic lives in ../../modules/webcore-canary; this file only wires
# inputs. Identical structure to ../sph-iac-demo-peer/main.tf — only inputs
# differ, proving "code is the same, blast radius is enforced by identity".
# ============================================================================
module "canary" {
  source = "../../modules/webcore-canary"

  demo_bucket   = var.demo_bucket
  workspace_tag = var.workspace_tag
}
