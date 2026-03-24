#!/usr/bin/env python3
"""Create a test customer user in FusionAuth marketexpress-store app."""
import json, subprocess, uuid

FA_BASE = "https://auth.marketexpress.us"
FA_KEY  = "gr27wF8Uv4jyaFompddrHoPrZMcHvYuAaZozSl6YBErjkDnu947PW8Yn0tFo0tmL"
STORE_APP_ID = "9fb71511-a59b-422b-bcb1-b7f5e5bb28d9"
TENANT_ID    = "d7d09513-a3f5-401c-9685-34ab6c552453"

def fa(method, path, data=None):
    cmd = ["curl", "-sk", "-X", method, f"{FA_BASE}{path}",
           "-H", f"Authorization: {FA_KEY}",
           "-H", "Content-Type: application/json"]
    if data:
        cmd += ["-d", json.dumps(data)]
    r = subprocess.run(cmd, capture_output=True, timeout=20)
    try:
        return json.loads(r.stdout.decode())
    except:
        return {"_raw": r.stdout.decode()[:200]}

user_id = str(uuid.uuid4())
print(f"Creating test customer: test-customer@marketexpress.us")
print(f"User ID: {user_id}")

r = fa("POST", f"/api/user/registration/{user_id}", {
    "user": {
        "id": user_id,
        "email": "test-customer@marketexpress.us",
        "password": "TestCustomer2026!",
        "firstName": "Test",
        "lastName": "Customer",
        "tenantId": TENANT_ID,
        "active": True,
        "verified": True,
    },
    "registration": {
        "applicationId": STORE_APP_ID,
        "roles": ["customer"],
    },
    "sendSetPasswordEmail": False,
    "skipVerification": True,
})

u = r.get("user", {})
reg = r.get("registration", {})
print(f"User created: {u.get('id','?')[:8] if u else 'FAILED'}")
print(f"Registration: {reg.get('applicationId','?')[:8] if reg else 'N/A'}")
if r.get("fieldErrors"):
    print(f"Errors: {r['fieldErrors']}")

# Test login
print("\nTesting customer login...")
r2 = fa("POST", "/api/login", {
    "loginId": "test-customer@marketexpress.us",
    "password": "TestCustomer2026!",
    "applicationId": STORE_APP_ID,
})
token = r2.get("token", "")
print(f"Token: {'YES '+token[:30]+'...' if token else 'FAIL: '+str(r2)[:150]}")

print("\n=== Test Customer ===")
print(f"Email:    test-customer@marketexpress.us")
print(f"Password: TestCustomer2026!")
print(f"App:      marketexpress-store ({STORE_APP_ID})")
print(f"Role:     customer")
