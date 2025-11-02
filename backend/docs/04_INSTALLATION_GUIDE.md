# Complete Installation Guide

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Comprehensive Installation & Setup Guide  
> **Audience:** Developers integrating into new projects

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Database Setup (Supabase)](#database-setup)
4. [Email Configuration (SMTP)](#email-configuration)
5. [Storage Setup (Optional)](#storage-setup)
6. [OAuth Setup (Optional)](#oauth-setup)
7. [Environment Configuration](#environment-configuration)
8. [Running the Application](#running-the-application)
9. [Verification & Testing](#verification--testing)
10. [Production Considerations](#production-considerations)

---

## 📦 Prerequisites

### **Required Software:**

1. **Go Programming Language** (v1.19 or higher)
   - Download: https://go.dev/dl/
   - Verify: `go version`

2. **Git** (for cloning repository)
   - Download: https://git-scm.com/downloads
   - Verify: `git --version`

3. **Text Editor/IDE**
   - Recommended: VS Code, GoLand, Vim
   - For `.env` file editing

### **Required Accounts:**

4. **Supabase Account** (free tier available)
   - Sign up: https://supabase.com
   - Free tier includes: 500MB database, 1GB storage

5. **Email Provider (choose one):**
   - **Gmail** (free, personal use) - Easiest for testing
   - **SendGrid** (free 100 emails/day) - Better for production
   - **AWS SES** (pay-as-you-go) - Enterprise scale
   - **Mailgun**, **Postmark**, etc.

### **Optional (for full features):**

6. **OAuth Provider Accounts**
   - Google Cloud Console (Google login)
   - GitHub Apps (GitHub login)
   - LinkedIn Developers (LinkedIn login)

---

## 🚀 Project Setup

### **Step 1: Get the Source Code**

**Option A: Clone from Repository**
```bash
git clone https://github.com/Upvista/Upvista-Community.git
cd Upvista-Community/backend
```

**Option B: Copy into Existing Project**
```bash
# Copy the backend folder structure:
your-project/
├── backend/          # Paste the entire backend folder here
└── your-other-code/
```

**Option C: Initialize New Project**
```bash
mkdir my-auth-backend
cd my-auth-backend

# Copy all files from backend/ folder
# Initialize Go module
go mod init your-project-name

# Install dependencies
go mod tidy
```

### **Step 2: Verify File Structure**

Ensure you have this structure:
```
backend/
├── internal/
│   ├── auth/
│   ├── account/
│   ├── config/
│   ├── models/
│   ├── repository/
│   └── utils/
├── pkg/
│   └── errors/
├── scripts/
│   └── migrate.sql
├── docs/
├── main.go
├── go.mod
└── go.sum
```

### **Step 3: Install Dependencies**

```bash
cd backend
go mod download
go mod tidy
```

This installs all required packages:
- Gin (web framework)
- JWT library
- bcrypt (password hashing)
- Viper (configuration)
- And more...

**Verify:**
```bash
go mod verify
# Should output: "all modules verified"
```

---

## 🗄️ Database Setup (Supabase)

### **Step 1: Create Supabase Project**

1. Go to https://app.supabase.com
2. Click **"New Project"**
3. Select organization (or create one)
4. Fill in project details:
   - **Name:** `upvista-auth-production` (or your name)
   - **Database Password:** **Strong password** (save it!)
   - **Region:** Select closest to your users
   - **Plan:** Free (or Pro if needed)
5. Click **"Create new project"**
6. Wait 1-2 minutes for provisioning

### **Step 2: Get API Credentials**

1. In project dashboard, go to: **Settings** (gear icon) → **API**
2. You'll see:
   - **Project URL:** `https://xxxproject.supabase.co`
   - **anon/public key:** `eyJhbGciOi...` (public key)
   - **service_role key:** `eyJhbGciOi...` (secret key)

**⚠️ Important:** You need the **service_role** key, not the anon key!

**Copy these values:**
```bash
SUPABASE_URL=https://xxxproject.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### **Step 3: Run Database Migration**

The migration script creates all necessary tables, indexes, and policies.

1. In Supabase dashboard: **SQL Editor** (left sidebar)
2. Click **"New query"**
3. Open local file: `backend/scripts/migrate.sql`
4. Copy entire contents (all ~150 lines)
5. Paste into SQL editor
6. Click **"Run"** (or press Ctrl+Enter)

**Expected output:**
```
Success. No rows returned
Time: ~200-500ms
```

**What was created:**
- ✅ `users` table (30+ columns)
- ✅ `user_sessions` table (session tracking)
- ✅ 15 indexes (performance optimization)
- ✅ Row Level Security policies
- ✅ Database triggers (auto-update timestamps)

**Verify tables exist:**
1. Go to **Table Editor** (left sidebar)
2. You should see:
   - `users` table
   - `user_sessions` table

### **Step 4: Verify Database Schema**

Run this query in SQL Editor:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE';
```

Should return:
- `users`
- `user_sessions`

---

## 📧 Email Configuration (SMTP)

### **Option 1: Gmail (Easiest for Development)**

**Requirements:**
- Gmail account
- 2-Step Verification enabled

**Steps:**

1. **Enable 2-Step Verification:**
   - Go to: https://myaccount.google.com/security
   - Click: **2-Step Verification**
   - Follow setup wizard

2. **Create App Password:**
   - In Security settings, scroll to: **App passwords**
   - Click: **App passwords**
   - Select app: **Mail**
   - Select device: **Other (Custom name)**
   - Enter: "Upvista Backend"
   - Click: **Generate**
   - Copy the **16-character password** (e.g., `abcd efgh ijkl mnop`)

3. **Configure in .env:**
   ```bash
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your.email@gmail.com
   SMTP_PASSWORD=abcd efgh ijkl mnop  # From step 2
   SMTP_FROM_EMAIL=your.email@gmail.com
   SMTP_FROM_NAME=Upvista Community
   ```

**Limitations:**
- 500 emails/day limit
- Not recommended for production (use SendGrid/SES)

---

### **Option 2: SendGrid (Recommended for Production)**

**Requirements:**
- SendGrid account (free tier: 100 emails/day)

**Steps:**

1. **Create Account:**
   - Go to: https://sendgrid.com
   - Sign up for free account

2. **Verify Sender Identity:**
   - Go to: **Settings** → **Sender Authentication**
   - Click: **Verify a Single Sender**
   - Enter your email
   - Verify via email link

3. **Create API Key:**
   - Go to: **Settings** → **API Keys**
   - Click: **Create API Key**
   - Name: "Upvista Backend"
   - Permissions: **Full Access**
   - Click: **Create & View**
   - Copy the API key (starts with `SG.`)

4. **Configure in .env:**
   ```bash
   SMTP_HOST=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_USERNAME=apikey  # Literally the word "apikey"
   SMTP_PASSWORD=SG.xxxxxxxxxxxxx  # Your API key
   SMTP_FROM_EMAIL=verified@yourdomain.com
   SMTP_FROM_NAME=Upvista Community
   ```

**Benefits:**
- 100 emails/day (free) → 100,000/month (paid)
- Better deliverability
- Analytics dashboard
- Production-ready

---

### **Option 3: AWS SES (Enterprise Scale)**

**For:** High-volume, lowest cost ($0.10 per 1,000 emails)

**Steps:**

1. **AWS Account Setup:**
   - Create AWS account
   - Go to: AWS SES Console

2. **Verify Domain/Email:**
   - Add your domain or email
   - Verify via DNS or email

3. **Get SMTP Credentials:**
   - Go to: **SMTP Settings**
   - Click: **Create My SMTP Credentials**
   - Copy username and password

4. **Move Out of Sandbox:**
   - By default, SES is in sandbox (can only email verified addresses)
   - Request production access
   - Takes 24-48 hours approval

5. **Configure in .env:**
   ```bash
   SMTP_HOST=email-smtp.us-east-1.amazonaws.com  # Your region
   SMTP_PORT=587
   SMTP_USERNAME=AKIAIOSFODNN7EXAMPLE
   SMTP_PASSWORD=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   SMTP_FROM_EMAIL=noreply@yourdomain.com
   SMTP_FROM_NAME=Upvista Community
   ```

---

## 💾 Storage Setup (For Profile Pictures)

### **Create Supabase Storage Bucket**

1. In Supabase dashboard: **Storage** (left sidebar)
2. Click **"New bucket"**
3. **Bucket details:**
   - **Name:** `profile-pictures`
   - **Public bucket:** ✅ Yes (checked)
   - **File size limit:** `5242880` bytes (5MB)
   - **Allowed MIME types:**
     - Add: `image/jpeg`
     - Add: `image/png`
     - Add: `image/gif`
     - Add: `image/webp`
4. Click **"Create bucket"**

**Verify creation:**
- You should see `profile-pictures` in bucket list

**Configure in .env (optional, uses defaults):**
```bash
STORAGE_BUCKET_NAME=profile-pictures
STORAGE_MAX_FILE_SIZE=5242880  # 5MB
STORAGE_ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif,image/webp
```

---

## 🔐 OAuth Setup (Social Login)

Detailed setup for each provider. **Optional** - skip if you don't need social login.

### **Google OAuth Setup**

See complete guide in **[10_OAUTH_INTEGRATION.md](./10_OAUTH_INTEGRATION.md)**

**Quick version:**
1. Google Cloud Console → Create project
2. Enable Google+ API
3. Create OAuth 2.0 credentials
4. Add redirect URI: `http://localhost:8081/api/v1/auth/google/callback`
5. Copy Client ID and Secret
6. Add to `.env`:
   ```bash
   GOOGLE_CLIENT_ID=123456-abcdef.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxx
   GOOGLE_REDIRECT_URL=http://localhost:8081/api/v1/auth/google/callback
   ```

### **GitHub OAuth Setup**

1. GitHub Settings → Developer settings → OAuth Apps
2. New OAuth App
3. Callback URL: `http://localhost:8081/api/v1/auth/github/callback`
4. Copy Client ID and generate Client Secret
5. Add to `.env`:
   ```bash
   GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxxx
   GITHUB_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxx
   GITHUB_REDIRECT_URL=http://localhost:8081/api/v1/auth/github/callback
   ```

### **LinkedIn OAuth Setup**

1. LinkedIn Developers → My Apps → Create app
2. Add redirect URL: `http://localhost:8081/api/v1/auth/linkedin/callback`
3. Request OAuth 2.0 scopes: openid, profile, email
4. Copy Client ID and Secret
5. Add to `.env`:
   ```bash
   LINKEDIN_CLIENT_ID=xxxxxxxxxxxxx
   LINKEDIN_CLIENT_SECRET=xxxxxxxxxxxxx
   LINKEDIN_REDIRECT_URL=http://localhost:8081/api/v1/auth/linkedin/callback
   ```

---

## ⚙️ Environment Configuration

### **Create .env File**

In `backend/` folder, create a file named `.env`:

```bash
# ============================================
# UPVISTA AUTHENTICATION SYSTEM
# Created by: Hamza Hafeez
# ============================================

# === DATABASE (Required) ===
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# === JWT CONFIGURATION (Required) ===
JWT_SECRET=generate_a_random_32_character_secret_key_here_please_change_this
JWT_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=7d

# === EMAIL / SMTP (Required) ===
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your.email@gmail.com
SMTP_PASSWORD=your app password here
SMTP_FROM_EMAIL=your.email@gmail.com
SMTP_FROM_NAME=Upvista Community

# === SERVER (Optional - has defaults) ===
PORT=8081
GIN_MODE=debug  # Use 'release' in production
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001

# === FRONTEND URL (For email links) ===
FRONTEND_URL=http://localhost:3001

# === RATE LIMITING (Optional - has defaults) ===
RATE_LIMIT_LOGIN=5
RATE_LIMIT_REGISTER=3
RATE_LIMIT_RESET=3
RATE_LIMIT_WINDOW=1m
RATE_LIMIT_FORGIVENESS=2

# === STORAGE (Optional - for profile pictures) ===
STORAGE_BUCKET_NAME=profile-pictures
STORAGE_MAX_FILE_SIZE=5242880  # 5MB
STORAGE_ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif,image/webp

# === OAUTH (Optional - for social login) ===
# Google
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxxxx
GOOGLE_REDIRECT_URL=http://localhost:8081/api/v1/auth/google/callback

# GitHub
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxxxxx
GITHUB_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxx
GITHUB_REDIRECT_URL=http://localhost:8081/api/v1/auth/github/callback

# LinkedIn
LINKEDIN_CLIENT_ID=xxxxxxxxxxxxxxx
LINKEDIN_CLIENT_SECRET=xxxxxxxxxxxxxxx
LINKEDIN_REDIRECT_URL=http://localhost:8081/api/v1/auth/linkedin/callback
```

**💡 Tip:** Create a `.env.example` file with placeholder values for your team.

---

## 🔐 Security: Generate Strong JWT Secret

### **Method 1: OpenSSL (Mac/Linux)**
```bash
openssl rand -base64 48
```

### **Method 2: PowerShell (Windows)**
```powershell
-join (1..48 | ForEach-Object {[char]((48..57)+(65..90)+(97..122) | Get-Random)})
```

### **Method 3: Online Generator**
- Go to: https://randomkeygen.com/
- Use "CodeIgniter Encryption Keys" (256-bit)

### **Method 4: Go Program**
```go
package main
import (
    "crypto/rand"
    "encoding/base64"
    "fmt"
)
func main() {
    b := make([]byte, 32)
    rand.Read(b)
    fmt.Println(base64.StdEncoding.EncodeToString(b))
}
```

**⚠️ CRITICAL:** 
- Minimum 32 characters
- Use random, unpredictable string
- Never commit to Git
- Different for each environment (dev, staging, production)

---

## 🔄 Database Migration (Detailed)

### **Understanding the Migration**

The `migrate.sql` script is **idempotent** - you can run it multiple times safely.

**What it does:**
1. Creates `users` table (if not exists)
2. Creates `user_sessions` table
3. Adds indexes for performance
4. Sets up Row Level Security policies
5. Creates database triggers
6. Adds OAuth columns (ALTER TABLE)
7. Adds Phase 2 columns (email change, username tracking)

### **Migration Steps:**

**1. Open SQL Editor:**
- Supabase Dashboard → **SQL Editor** → **New query**

**2. Load Migration Script:**
- Open `backend/scripts/migrate.sql` in your editor
- Select all (Ctrl+A / Cmd+A)
- Copy (Ctrl+C / Cmd+C)

**3. Paste and Run:**
- Paste into Supabase SQL Editor
- Click **"Run"** or press `Ctrl+Enter`

**4. Verify Success:**
```
Success. No rows returned
Time: ~200-500ms
```

### **Verify Migration:**

Run this query:
```sql
-- Check tables exist
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('users', 'user_sessions')
ORDER BY table_name, ordinal_position;
```

Should show all columns for both tables.

### **Check Indexes:**
```sql
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public';
```

Should show 15+ indexes.

---

## 🎨 Email Provider Configuration (Detailed)

### **Gmail Setup (Step-by-Step)**

**Why Gmail?**
- Free
- Easy setup
- Perfect for development/testing
- 500 emails/day limit

**Complete Steps:**

1. **Go to Google Account Security**
   - URL: https://myaccount.google.com/security

2. **Enable 2-Step Verification** (if not already)
   - Click **"2-Step Verification"**
   - Click **"Get started"**
   - Follow prompts (usually phone verification)
   - This is required for App Passwords

3. **Create App Password:**
   - Go back to Security page
   - Scroll to: **"Signing in to Google"**
   - Click: **"App passwords"**
   - If you don't see it, ensure 2-Step Verification is on
   - **Select app:** Mail
   - **Select device:** Other (Custom name)
   - Enter name: `Upvista Backend`
   - Click **"Generate"**
   - Google shows: `abcd efgh ijkl mnop` (16 chars, 4 groups)
   - **Copy this password!**

4. **Add to .env:**
   ```bash
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your.email@gmail.com
   SMTP_PASSWORD=abcd efgh ijkl mnop  # Spaces don't matter
   SMTP_FROM_EMAIL=your.email@gmail.com
   SMTP_FROM_NAME=Upvista Community
   ```

**Troubleshooting Gmail:**
- **"Invalid credentials":** Check app password is correct
- **"Less secure apps":** Not needed with App Password
- **Not receiving emails:** Check spam folder
- **Still not working:** Try creating a new app password

---

### **SendGrid Setup (Recommended for Production)**

**Why SendGrid?**
- 100 emails/day free → 100,000/month paid
- Better deliverability
- Email analytics
- Professional features

**Complete Steps:**

1. **Create Account:**
   - Go to: https://signup.sendgrid.com/
   - Sign up (free tier)
   - Verify your email

2. **Verify Sender Identity:**
   - Dashboard → **Settings** → **Sender Authentication**
   - **Option A: Single Sender Verification** (easier)
     - Click **"Verify a Single Sender"**
     - Enter your email
     - Verify via email link
   - **Option B: Domain Authentication** (better)
     - Click **"Authenticate Your Domain"**
     - Add DNS records to your domain
     - Better for production

3. **Create API Key:**
   - Go to: **Settings** → **API Keys**
   - Click **"Create API Key"**
   - **Name:** "Upvista Backend"
   - **Permissions:** Full Access (or Restricted: Mail Send only)
   - Click **"Create & View"**
   - **Copy the key:** `SG.xxxxxxxxxxxxxxxxxxxxxxx`
   - ⚠️ **Save it now!** You can't see it again

4. **Configure in .env:**
   ```bash
   SMTP_HOST=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_USERNAME=apikey  # Literally the word "apikey"
   SMTP_PASSWORD=SG.xxxxxxxxxxxxxxxxxxxxxxx  # Your API key
   SMTP_FROM_EMAIL=verified@yourdomain.com  # Must be verified
   SMTP_FROM_NAME=Upvista Community
   ```

**Test sending:**
```bash
# SendGrid provides a test endpoint:
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer SG.your_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [{"to": [{"email": "your@email.com"}]}],
    "from": {"email": "verified@yourdomain.com"},
    "subject": "Test",
    "content": [{"type": "text/plain", "value": "Test email"}]
  }'
```

---

## 🏃 Running the Application

### **Development Mode:**

```bash
cd backend
go run main.go
```

**Output:**
```
Starting server on port 8081
```

**Server is running!** Press `Ctrl+C` to stop.

### **With Auto-Reload (Development):**

Install Air (live reload tool):
```bash
go install github.com/cosmtrek/air@latest
```

Create `.air.toml` in backend folder:
```toml
root = "."
tmp_dir = "tmp"

[build]
  cmd = "go build -o ./tmp/main ."
  bin = "tmp/main"
  include_ext = ["go"]
  exclude_dir = ["tmp"]
```

Run with auto-reload:
```bash
air
```

Now code changes auto-restart the server!

### **Production Mode:**

Build binary:
```bash
go build -o upvista-backend main.go
```

Run binary:
```bash
./upvista-backend  # Mac/Linux
upvista-backend.exe  # Windows
```

---

## ✅ Verification & Testing

### **1. Health Checks**

```bash
# Server health
curl http://localhost:8081/health

# API version
curl http://localhost:8081/api/v1/status

# Database connection
curl http://localhost:8081/api/v1/test-db
```

All should return `200 OK`.

### **2. Authentication Flow Test**

**A. Register:**
```bash
curl -X POST http://localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "SecurePass123",
    "username": "newuser",
    "display_name": "New User",
    "age": 28
  }'
```

**B. Check Email:**
- Open inbox for `newuser@example.com`
- Copy 6-digit verification code

**C. Verify Email:**
```bash
curl -X POST http://localhost:8081/api/v1/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "verification_code": "123456"
  }'
```

**D. Save Token:**
```bash
export TOKEN="token_from_response"
```

**E. Test Authenticated Endpoint:**
```bash
curl -X GET http://localhost:8081/api/v1/account/profile \
  -H "Authorization: Bearer $TOKEN"
```

### **3. Email System Test**

After registration, you should receive:
- ✅ Email verification code (professional template)
- ✅ Welcome email (after verification)

Test all email types:
```bash
# Password reset
curl -X POST http://localhost:8081/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "newuser@example.com"}'

# Check email for reset link
```

### **4. Profile Picture Upload Test**

```bash
# Prepare a test image (< 5MB)
curl -X POST http://localhost:8081/api/v1/account/profile-picture \
  -H "Authorization: Bearer $TOKEN" \
  -F "profile_picture=@/path/to/test-image.jpg"

# Should return public URL
```

### **5. Data Export Test**

```bash
curl -X GET http://localhost:8081/api/v1/account/export-data \
  -H "Authorization: Bearer $TOKEN" \
  -o user-data.json

# View exported data
cat user-data.json | jq  # If jq installed
cat user-data.json       # Without jq
```

---

## 🔧 Configuration Validation

### **Check All Required Variables:**

Create a test script `check-config.sh`:
```bash
#!/bin/bash

echo "Checking configuration..."

# Required variables
required=(
    "SUPABASE_URL"
    "SUPABASE_SERVICE_ROLE_KEY"
    "JWT_SECRET"
    "SMTP_USERNAME"
    "SMTP_PASSWORD"
)

for var in "${required[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing: $var"
    else
        echo "✅ Found: $var"
    fi
done
```

Run:
```bash
chmod +x check-config.sh
source .env && ./check-config.sh
```

---

## 🎯 Post-Installation Steps

### **1. Test All Features:**

Use the test script in `backend/test-api.sh`:
```bash
#!/bin/bash
BASE_URL="http://localhost:8081"

echo "Testing Health..."
curl $BASE_URL/health

echo "\nTesting Database..."
curl $BASE_URL/api/v1/test-db

echo "\nTesting Registration..."
curl -X POST $BASE_URL/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123","username":"test","display_name":"Test","age":25}'

# ... more tests
```

### **2. Review Logs:**

Check terminal output for:
- Database connection logs
- Email sending logs
- Request logs
- Error logs (if any)

### **3. Check Supabase Dashboard:**

1. **Table Editor** → `users` → Should see test users
2. **Table Editor** → `user_sessions` → Should see sessions
3. **Storage** → `profile-pictures` → Should see uploaded files

---

## 🌐 Production Considerations

When moving to production:

### **1. Update Environment Variables:**

```bash
# Change these for production:
GIN_MODE=release
FRONTEND_URL=https://yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com

# Use production Supabase project
SUPABASE_URL=https://prod-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=production_key_here

# Use production email service (SendGrid/SES)
SMTP_HOST=smtp.sendgrid.net
SMTP_USERNAME=apikey
SMTP_PASSWORD=SG.production_key

# Strong JWT secret (different from dev!)
JWT_SECRET=production_secret_min_48_chars_completely_random
```

### **2. Security Hardening:**

- ✅ Use strong JWT_SECRET (48+ chars)
- ✅ Enable HTTPS/TLS
- ✅ Set strict CORS policy
- ✅ Use environment-specific secrets
- ✅ Enable rate limiting
- ✅ Monitor logs

### **3. Performance:**

- ✅ Use production Supabase plan
- ✅ Enable database connection pooling
- ✅ Use CDN for static files
- ✅ Enable compression (Gin middleware)

---

## 🚧 Common Installation Issues

### **Issue: "Go command not found"**

**Solution:**
```bash
# Add Go to PATH
# Mac/Linux: Add to ~/.bashrc or ~/.zshrc
export PATH=$PATH:/usr/local/go/bin

# Windows: Add to System Environment Variables
C:\Go\bin
```

### **Issue: "Package not found"**

**Solution:**
```bash
# Clear module cache
go clean -modcache

# Re-download dependencies
go mod download
go mod tidy
```

### **Issue: "Port already in use"**

**Solution:**
```bash
# Find process on port 8081
# Windows:
netstat -ano | findstr :8081
taskkill /PID <PID> /F

# Mac/Linux:
lsof -i :8081
kill -9 <PID>

# Or change port in .env:
PORT=8082
```

### **Issue: "Database error"**

**Solution:**
1. Check `SUPABASE_URL` format: `https://xxx.supabase.co` (include https://)
2. Use `service_role` key, not `anon` key
3. Verify migration ran successfully
4. Check Supabase project is not paused

### **Issue: "Failed to send email"**

**Solution:**
1. Verify SMTP credentials
2. Check Gmail App Password (not regular password)
3. Ensure 2-Step Verification is enabled
4. Try regenerating App Password
5. Check firewall allows port 587

---

## 📚 Next Steps

### **After successful installation:**

1. **Explore API:** Read **[05_API_REFERENCE.md](./05_API_REFERENCE.md)**
2. **Build Frontend:** Connect your UI to the API
3. **Customize:** Modify email templates, add features
4. **Deploy:** Follow **[11_DEPLOYMENT_GUIDE.md](./11_DEPLOYMENT_GUIDE.md)**

### **For production deployment:**

1. **Configure production .env**
2. **Setup production Supabase project**
3. **Configure production email service**
4. **Deploy to hosting platform**
5. **Setup monitoring**

---

## ✅ Installation Checklist

- [ ] Go installed and verified
- [ ] Supabase account created
- [ ] Supabase project created
- [ ] Database migration successful
- [ ] Gmail account setup (or other SMTP)
- [ ] App password created
- [ ] Storage bucket created (if using profile pictures)
- [ ] OAuth apps created (if using social login)
- [ ] `.env` file created and populated
- [ ] Dependencies installed (`go mod tidy`)
- [ ] Server starts without errors
- [ ] Health check passes
- [ ] Database connection works
- [ ] Test user created successfully
- [ ] Verification email received
- [ ] User verified and logged in
- [ ] JWT token works for authenticated requests

**All checked?** ✅ You're ready for development!

---

**Created with care by Hamza Hafeez**  
Founder & CEO, Upvista

---

**[← Back to Overview](./01_OVERVIEW.md)** | **[Next: API Reference →](./05_API_REFERENCE.md)**

