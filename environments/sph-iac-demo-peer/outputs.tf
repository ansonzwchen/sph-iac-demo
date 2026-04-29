output "canary_object_key" {
  description = "After apply, search this key in COS console — note the path lives under tfc-canary/sph-iac-demo-peer/, never overlapping the sibling workspace."
  value       = module.canary.canary_object_key
}

output "canary_bucket_console_url" {
  description = "Same bucket as sibling workspace, different prefix — open and verify."
  value       = "https://console.cloud.tencent.com/cos/bucket?bucket=${var.demo_bucket}&region=${var.region}"
}
