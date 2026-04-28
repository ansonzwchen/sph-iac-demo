output "canary_object_key" {
  description = "After apply, search this key in COS console to verify."
  value       = tencentcloud_cos_bucket_object.canary.key
}

output "canary_bucket_console_url" {
  description = "Click to open the bucket directly in Tencent Cloud console."
  value       = "https://console.cloud.tencent.com/cos/bucket?bucket=${var.demo_bucket}&region=${var.region}"
}
