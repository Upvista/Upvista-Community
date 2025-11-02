# Security Guide - Best Practices & Implementation

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Complete Security Reference

---

## 🛡️ Security Features Overview

✅ bcrypt password hashing (cost 14)  
✅ JWT authentication with blacklisting  
✅ Rate limiting on sensitive endpoints  
✅ Email verification required  
✅ Session tracking with token hashing  
✅ Password verification for sensitive operations  
✅ OAuth CSRF protection (state parameter)  
✅ Email enumeration prevention  
✅ Secure token generation (crypto/rand)  
✅ HTTPS recommended (production)  
✅ CORS policy enforcement  
✅ Input validation at multiple layers  
✅ SQL injection prevention (PostgREST)  
✅ XSS protection (JWT, not cookies by default)  
✅ Automatic session expiry  

---

## 🔐 Authentication Security

### **Password Hashing (bcrypt)**

**Implementation:**
```go
// Cost 14 = 2^14 = 16,384 iterations
hash, _ := bcrypt.GenerateFromPassword([]byte(password), 14)
```

**Why bcrypt?**
- Adaptive cost (can increase as computers get faster)
- Built-in salt (prevents rainbow table attacks)
- Slow by design (prevents brute force)
- Industry standard for 20+ years

**Attack Resistance:**
- 🔴 Brute Force: Would take centuries with cost 14
- 🔴 Rainbow Tables: Impossible (salted)
- 🔴 Dictionary Attacks: Mitigated by slow hashing

---

### **JWT Token Security**

**Token Structure:**
```
Header: {"alg": "HS256", "typ": "JWT"}
Payload: {"user_id": "...", "email": "...", "exp": 1234567890}
Signature: HMACSHA256(header + payload, secret)
```

