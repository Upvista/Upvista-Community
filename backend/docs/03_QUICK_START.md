# Quick Start Guide - Running in 15 Minutes

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Goal:** Get the authentication system running in 15 minutes or less  
> **Difficulty:** Beginner-friendly

---

## ⏱️ 15-Minute Setup

Follow these steps to have the system running locally:

### **✅ Prerequisites (5 minutes)**

Before starting, make sure you have:

1. **Go installed** (version 1.19+)
   ```bash
   # Check if installed:
   go version
   
   # If not installed, download from: https://go.dev/dl/
   ```

2. **Supabase account** (free)
   - Go to: https://supabase.com
   - Click "Start your project"
   - Create free account

3. **Gmail account** (for emails)
   - Any Gmail account works
   - You'll need to create an "App Password" later

---

## 🚀 Step 1: Get the Code (1 minute)

```bash
# If you already have it:
cd backend

# If starting fresh:
git clone <your-repo>
cd backend
```

---

## 🗄️ Step 2: Setup Supabase (3 minutes)

### **2.1 Create a New Project**

1. Go to https://app.supabase.com
2. Click **"New Project"**
3. Fill in:
   - **Name:** `upvista-auth` (or any name)
   - **Database Password:** Create a strong password
   - **Region:** Choose closest to you
4. Click **"Create new project"**
5. Wait 1-2 minutes for setup

### **2.2 Get Your API Keys**

1. In Supabase dashboard, go to: **Settings** → **API**
2. Copy these two keys:
   - **Project URL:** `https://xxx.supabase.co`
   - **service_role key:** `eyJhbG...` (long key, keep secret!)

### **2.3 Run Database Migration**

1. In Supabase dashboard, go to: **SQL Editor**
2. Click **"New query"**
3. Open file: `backend/scripts/migrate.sql`
4. Copy entire contents
5. Paste into Supabase SQL editor
6. Click **"Run"** (bottom right)
7. Should see: "Success. No rows returned"

✅ **Database is ready!**

---

## 📧 Step 3: Setup Email (Gmail) (3 minutes)

### **3.1 Create Gmail App Password**

1. Go to your **Google Account**: https://myaccount.google.com
2. Navigate to: **Security** → **2-Step Verification**
   - If not enabled, enable it first
3. Scroll down to: **App passwords**
4. Create new app password:
   - **App:** Mail
   - **Device:** Other (custom name) - enter "Upvista Backend"
5. Google shows a **16-character password** - copy it!

---

## ⚙️ Step 4: Configure Environment (2 minutes)

Create a file called `.env` in the `backend/` folder:

```bash
# In backend folder:
cd backend

# Create .env file (or copy from template)
# Add these values:
```

**Copy and paste this into your `.env` file:**

```bash
# === REQUIRED: Database (from Supabase) ===
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# === REQUIRED: JWT Secret (generate random string) ===
JWT_SECRET=your_super_secret_key_min_32_characters_please_change_this

# === REQUIRED: Email (your Gmail) ===
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your.email@gmail.com
SMTP_PASSWORD=xxxx xxxx xxxx xxxx  # 16-char app password from Step 3
SMTP_FROM_EMAIL=your.email@gmail.com
SMTP_FROM_NAME=Upvista Community

# === OPTIONAL: Server Port ===
PORT=8081

# === OPTIONAL: Frontend URL (for email links) ===
FRONTEND_URL=http://localhost:3001
```

**⚠️ Replace these values:**
- `SUPABASE_URL` - From Supabase dashboard
- `SUPABASE_SERVICE_ROLE_KEY` - From Supabase dashboard
- `JWT_SECRET` - Generate a random 32+ character string
- `SMTP_USERNAME` - Your Gmail address
- `SMTP_PASSWORD` - App password from Step 3
- `SMTP_FROM_EMAIL` - Your Gmail address

