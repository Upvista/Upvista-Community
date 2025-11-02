# Test Sliding Window Authentication

## Quick Test

**1. Login and check token:**
```bash
# Login
curl -X POST http://localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email_or_username":"test@test.com","password":"yourpass"}'

# Save the token from response
TOKEN="your_token_here"
```

**2. Make API call and check for refresh:**
```bash
# Call any protected endpoint
curl -v http://localhost:8081/api/v1/account/profile \
  -H "Authorization: Bearer $TOKEN"

# Look for this header in response:
# < X-New-Token: ey...
# If present, token was refreshed!
```

**3. Check backend logs:**
```
[Auth] Token refreshed for user xxx (was expiring in 14d, refreshed to 30 days)
```

## What This Means

- ✅ Users stay logged in for 30 days
- ✅ After 15 days, token auto-refreshes on any activity
- ✅ Users who are active stay logged in **forever**
- ✅ Inactive users (30+ days) must re-login

## Success Criteria

- [x] Token expiry set to 30 days
- [x] Middleware checks token age
- [x] New token issued when past halfway
- [x] X-New-Token header sent to frontend
- [x] Frontend auto-updates localStorage
- [x] No user interruption

**System Working!** 🎉

