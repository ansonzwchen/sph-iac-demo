# Identical to ../sph-iac-demo/web_identity_wrap.tf. See that file for the
# rationale on using a `data "external"` source to surface the HCP-injected
# TFC_WORKLOAD_IDENTITY_TOKEN env var into terraform's value space.
data "external" "tfc_jwt" {
  program = ["bash", "-c",
    "printf '{\"jwt\":\"%s\"}' \"$TFC_WORKLOAD_IDENTITY_TOKEN\""
  ]
}
