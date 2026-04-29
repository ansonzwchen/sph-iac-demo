# ============================================================================
# Read the HCP-minted JWT out of the Run environment and expose it as a
# terraform data attribute consumable by the provider block.
#
# Why a data source and not a plain var:
#   - TF variables are set before plan starts; HCP injects TFC_* env vars only
#     INTO the Run sandbox, not into the Terraform variable space.
#   - `external` data source runs a script at refresh/plan time, reads env,
#     returns JSON. Provider config can consume it because provider
#     initialization happens after data sources are refreshed.
#
# The program below emits a JSON object {"jwt": "<token>"} so Terraform can
# pick it up via `.result["jwt"]`.
# ============================================================================
data "external" "tfc_jwt" {
  program = ["bash", "-c",
    "printf '{\"jwt\":\"%s\"}' \"$TFC_WORKLOAD_IDENTITY_TOKEN\""
  ]
}