**Security Features:**
- ✅ Signed with strong secret (32+ chars)
- ✅ 15-minute expiry (short-lived)
- ✅ Blacklist on logout (can't reuse)
- ✅ Validated on every request
- ✅ Stateless (scalable)

**What Can Go Wrong & Mitigations:**
| Attack | Prevention |
|--------|-----------|
| Token Theft | Short expiry (15min), HTTPS only |
| Token Replay | Blacklist on logout |
| Weak Secret | Enforce 32+ char minimum |
| Token Forgery | HMAC signature validation |

---

## 🔒 Session Security

### **Token Hashing (SHA256)**

**Why hash tokens in database?**

**Scenario:** Database is compromised

**Without hashing:**
```
Attacker gets: "eyJhbGciOiJIUzI1NiIs..." (actual JWT)
Result: Can impersonate users immediately ❌
```

**With hashing:**
```
Attacker gets: "5f4dcc3b5aa765d61d8327deb882cf99..." (SHA256 hash)
Result: Can't reverse hash to get JWT ✅
```

**Implementation:**
```go
// On session creation:
tokenHash := SHA256(jwt_token)
sessionRepo.Create(userID, tokenHash, ...)

// On logout:
tokenHash := SHA256(incoming_token)
sessionRepo.DeleteByHash(tokenHash)
```

---

## 🚫 Rate Limiting

### **Configuration:**

| Endpoint | Limit | Window | Purpose |
|----------|-------|--------|---------|
| Login | 5 requests | 1 minute | Prevent brute force |
| Register | 3 requests | 1 minute | Prevent spam accounts |
| Password Reset | 3 requests | 1 minute | Prevent email bombing |

**Forgiveness Factor:** 2 (allows burst, then strict limit)

### **How It Works:**

```
User makes login attempt:
  ↓
Check: Requests in last minute?
  ├─ < 5: Allow ✅
  └─ ≥ 5: Block ❌ (return 429 Too Many Requests)
```

**Implementation:**
```go
// In-memory tracking (per IP address)
rateLimiter.Allow(ipAddress, endpoint, limit, window)
```

**Bypass:** Move to different IP (mitigated by account lockout after failed attempts in future versions)

---

## 📧 Email Security

### **Verification Code Security:**

- **6 digits:** 1,000,000 possibilities
- **1 hour expiry:** Reduces window for guessing
- **Single use:** Deleted after successful verification
- **Rate limited:** Can't spam verification requests

**Brute Force Resistance:**
- Try all codes: 1,000,000 attempts
- At 1 attempt/second: ~11.5 days
- With rate limiting: Impossible

---

### **Password Reset Security:**

**Token Generation:**
```go
// 32 bytes = 256 bits of randomness
bytes := make([]byte, 32)
crypto.Read(bytes)
token := hex.EncodeToString(bytes)
// Result: 64-character hex string
```

**Security:**
- Cryptographically random (not predictable)
- 1-hour expiry
- Single use (deleted after reset)
- Sent via email only (not SMS, not shown in UI)

**Email Enumeration Prevention:**
```go
// Always return success, don't reveal if email exists
if userNotFound {
    return success("If email exists, link sent")  // Same message!
}
```

**Why?** Prevents attackers from discovering which emails have accounts.

---

## 🔐 OAuth Security (CSRF Protection)

### **State Parameter Flow:**

```
1. User clicks "Login with Google"
   ↓
2. Backend generates random state:
   state = randomString(32)
   ↓
3. Frontend stores in sessionStorage:
   sessionStorage.setItem('oauth_state', state)
   ↓
4. Redirect to Google with state:
   https://accounts.google.com/...&state={state}
   ↓
5. Google redirects back with state:
   /callback?code=ABC&state={state}
   ↓
6. Frontend validates state matches:
   if (urlState !== sessionStorage.getItem('oauth_state')) {
       throw "CSRF attack detected!"
   }
   ↓
7. Exchange code for token
```

**What This Prevents:**
- CSRF attacks
- OAuth redirect hijacking
- Man-in-the-middle attacks

---

## 🛡️ Input Validation

### **Multiple Layers:**

```
Client Input: "user@example.com"
  ↓
1. Frontend Validation (optional, UX only)
   - Format check
   - Length check
   ↓
2. Handler Validation
   - JSON binding
   - Type checking
   ↓
3. Service Validation
   - Business rules
   - Email format
   - Normalization
   ↓
4. Repository Validation
   - SQL injection prevention (PostgREST)
   - Type safety
   ↓
5. Database Constraints
   - UNIQUE constraint
   - NOT NULL check
   - CHECK constraint (age >= 13)
```

**Why Multiple Layers?**
- Defense in depth
- Catch errors early
- Different concerns at each layer

---

## 🔴 Common Attack Vectors & Defenses

### **1. SQL Injection**

**Attack:**
```sql
-- Malicious input:
email = "'; DROP TABLE users; --"

-- Vulnerable code:
query = "SELECT * FROM users WHERE email = '" + email + "'"
-- Result: DROP TABLE users executed ❌
```

**Defense:**
✅ Using Supabase PostgREST (parameterized queries)  
✅ No raw SQL in application code  
✅ All queries via safe API

---

### **2. Brute Force Attacks**

**Attack:** Try many passwords until one works

**Defense:**
✅ Rate limiting (5 login attempts/minute)  
✅ bcrypt slow hashing (expensive to verify)  
✅ Account lockout (future: after N failed attempts)

---

### **3. Session Hijacking**

**Attack:** Steal user's session token

**Defense:**
✅ Short token expiry (15 minutes)  
✅ HTTPS only in production  
✅ Token blacklist on logout  
✅ Session tracking (user can see unauthorized logins)

---

### **4. Email Enumeration**

**Attack:** Discover which emails have accounts

**Defense:**
✅ Forgot password: Same response for existing/non-existing emails  
✅ Timing attacks prevented (consistent response times)

---

### **5. CSRF (Cross-Site Request Forgery)**

**Attack:** Trick user into making unauthorized requests

**Defense:**
✅ JWT in Authorization header (not cookies)  
✅ OAuth state parameter  
✅ SameSite cookies (if using cookies)

---

### **6. XSS (Cross-Site Scripting)**

**Attack:** Inject malicious JavaScript

**Defense:**
✅ JWT in localStorage/Authorization header (not in HTML)  
✅ JSON responses only (no HTML rendering)  
✅ Input sanitization

---

## ✅ Security Checklist (Production)

**Before deploying:**

- [ ] Change JWT_SECRET to strong, random value (48+ chars)
- [ ] Enable HTTPS/TLS (SSL certificate)
- [ ] Set strict CORS policy (production domain only)
- [ ] Use production Supabase project (not free tier for sensitive data)
- [ ] Enable Supabase RLS policies
- [ ] Use production SMTP (SendGrid/SES, not Gmail)
- [ ] Set GIN_MODE=release
- [ ] Disable debug endpoints (/test-db)
- [ ] Configure rate limiting appropriately
- [ ] Set up logging and monitoring
- [ ] Enable database backups
- [ ] Review all .env variables
- [ ] Use environment-specific secrets
- [ ] Enable firewall rules
- [ ] Set up intrusion detection
- [ ] Regular security audits

---

**Created by Hamza Hafeez - Founder & CEO of Upvista**

