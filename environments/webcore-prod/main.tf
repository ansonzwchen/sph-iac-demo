# ============================================================================
# A deliberately tiny, visible, low-risk demo resource:
#   Write a timestamped canary object to the demo COS bucket.
#
# Why this resource:
#   - Visible: customer sees the object instantly in COS console.
#   - Cheap: object is < 100 bytes; rollback cost = 0.
#   - Stateful: terraform state file proves IaC is actually in control.
# ============================================================================
resource "tencentcloud_cos_bucket_object" "canary" {
  bucket  = var.demo_bucket
  key     = "tfc-canary/${var.workspace_tag}/${formatdate("YYYYMMDDhhmmss", timestamp())}.txt"
  content = "terraform-oidc-ok @ ${var.workspace_tag} @ ${timestamp()}"
  acl     = "private"
}
