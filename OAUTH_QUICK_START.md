# OAuth Quick Start Guide

## ✅ What's Been Implemented

OAuth authentication for **Google**, **GitHub**, and **LinkedIn** is fully coded and ready to use.

---

## 🚀 Steps to Get OAuth Working

### Step 1: Update Database (2 minutes)

Go to your **Supabase SQL Editor** and run:

```sql
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS github_id VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS linkedin_id VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS oauth_provider VARCHAR(50),
ADD COLUMN IF NOT EXISTS profile_picture TEXT;

CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_github_id ON users(github_id);
CREATE INDEX IF NOT EXISTS idx_users_linkedin_id ON users(linkedin_id);
```

---

### Step 2: Add OAuth Credentials to .env (1 minute)

Open `backend/.env` and add these lines **with your actual credentials**:

```bash
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-your-client-secret
GOOGLE_REDIRECT_URL=http://localhost:8081/api/v1/auth/google/callback

# GitHub OAuth Configuration
GITHUB_CLIENT_ID=Iv1.your-client-id
GITHUB_CLIENT_SECRET=ghp_your-client-secret
GITHUB_REDIRECT_URL=http://localhost:8081/api/v1/auth/github/callback

# LinkedIn OAuth Configuration
LINKEDIN_CLIENT_ID=your-client-id
LINKEDIN_CLIENT_SECRET=your-client-secret
LINKEDIN_REDIRECT_URL=http://localhost:8081/api/v1/auth/linkedin/callback
```

**Replace the placeholder values with the real credentials from:**
- Google Cloud Console
- GitHub Developer Settings
- LinkedIn Developers Portal

---

### Step 3: Start Backend (30 seconds)

```bash
cd backend
go run main.go
```

You should see: `Starting server on port 8081`

---

### Step 4: Start Frontend (30 seconds)

```bash
cd frontend-web
npm run dev
```

---

### Step 5: Test OAuth (1 minute)

1. Go to `http://localhost:3000/auth`
2. Click "Continue with Google" (or GitHub/LinkedIn)
3. Authenticate with the provider
4. You'll be redirected back and logged in automatically!

---

## 🔄 How OAuth Flow Works

```
User clicks "Continue with Google"
    ↓
Frontend calls: /api/v1/auth/google/login
    ↓
Backend returns Google auth URL + state token
    ↓
Frontend stores state in sessionStorage
    ↓
Frontend redirects to Google
    ↓
User authenticates with Google
    ↓
Google redirects to: /api/v1/auth/google/callback
    ↓
Backend redirects to frontend: /auth/callback?code=...&state=...
    ↓
Frontend validates state token (CSRF protection)
    ↓
Frontend calls: POST /api/v1/auth/google/exchange {code}
    ↓
Backend exchanges code with Google for user info
    ↓
Backend creates/finds user in Supabase
    ↓
Backend generates YOUR JWT token
    ↓
Frontend stores JWT in localStorage
    ↓
User is logged in!
```

---

## 🔐 Security Features

- **CSRF Protection:** State token validated on callback
- **Account Linking:** If email exists, links OAuth to existing account
- **Email Verification:** OAuth emails are auto-verified
- **No Password:** OAuth users don't need passwords
- **Profile Pictures:** Automatically fetched from OAuth provider

---

## 🗄️ Database Storage

All OAuth users are stored in your Supabase `users` table:

- Email/password users: Have `password_hash`
- Google users: Have `google_id`, no password
- GitHub users: Have `github_id`, no password
- LinkedIn users: Have `linkedin_id`, no password
- Users can link multiple OAuth providers to one account

---

## 🎯 API Endpoints

### OAuth Initiation:
- `GET /api/v1/auth/google/login` → Returns auth URL
- `GET /api/v1/auth/github/login` → Returns auth URL
- `GET /api/v1/auth/linkedin/login` → Returns auth URL

### OAuth Callbacks (from provider):
- `GET /api/v1/auth/google/callback` → Redirects to frontend
- `GET /api/v1/auth/github/callback` → Redirects to frontend
- `GET /api/v1/auth/linkedin/callback` → Redirects to frontend

### Token Exchange (from frontend):
- `POST /api/v1/auth/google/exchange` → Returns JWT
- `POST /api/v1/auth/github/exchange` → Returns JWT
- `POST /api/v1/auth/linkedin/exchange` → Returns JWT

---

## ✅ Checklist Before Testing

- [ ] Database migration SQL executed in Supabase
- [ ] Google credentials added to `.env`
- [ ] GitHub credentials added to `.env`
- [ ] LinkedIn credentials added to `.env`
- [ ] Backend server stopped (Ctrl+C if running)
- [ ] Backend server restarted (`go run main.go`)
- [ ] Frontend server running (`npm run dev`)

---

## 🚨 If OAuth Still Fails

### "Failed to initialize login"
- OAuth credentials not in `.env` file
- Backend not restarted after adding credentials
- **Fix:** Add credentials, restart backend

### "Invalid callback parameters"
- OAuth provider redirect URL doesn't match
- **Fix:** Verify redirect URLs in provider consoles match exactly:
  - `http://localhost:8081/api/v1/auth/PROVIDER/callback`

### "Authentication failed"
- Backend can't reach OAuth provider (network/firewall)
- Invalid OAuth credentials
- **Fix:** Check backend terminal logs for detailed error

---

## 🎉 You're All Set!

Once you:
1. ✅ Run the SQL migration
2. ✅ Add OAuth credentials to `.env`
3. ✅ Restart backend

OAuth will be fully functional!

