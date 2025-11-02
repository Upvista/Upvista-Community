# Troubleshooting Guide

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Common Issues & Solutions

---

## 🔧 Quick Diagnostics

### **Server Won't Start**

**Error:** "Port already in use"
```bash
# Find and kill process:
# Windows:
netstat -ano | findstr :8081
taskkill /PID <PID> /F

# Mac/Linux:
lsof -i :8081
kill -9 <PID>

# Or change port:
PORT=8082 go run main.go
```

**Error:** "Failed to load config"
- Check `.env` file exists
- Verify all required variables set
- Check for typos in variable names

---

## 🗄️ Database Issues

**Error:** "Database connection failed"

**Solutions:**
1. Verify `SUPABASE_URL` includes `https://`
2. Use `service_role` key, not `anon` key
3. Check Supabase project is not paused
4. Test connection: `curl http://localhost:8081/api/v1/test-db`

**Error:** "null value in column violates not-null constraint"
- Run latest migration script
- Check all required columns exist
- Verify migration completed successfully

---

## 📧 Email Problems

**Emails Not Sending:**

1. **Gmail:**
   - Use App Password, not regular password
   - Enable 2-Step Verification first
   - Check spam folder
   - Verify SMTP credentials

2. **SendGrid:**
   - Verify sender identity
   - Check API key is valid
   - Username must be literally "apikey"
   - From email must be verified

**Emails Going to Spam:**
- Add SPF/DKIM records
- Use verified domain
- Avoid spammy content
- Use professional email provider

---

## 🔐 Authentication Errors

**"Invalid credentials":**
- Check password is correct
- Verify email/username exists
- Check account is active (`is_active = true`)
- Verify email is verified (`is_email_verified = true`)

**"Token expired":**
- Tokens expire after 15 minutes
- Use refresh endpoint to get new token
- Or re-login

**"Unauthorized":**
- Token missing or invalid
- Token blacklisted (after logout)
- Check Authorization header format: `Bearer <token>`

---

## 🌐 OAuth Issues

**"Invalid state parameter":**
- State mismatch (CSRF protection)
- Clear sessionStorage and try again
- Check redirect URLs match exactly

**"redirect_uri mismatch":**
- Verify redirect URL in OAuth app settings
- Must match exactly (no trailing slash)
- Check http vs https

---

## ⚠️ Rate Limiting

**"Too many requests" (429):**
- Wait 1 minute
- You've exceeded rate limit
- Default limits:
  - Login: 5/minute
  - Register: 3/minute
  - Reset: 3/minute

---

## 🐛 Common Mistakes

❌ Using `anon` key instead of `service_role` key  
❌ Gmail password instead of App Password  
❌ Forgetting to run migration  
❌ Wrong redirect URL for OAuth  
❌ JWT_SECRET too short (< 32 chars)  
❌ Not enabling 2-Step Verification for Gmail  

---

**Created by Hamza Hafeez - Founder & CEO of Upvista**

