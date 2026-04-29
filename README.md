# webcore-iac-tfc · LT#2 on HCP Terraform (alternative to GHA driven)

This is the Terraform project that proves Tencent Cloud satisfies the
customer's requirement *"Infrastructure provisioning (e.g., Terraform Cloud,
Pulumi Cloud) — assumes role for infra provisioning; state backend is
access-controlled per workspace"* — driven by **HCP Terraform** end-to-end
(plan/apply both run inside HCP's default runner; no self-hosted Agent).

This project is **parallel and independent** from the main GHA-driven project
under `webcore-iac/`. Both can coexist in the same Tencent Cloud sandbox
because they use different CAM IdPs and different CAM roles.

## How it satisfies the customer's requirement

| Customer requirement | This setup |
|----------------------|-----------|
| No static credentials | `provider.tf` has no `secret_id` / `secret_key`; HCP injects an OIDC JWT into the Run sandbox and the provider swaps it for <= 1h STS creds |
| OIDC Workload Identity Federation | HCP Terraform mints OIDC JWTs (signed by `app.terraform.io`); CAM IdP `TerraformCloud` validates them |
| **State backend access-controlled per workspace** | Two TFC workspaces (`sph-iac-demo`, `sph-iac-demo-peer`) sharing the same COS bucket but bound to **non-overlapping prefixes** + **distinct CAM roles** + **explicit cross-deny** in each role's policy. Customer can verify by browsing the bucket: each workspace only reads/writes its own prefix; even if a malicious operator forces the wrong role ARN into the wrong workspace, OIDC sub mismatch fails the assume-role call closed. |
| Assume role per pipeline run | Each TFC Run phase (plan/apply) gets a fresh JWT → fresh STS exchange |
| Plan / apply separation | Workspace `Apply Method = Manual apply` forces a human to click "Confirm & Apply" between plan and apply |

## Repository layout

```
webcore-iac-tfc/
├── README.md
├── modules/
│   └── webcore-canary/                    # business logic, shared by every env
│       ├── main.tf                        # tencentcloud_cos_bucket_object.canary
│       ├── variables.tf                   # demo_bucket, workspace_tag
│       └── outputs.tf
├── environments/
│   ├── sph-iac-demo/                      # Working Directory for TFC workspace `sph-iac-demo`
│   │   ├── backend.tf                     # COS prefix tfstate/sph-iac-demo/
│   │   ├── provider.tf                    # assume_role_with_web_identity (TFCInfraDeployRole)
│   │   ├── web_identity_wrap.tf           # `external` data source unwrapping the HCP JWT env var
│   │   ├── variables.tf                   # workspace_tag default = "sph-iac-demo"
│   │   ├── main.tf                        # 1-line module call
│   │   └── outputs.tf
│   └── sph-iac-demo-peer/                 # Working Directory for TFC workspace `sph-iac-demo-peer`
│       ├── backend.tf                     # COS prefix tfstate/sph-iac-demo-peer/
│       ├── provider.tf                    # assume_role_with_web_identity (TFCInfraDemoPeerRole)
│       ├── web_identity_wrap.tf
│       ├── variables.tf                   # workspace_tag default = "sph-iac-demo-peer"
│       ├── main.tf                        # IDENTICAL 1-line module call (intentional — see below)
│       └── outputs.tf
└── cam/
    ├── README.md
    ├── TFCInfraDeployRole.trust-policy.json     # demo role trust
    ├── sph-cos-tfc-policy.json                  # demo role permissions
    ├── TFCInfraDemoPeerRole.trust-policy.json   # peer role trust
    └── sph-cos-tfc-peer-policy.json             # peer role permissions
```

The two environment directories have **byte-identical `main.tf`** — the only
files that differ are `backend.tf` (different COS prefix), `variables.tf`
(different default tag and role ARN), and `provider.tf` (different
session_name for audit-log diffing). This is the demo's load-bearing point:
**business code is shared; per-workspace blast radius is enforced by identity**.

## Four-point name alignment (the demo's central invariant)

For each workspace, the same string must appear at exactly four hard-coded
sites; any single typo fails the run closed:

| Layer | Site | `sph-iac-demo` | `sph-iac-demo-peer` |
|-------|------|----------------|---------------------|
| Identity | OIDC sub workspace segment | `workspace:sph-iac-demo` | `workspace:sph-iac-demo-peer` |
| TFC | Workspace name | `sph-iac-demo` | `sph-iac-demo-peer` |
| Storage (state) | COS backend prefix | `tfstate/sph-iac-demo/` | `tfstate/sph-iac-demo-peer/` |
| Storage (workload) | COS canary prefix | `tfc-canary/sph-iac-demo/` | `tfc-canary/sph-iac-demo-peer/` |
| Authorization | CAM allow resource | `.../tfstate/sph-iac-demo/*` and `.../tfc-canary/sph-iac-demo/*` | `.../tfstate/sph-iac-demo-peer/*` and `.../tfc-canary/sph-iac-demo-peer/*` |
| Authorization | CAM deny resource | `<peer's two paths>` | `<demo's two paths>` |

Why hard-coded redundancy is a feature, not a bug:
- Terraform forbids variable use inside `backend` blocks (init runs before
  vars are loaded), so directory-per-workspace + literal prefix is canonical.
- The redundancy turns the workspace name into an **integrity contract**
  enforced at four independent layers: a single-character typo in any one
  layer causes init / assume-role / put-object to fail closed, never silent.

## One-time setup

See the companion document `SPH_Challenge1_LiveTest2_TFC_Alternative_v1.1.docx`
for the full step-by-step walkthrough. In short:

1. **HCP Terraform**: register account → organization `tencent-tfc` → project
   `sph-demo` → two workspaces `sph-iac-demo` and `sph-iac-demo-peer` (Version
   Control Workflow, Working Directory pointing at the corresponding
   `environments/<workspace-name>/` directory, Apply Method = Manual,
   Terraform Version 1.7.5+).
2. **Per-workspace HCP Variables** (4 environment variables, none sensitive):
   - `TFC_WORKLOAD_IDENTITY_AUDIENCE = tfc.cloud.tencent.com`
   - `TENCENTCLOUD_REGION = ap-singapore`
   - `TENCENTCLOUD_ASSUME_ROLE_PROVIDER_ID = TerraformCloud`
   - `TENCENTCLOUD_ASSUME_ROLE_ARN`
     - In `sph-iac-demo` workspace: `qcs::cam::uin/200043019381:roleName/TFCInfraDeployRole`
     - In `sph-iac-demo-peer` workspace: `qcs::cam::uin/200043019381:roleName/TFCInfraDemoPeerRole`
3. **Tencent Cloud CAM**:
   - Create OIDC IdP `TerraformCloud` once (issuer `https://app.terraform.io`,
     Client ID `tfc.cloud.tencent.com`, paste 4 PEMs converted from
     `https://app.terraform.io/.well-known/jwks`).
   - Create role `TFCInfraDeployRole` with the trust policy in
     `cam/TFCInfraDeployRole.trust-policy.json`, attach the resource policy
     `cam/sph-cos-tfc-policy.json`.
   - Create role `TFCInfraDemoPeerRole` with the trust policy in
     `cam/TFCInfraDemoPeerRole.trust-policy.json`, attach the resource policy
     `cam/sph-cos-tfc-peer-policy.json`.

## Live demo script (5 minutes)

| Step | Action | What customer sees |
|------|--------|--------------------|
| 1 | Open TFC workspace `sph-iac-demo` → Actions → Start new run → Confirm & Apply | `Apply complete! 1 added, 0 changed, 1 destroyed` (canary object created) |
| 2 | Open COS console → bucket `sph-demo-1365626084` → drill into `tfc-canary/sph-iac-demo/` | Exactly one timestamped `.txt` from this run; `tfstate/sph-iac-demo/` holds the state file |
| 3 | Switch to TFC workspace `sph-iac-demo-peer` → Start new run → Confirm & Apply | Same `Apply complete!`, but on a different role |
| 4 | Back to COS console → drill into `tfc-canary/sph-iac-demo-peer/` and `tfstate/sph-iac-demo-peer/` | Files exist under peer's prefixes, ZERO files under sibling's — physical proof of per-workspace isolation |
| 5 | Open CAM console → role `TFCInfraDeployRole` → policy `sph-cos-tfc-policy` → JSON view | Show `AllowOwnWorkspaceState` (only `tfstate/sph-iac-demo/*`) + `DenySiblingWorkspaceCrossAccess` (explicit deny on peer's paths) |

Closing line: *"两个 workspace 共享同一个 COS 桶但完全不互通，state、工作负载、信任关系三层都按 workspace 隔离 —— 这就是客户原文要求的 state backend access-controlled per workspace。"*

## Coexistence with the main GHA-driven project

This project's CAM resources do NOT collide with `webcore-iac/`'s:

| Resource | This project (TFC) | Main project (GHA) |
|----------|--------------------|--------------------|
| OIDC IdP | `TerraformCloud` | `GitHubActions` |
| CAM roles | `TFCInfraDeployRole`, `TFCInfraDemoPeerRole` | `GitHubInfraDeployRole`, etc. |
| State prefixes | `tfstate/sph-iac-demo/`, `tfstate/sph-iac-demo-peer/` | `tfstate/webcore-prod/` |

State prefixes intentionally do NOT overlap — TFC and GHA demos own different
state files and never compete for the same lock.
