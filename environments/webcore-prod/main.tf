# ============================================================================
# A deliberately tiny, visible, low-risk demo resource:
#   Write a timestamped canary object to the demo COS bucket.
#
# Identical to main doc v1.10's webcore-iac/environments/webcore-prod/main.tf
# — proving "execution location decoupled from security model".
# ============================================================================
resource "tencentcloud_cos_bucket_object" "canary" {
  bucket  = var.demo_bucket
  key     = "tfc-canary/${var.workspace_tag}/${formatdate("YYYYMMDDhhmmss", timestamp())}.txt"
  content = "terraform-oidc-tfc-ok @ ${var.workspace_tag} @ ${timestamp()}"
  acl     = "private"
}