**How to generate JWT_SECRET:**
```bash
# On Mac/Linux:
openssl rand -base64 32

# On Windows (PowerShell):
-join (1..32 | ForEach-Object {[char]((65..90)+(97..122) | Get-Random)})

# Or use any random 32+ character string
```

---

## 🎯 Step 5: Install Dependencies (1 minute)

```bash
# In backend folder:
go mod tidy
```

This downloads all required Go packages.

---

## 🚀 Step 6: Start the Server (1 minute)

```bash
# In backend folder:
go run main.go
```

**You should see:**
```
Starting server on port 8081
```

✅ **Server is running!**

---

## ✅ Step 7: Test It Works (2 minutes)

### **Test 1: Health Check**

Open a new terminal:

```bash
curl http://localhost:8081/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "service": "upvista-community-backend",
  "version": "1.0.0"
}
```

### **Test 2: Database Connection**

```bash
curl http://localhost:8081/api/v1/test-db
```

**Expected response:**
```json
{
  "success": true,
  "message": "Database connection successful",
  "emailExists": false
}
```

### **Test 3: Create Your First User**

```bash
curl -X POST http://localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123",
    "username": "testuser",
    "display_name": "Test User",
    "age": 25
  }'
```

**Expected response:**
```json
{
  "success": true,
  "message": "Registration successful. Please check your email for verification code.",
  "user_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

**✅ Check your email!** You should receive a professional verification email with a 6-digit code.

### **Test 4: Verify Email**

```bash
# Replace 123456 with the code from your email
curl -X POST http://localhost:8081/api/v1/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "verification_code": "123456"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "message": "Email verified successfully",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2025-11-01T15:45:00Z",
  "user": {
    "id": "...",
    "email": "test@example.com",
    "username": "testuser",
    "display_name": "Test User",
    "age": 25,
    "is_email_verified": true
  }
}
```

**Save the token!** You'll need it for authenticated requests.

### **Test 5: Get Your Profile**

```bash
# Replace TOKEN with the token from previous response
curl -X GET http://localhost:8081/api/v1/account/profile \
  -H "Authorization: Bearer TOKEN"
```

**Expected response:**
```json
{
  "success": true,
  "user": {
    "id": "...",
    "email": "test@example.com",
    "username": "testuser",
    ...
  }
}
```

---

## 🎉 Success!

If all tests passed, **congratulations!** 🎊 Your authentication system is running!

You now have:
- ✅ Backend server running on port 8081
- ✅ Database connected (Supabase)
- ✅ Email system working (Gmail)
- ✅ User registration working
- ✅ Email verification working
- ✅ JWT authentication working
- ✅ Profile access working

---

## 🎯 What You Can Do Now

### **Test More Features:**

```bash
# Set your token for convenience
export TOKEN="your_jwt_token_here"

# Test login
curl -X POST http://localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email_or_username": "testuser",
    "password": "TestPassword123"
  }'

# Update profile
curl -X PATCH http://localhost:8081/api/v1/account/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"display_name": "New Name", "age": 26}'

# View active sessions
curl -X GET http://localhost:8081/api/v1/account/sessions \
  -H "Authorization: Bearer $TOKEN"

# Export your data (GDPR)
curl -X GET http://localhost:8081/api/v1/account/export-data \
  -H "Authorization: Bearer $TOKEN" \
  -o my-data.json
```

---

## 🛠️ Optional: Setup Supabase Storage (For Profile Pictures)

If you want to test profile picture uploads:

### **Create Storage Bucket:**

1. In Supabase dashboard: **Storage** → **New Bucket**
2. **Name:** `profile-pictures`
3. **Public:** ✅ Yes
4. **File size limit:** `5242880` (5MB)
5. **Allowed MIME types:** 
   - `image/jpeg`
   - `image/png`
   - `image/gif`
   - `image/webp`
6. Click **Save**

### **Test Upload:**

```bash
# Upload a picture
curl -X POST http://localhost:8081/api/v1/account/profile-picture \
  -H "Authorization: Bearer $TOKEN" \
  -F "profile_picture=@/path/to/your/image.jpg"
