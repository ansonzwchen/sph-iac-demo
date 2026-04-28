# webcore-iac-tfc · LT#2 on HCP Terraform (alternative to GHA driven)

This is the Terraform project that proves Tencent Cloud satisfies the
customer's requirement *"Infrastructure provisioning (e.g., Terraform Cloud,
Pulumi Cloud) — assumes role for infra provisioning; state backend is
access-controlled per workspace"* — driven by **HCP Terraform** end-to-end
(plan/apply both run inside HCP's default runner; no self-hosted Agent).

This project is **parallel and independent** to the main GHA-driven project
under `webcore-iac/`. Both can coexist in the same Tencent Cloud sandbox
because they use different CAM IdPs and different CAM roles.

## How it satisfies the customer's requirement

| Customer requirement | This setup |
|----------------------|-----------|
| No static credentials | `provider.tf` has no `secret_id` / `secret_key`; HCP injects an OIDC JWT into the Run sandbox and the provider swaps it for ≤ 1h STS creds |
| OIDC Workload Identity Federation | HCP Terraform mints OIDC JWTs (signed by `app.terraform.io`); CAM IdP `TerraformCloud` validates them |
| State backend access-controlled per workspace | (1) HCP workspace state isolation + (2) COS backend `prefix=tfstate/webcore-prod/` + (3) CAM policy denies sibling workspace prefixes — triple defense |
| Assume role per pipeline run | Each TFC Run phase (plan/apply) gets a fresh JWT → fresh STS exchange |
| Plan / apply separation | Workspace `Apply Method = Manual apply` forces a human to click "Confirm & Apply" between plan and apply |

## Files

```
webcore-iac-tfc/
├── README.md
└── environments/
    └── webcore-prod/
        ├── backend.tf            # COS backend, prefix per workspace
        ├── provider.tf           # assume_role_with_web_identity block
        ├── web_identity_wrap.tf  # `external` data source unwrapping the HCP JWT env var
        ├── variables.tf          # region / demo_bucket / workspace_tag / tfc_role_arn
        ├── main.tf               # canary COS object resource
        ├── outputs.tf            # canary key + console URL
        └── terraform.tfvars      # non-sensitive default values
```

## One-time setup

See the companion document `SPH_Challenge1_LiveTest2_TFC_Alternative_v1.0.docx`
for a full step-by-step walkthrough. In short:

1. **HCP**: register account → create organization `<your-hcp-org>` → project
   `sph-pitch-2026` → workspace `webcore-prod` (Version Control Workflow,
   Working Directory `environments/webcore-prod`, Apply Method = Manual,
   Terraform Version 1.7.5).
2. **HCP workspace Variables** (4 environment variables, none sensitive):
   - `TFC_WORKLOAD_IDENTITY_AUDIENCE = tfc.cloud.tencent.com`
   - `TENCENTCLOUD_REGION = ap-singapore`
   - `TENCENTCLOUD_ASSUME_ROLE_ARN = qcs::cam::uin/200043019381:roleName/TFCInfraDeployRole`
   - `TENCENTCLOUD_ASSUME_ROLE_PROVIDER_ID = TerraformCloud`
3. **Tencent Cloud CAM**: create OIDC IdP `TerraformCloud`
   (`https://app.terraform.io`, Client ID `tfc.cloud.tencent.com`, JWKS PEM
   pasted from `https://app.terraform.io/.well-known/jwks`).
4. **Tencent Cloud CAM**: create role `TFCInfraDeployRole` trusting the
   `TerraformCloud` IdP, with `oidc:sub` matching
   `organization:<your-hcp-org>:project:sph-pitch-2026:workspace:webcore-prod:run_phase:*`,
   and a COS policy allowing `tfstate/webcore-prod/*` + `tfc-canary/webcore-prod/*`
   plus an explicit deny on sibling workspaces.

## Per-run usage

```bash
git checkout main
# ... edit environments/webcore-prod/*.tf ...
git push origin main
# HCP detects the push within 30s, spawns a Run, runs `terraform plan`,
# posts plan output to the TFC Run UI, waits for a reviewer to click
# "Confirm & Apply" → runs `terraform apply`.
```

After apply, TFC Run UI shows `Apply complete!` and the Outputs tab gives
the canary object key + a direct COS console URL.

## Coexistence with the main GHA-driven project

This project's CAM resources do NOT collide with `webcore-iac/`'s:

| Resource | This project (TFC) | Main project (GHA) |
|----------|--------------------|--------------------|
| OIDC IdP | `TerraformCloud` | `GitHubActions` |
| CAM role | `TFCInfraDeployRole` | `GitHubInfraDeployRole` |
| State prefix | `tfstate/webcore-prod/` | `tfstate/webcore-prod/` (same!) |

The state prefix is intentionally the same — both projects target the same
real infrastructure, so they share state. **Only one project should be active
at a time** (i.e. don't run TFC and GHA workflows on the same workspace
simultaneously). Switching is safe: stop one, run the other.
