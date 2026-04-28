# webcore-iac · GitHub Actions Terraform demo for SPH Pitch (LT#2)

Terraform project that proves Tencent Cloud satisfies the customer's
requirement *"Infrastructure Provisioning — OIDC Workload Identity Federation
→ assumes role for infra provisioning; state backend is access-controlled per
workspace"*. Same OIDC link as LT#1, but driven by **GitHub Actions** end to
end (`terraform init / plan / apply` all run inside the GHA runner).

## Why this satisfies the customer's requirement

| Customer requirement | This setup |
|----------------------|-----------|
| No static credentials | `provider.tf` has no `secret_id` / `secret_key`; runner only ever holds short-lived (≤ 1h) STS creds in `$GITHUB_ENV` |
| OIDC Workload Identity Federation | `terraform.yml` runs `sts_oidc.py` per job → AssumeRoleWithWebIdentity → fresh creds |
| State backend access-controlled per workspace | COS backend `prefix = "tfstate/<workspace>/"` + CAM policy denies access to sibling workspace prefixes |
| Assume role per pipeline run | Each PR/push triggers a fresh job; new OIDC JWT → new STS exchange → new creds |
| Plan / apply separation | PR triggers `plan` only (posted as PR comment); push to `main` triggers `apply` gated by environment `prod` (required reviewer) |

## Files

```
webcore-iac/
├── README.md
├── .github/
│   └── workflows/
│       └── terraform.yml         # GHA workflow: PR=plan, push main=apply
├── environments/
│   └── webcore-prod/
│       ├── backend.tf            # COS backend, prefix per workspace
│       ├── provider.tf           # No static keys (reads env)
│       ├── variables.tf
│       ├── main.tf               # Tiny canary COS object resource
│       ├── outputs.tf            # Direct console links after apply
│       └── terraform.tfvars
└── scripts/
    └── sts_oidc.py               # Same script as LT#1; OIDC → STS exchange
```

## One-time setup

1. CAM IdP `GitHubActions`, role `GitHubDeployRole`, and bucket
   `sph-demo-1365626084` already exist in account UIN `200043019381` /
   region `ap-singapore` (created in LT#1's §3.2 / §3.3).
2. Append `tfstate/webcore-prod/*` and `tfc-canary/webcore-prod/*` to the
   role's COS policy resource list (see §5.5 Step 4 of the verification doc).
3. Repo Settings → Environments → create environment `prod` with at least
   one required reviewer. This gates `terraform apply`.
4. Repo Settings → Secrets and variables → Actions: confirm
   **No repository / environment secrets** — same as LT#1.

## Per-run usage

```bash
# Developer flow:
git checkout -b feat/canary-update
# ... edit environments/webcore-prod/*.tf ...
git push origin feat/canary-update
# Open PR → GHA runs `terraform plan` → diff posted as PR comment.

# Reviewer approves PR → merge to main → GHA runs `terraform apply`.
# (apply waits for environment `prod` reviewer to click Approve.)
```

After apply, GHA logs show `Apply complete!` and `terraform output` prints
the canary object key + a direct COS console URL.

The same `backend.tf` / `provider.tf` would work unchanged on Terraform Cloud
or any other CI runner — execution location is decoupled from the security
model. We picked GitHub Actions because the customer already runs LT#1 there
and reusing the OIDC link keeps the trust footprint at exactly one IdP.