```

---

## 🧪 Optional: Setup OAuth (Social Login)

If you want Google/GitHub/LinkedIn login:

See **[10_OAUTH_INTEGRATION.md](./10_OAUTH_INTEGRATION.md)** for detailed setup.

**Quick version:**
1. Create OAuth app on Google/GitHub/LinkedIn
2. Get client ID and secret
3. Add to `.env`:
   ```bash
   GOOGLE_CLIENT_ID=your_client_id
   GOOGLE_CLIENT_SECRET=your_client_secret
   GOOGLE_REDIRECT_URL=http://localhost:8081/api/v1/auth/google/callback
   ```
4. Restart server

---

## 🐛 Troubleshooting

### **Problem: Server won't start**

**Check:**
```bash
# Is port 8081 already in use?
# Windows:
netstat -ano | findstr :8081

# Mac/Linux:
lsof -i :8081

# Kill the process or change PORT in .env
```

### **Problem: Database connection fails**

**Check:**
1. `SUPABASE_URL` is correct (includes https://)
2. `SUPABASE_SERVICE_ROLE_KEY` is the **service_role** key (not anon key!)
3. Supabase project is not paused
4. Internet connection is working

### **Problem: Emails not sending**

**Check:**
1. Gmail App Password is correct (16 characters, spaces don't matter)
2. 2-Step Verification is enabled on Google account
3. SMTP credentials are correct:
   - Host: `smtp.gmail.com`
   - Port: `587`
4. Check spam folder

**Test SMTP connection:**
```bash
# Add this endpoint temporarily in main.go:
r.GET("/test-email", func(c *gin.Context) {
    err := emailSvc.SendVerificationEmail("your@email.com", "123456")
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    c.JSON(200, gin.H{"message": "Email sent!"})
})

# Then:
curl http://localhost:8081/test-email
```

### **Problem: Migration fails**

**Common issues:**
- Policy already exists → Migration is idempotent, just run again
- Column already exists → Run the full migration script
- Table already exists → Script handles this with IF NOT EXISTS

**Solution:** Run entire `migrate.sql` script in Supabase SQL Editor

---

## 📖 What's Next?

### **For Complete Setup:**
See **[04_INSTALLATION_GUIDE.md](./04_INSTALLATION_GUIDE.md)** for production configuration

### **To Build Frontend:**
See **[05_API_REFERENCE.md](./05_API_REFERENCE.md)** for all available endpoints

### **To Deploy:**
See **[11_DEPLOYMENT_GUIDE.md](./11_DEPLOYMENT_GUIDE.md)** for production deployment

### **If Problems:**
See **[12_TROUBLESHOOTING.md](./12_TROUBLESHOOTING.md)** for detailed solutions

---

## 🎓 Understanding What You Just Built

### **What's Running:**

1. **HTTP Server** (port 8081)
   - Handles API requests
   - Returns JSON responses

2. **30 API Endpoints:**
   - 16 authentication endpoints
   - 14 account management endpoints

3. **Connection to Supabase:**
   - PostgreSQL database
   - Stores user accounts and sessions

4. **Email Service:**
   - Sends verification codes
   - Sends password resets
   - Sends security notifications

### **What You Can Test:**

✅ **User Registration** - Create accounts  
✅ **Email Verification** - 6-digit codes  
✅ **Login** - Username/email + password  
✅ **Profile Management** - View and update  
✅ **Password Changes** - Secure updates  
✅ **Session Tracking** - See active logins  
✅ **Data Export** - GDPR compliance  

---

## 💡 Quick Tips

### **Development Workflow:**

```bash
# Terminal 1: Run backend
cd backend
go run main.go

# Terminal 2: Test API calls
curl http://localhost:8081/health

