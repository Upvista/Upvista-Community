# Configuration Reference

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Complete Environment Variable Reference

---

## 📋 All Environment Variables

### **Required Variables:**

```bash
# Database
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR...

# JWT
JWT_SECRET=min_32_random_characters_here

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your.email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_FROM_EMAIL=your.email@gmail.com
```

### **Optional (with defaults):**

```bash
# Server
PORT=8081
GIN_MODE=debug
CORS_ALLOWED_ORIGINS=http://localhost:3000

# JWT
JWT_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=7d

# Email
SMTP_FROM_NAME=Upvista Community
FRONTEND_URL=http://localhost:3001

# Rate Limiting
RATE_LIMIT_LOGIN=5
RATE_LIMIT_REGISTER=3
RATE_LIMIT_RESET=3
RATE_LIMIT_WINDOW=1m
RATE_LIMIT_FORGIVENESS=2

# Storage
STORAGE_BUCKET_NAME=profile-pictures
STORAGE_MAX_FILE_SIZE=5242880
STORAGE_ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif,image/webp

# OAuth (if using social login)
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-secret
GOOGLE_REDIRECT_URL=http://localhost:8081/api/v1/auth/google/callback

GITHUB_CLIENT_ID=your-client-id
GITHUB_CLIENT_SECRET=your-secret
GITHUB_REDIRECT_URL=http://localhost:8081/api/v1/auth/github/callback

LINKEDIN_CLIENT_ID=your-client-id
LINKEDIN_CLIENT_SECRET=your-secret
LINKEDIN_REDIRECT_URL=http://localhost:8081/api/v1/auth/linkedin/callback
```

---

## 📚 Variable Details

### **SUPABASE_URL**
- **Required:** Yes
- **Format:** `https://xxxproject.supabase.co`
- **Where:** Supabase Dashboard → Settings → API
- **Example:** `https://abcdefgh.supabase.co`

### **JWT_SECRET**
- **Required:** Yes
- **Min Length:** 32 characters
- **Recommendation:** 48+ characters, random
- **Generate:** `openssl rand -base64 48`
- **Security:** Different for dev/staging/production

### **PORT**
- **Default:** 8081
- **Production:** Usually 8080 or 10000 (Render.com)

---

**For complete list of all variables with examples, see the file.**

**Created by Hamza Hafeez - Founder & CEO of Upvista**

