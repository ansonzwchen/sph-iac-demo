#!/usr/bin/env python3
"""Exchange a GitHub OIDC token for Tencent Cloud STS temporary credentials.

All environment-specific values are injected via env vars from the GitHub
Actions workflow:

    OIDC_TOKEN                  GitHub OIDC JWT (set by previous step)
    TENCENTCLOUD_UIN            Account UIN, e.g. 200043019381
    TENCENTCLOUD_ROLE_NAME      CAM role name, e.g. GitHubDeployRole
    TENCENTCLOUD_PROVIDER_NAME  CAM OIDC provider name, e.g. GitHubActions
    TENCENTCLOUD_REGION         e.g. ap-singapore
    TENCENTCLOUD_DURATION_SEC   optional, default 3600

stdout (3 lines, easy to capture with sed -n 'Np'):
    line 1 = TmpSecretId
    line 2 = TmpSecretKey
    line 3 = Token

stderr:
    "Credentials expire at: <CST timestamp>"
"""

import json
import os
import sys
import time
import http.client
from datetime import datetime, timezone, timedelta


def env(name: str, required: bool = True, default: str = "") -> str:
    val = os.environ.get(name, default)
    if required and not val:
        print(f"ERROR: required env var {name} is missing", file=sys.stderr)
        sys.exit(2)
    return val


# ---- Read all config from env -------------------------------------------------
oidc_token    = env("OIDC_TOKEN")
uin           = env("TENCENTCLOUD_UIN")
role_name     = env("TENCENTCLOUD_ROLE_NAME")
provider_name = env("TENCENTCLOUD_PROVIDER_NAME")
region        = env("TENCENTCLOUD_REGION")
duration_sec  = int(env("TENCENTCLOUD_DURATION_SEC", required=False, default="3600"))

# ARN derived from UIN + RoleName, keeps script env-agnostic
role_arn = f"qcs::cam::uin/{uin}:roleName/{role_name}"

# ---- Build STS request --------------------------------------------------------
payload = json.dumps({
    "WebIdentityToken": oidc_token,
    "RoleArn":          role_arn,
    "ProviderId":       provider_name,
    "RoleSessionName":  role_name,        # mirrors role for easy audit lookup
    "DurationSeconds":  duration_sec,
})
payload_bytes = payload.encode("utf-8")

headers = {
    "Content-Type":   "application/json; charset=utf-8",
    "Content-Length": str(len(payload_bytes)),
    "X-TC-Action":    "AssumeRoleWithWebIdentity",
    "X-TC-Version":   "2018-08-13",
    "X-TC-Region":    region,
    "X-TC-Timestamp": str(int(time.time())),
    # OIDC federation: STS validates the OIDC JWT signature; client signing
    # is intentionally skipped.
    "Authorization":  "SKIP",
    "Host":           "sts.tencentcloudapi.com",
}

conn = http.client.HTTPSConnection("sts.tencentcloudapi.com", timeout=15)
conn.request("POST", "/", body=payload_bytes, headers=headers)
resp = conn.getresponse()
data = json.loads(resp.read().decode("utf-8"))
conn.close()

if "Error" in data.get("Response", {}):
    err = data["Response"]["Error"]
    print(f"STS ERROR: {err.get('Code')} - {err.get('Message')}", file=sys.stderr)
    print(f"RoleArn used: {role_arn}", file=sys.stderr)
    sys.exit(1)

creds = data["Response"]["Credentials"]
expiration = data["Response"].get("Expiration", "N/A")

# ---- Output (must be exactly 3 lines on stdout) ------------------------------
print(creds["TmpSecretId"])
print(creds["TmpSecretKey"])
print(creds["Token"])

if expiration != "N/A":
    expire_utc = datetime.fromisoformat(expiration.replace("Z", "+00:00"))
    expire_cst = expire_utc.astimezone(timezone(timedelta(hours=8)))
    print(f"Credentials expire at: {expire_cst.strftime('%Y-%m-%d %H:%M:%S')} CST",
          file=sys.stderr)
else:
    print("Credentials expire at: N/A", file=sys.stderr)