# When you make code changes:
# Press Ctrl+C in Terminal 1, then run again
```

### **Environment Variables:**

Create different `.env` files:
- `.env` - Development
- `.env.production` - Production
- `.env.test` - Testing

Load specific env:
```bash
go run main.go --env=.env.production
```

### **View Logs:**

```bash
# Backend logs show in terminal
# Look for:
# - Request logs
# - Database queries
# - Email sending status
# - Error messages
```

---

## 🎯 Common Next Steps

### **1. Frontend Integration**

The backend is running! Now build a frontend:

**Example (React/Next.js):**
```typescript
// Register user
const response = await fetch('http://localhost:8081/api/v1/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'SecurePass123',
    username: 'cooluser',
    display_name: 'Cool User',
    age: 25
  })
});

const data = await response.json();
console.log(data); // success!
```

### **2. Add OAuth (Social Login)**

Want Google/GitHub login?

1. Follow **[10_OAUTH_INTEGRATION.md](./10_OAUTH_INTEGRATION.md)**
2. Get OAuth credentials
3. Add to `.env`
4. Restart server
5. Test: `curl http://localhost:8081/api/v1/auth/google/login`

### **3. Deploy to Production**

When ready to go live:

1. Follow **[11_DEPLOYMENT_GUIDE.md](./11_DEPLOYMENT_GUIDE.md)**
2. Choose platform (Render, Railway, Fly.io, etc.)
3. Set environment variables
4. Deploy!

---

## 📊 System Status Checklist

After quick start, you should have:

- [x] Go installed and working
- [x] Supabase project created
- [x] Database migration successful
- [x] Gmail app password created
- [x] `.env` file configured
- [x] Dependencies installed (`go mod tidy`)
- [x] Server running (port 8081)
- [x] Health check passing
- [x] Database connection working
- [x] Test user created
- [x] Email received
- [x] User verified
- [x] JWT token obtained
- [x] Profile fetched successfully

**All checked?** ✅ You're ready to build!

---

## 🆘 Getting Help

### **Still Having Issues?**

1. **Check Logs:** Look at terminal output for error messages
2. **Verify .env:** Double-check all values are correct
3. **Test Database:** Use `/test-db` endpoint
4. **Read Troubleshooting:** See **[12_TROUBLESHOOTING.md](./12_TROUBLESHOOTING.md)**
5. **Check Documentation:** Each feature has detailed docs

### **Common Mistakes:**

❌ **Using ANON key instead of SERVICE_ROLE key**
- Must use `service_role` key from Supabase, not `anon` key

❌ **Gmail password instead of App Password**
- Must create App Password, regular password won't work

❌ **Port already in use**
- Change `PORT=8081` to `PORT=8082` in `.env`

❌ **Forgot to run migration**
- Tables don't exist → run `migrate.sql` in Supabase

---

## 🎓 Learn More

### **Understand the System:**
- **[02_ARCHITECTURE.md](./02_ARCHITECTURE.md)** - How it works internally
- **[06_DATABASE_SCHEMA.md](./06_DATABASE_SCHEMA.md)** - Database structure
- **[07_SECURITY_GUIDE.md](./07_SECURITY_GUIDE.md)** - Security features

### **Use the System:**
- **[05_API_REFERENCE.md](./05_API_REFERENCE.md)** - All 30 endpoints
- **[09_EMAIL_SYSTEM.md](./09_EMAIL_SYSTEM.md)** - Email templates
- **[13_EXTENDING_SYSTEM.md](./13_EXTENDING_SYSTEM.md)** - Add features

---

## 🎊 Congratulations!

You've successfully set up a **production-ready authentication system** in 15 minutes!

**What you accomplished:**
- Deployed a complete backend API
- Connected to a scalable database
- Configured professional email sending
- Created and verified a user account
- Tested JWT authentication
- Accessed protected endpoints

**This would have taken days to build from scratch!** 🚀

---

**Created with ❤️ by Hamza Hafeez**  
Founder & CEO, Upvista

---

**[← Back to Overview](./01_OVERVIEW.md)** | **[Next: Installation Guide →](./04_INSTALLATION_GUIDE.md)**

