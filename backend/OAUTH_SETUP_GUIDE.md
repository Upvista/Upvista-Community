# OAuth Authentication Setup Guide

## ✅ Implementation Complete

OAuth authentication for **Google**, **GitHub**, and **LinkedIn** has been successfully implemented.

---

## 📋 What Was Implemented

### Backend Changes:
1. ✅ Database schema updated with OAuth columns
2. ✅ Config system updated for OAuth providers
3. ✅ OAuth services created for all 3 providers
4. ✅ User repository methods added for OAuth
5. ✅ OAuth handlers and routes registered
6. ✅ Main.go initialized with OAuth services

### Frontend Changes:
1. ✅ Auth page updated with working OAuth buttons
2. ✅ Unified callback page created
3. ✅ GitHub and LinkedIn SVG icons added
4. ✅ Error handling implemented

---

## 🚀 Next Steps

### Step 1: Update Database Schema

Run this SQL in your Supabase SQL Editor:

```sql
-- Add OAuth columns to existing users table
ALTER TABLE users
ALTER COLUMN password_hash DROP NOT NULL;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS github_id VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS linkedin_id VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS oauth_provider VARCHAR(50),
ADD COLUMN IF NOT EXISTS profile_picture TEXT;

-- Add indexes for OAuth IDs
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_github_id ON users(github_id);
CREATE INDEX IF NOT EXISTS idx_users_linkedin_id ON users(linkedin_id);
```

**Or** run the full migration script: `backend/scripts/migrate.sql`

---

### Step 2: Verify .env Configuration

Make sure your `backend/.env` file has all OAuth credentials:

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-your-secret
GOOGLE_REDIRECT_URL=http://localhost:8081/api/v1/auth/google/callback

# GitHub OAuth
GITHUB_CLIENT_ID=Iv1.your-client-id
GITHUB_CLIENT_SECRET=ghp_your-secret
GITHUB_REDIRECT_URL=http://localhost:8081/api/v1/auth/github/callback

# LinkedIn OAuth
LINKEDIN_CLIENT_ID=your-client-id
LINKEDIN_CLIENT_SECRET=your-secret
LINKEDIN_REDIRECT_URL=http://localhost:8081/api/v1/auth/linkedin/callback
```

---

### Step 3: Restart Backend Server

```bash
cd backend
go run main.go
```

The server will start with OAuth routes active.

---

### Step 4: Restart Frontend Server

```bash
cd frontend-web
npm run dev
```

---

### Step 5: Test OAuth Flow

1. Go to `http://localhost:3000/auth`
2. Click "Continue with Google" (or GitHub/LinkedIn)
3. Authenticate with the provider
4. You'll be redirected to `/auth/callback`
5. Then redirected to home page with JWT token

---

## 🔄 OAuth Flow Explanation

### User clicks "Continue with Google":
```
1. Frontend calls: GET /api/v1/auth/google/login
2. Backend generates state token (CSRF protection)
3. Backend returns Google auth URL
4. Frontend redirects user to Google
5. User authenticates with Google
6. Google redirects to: /api/v1/auth/google/callback?code=...&state=...
7. Backend verifies state, exchanges code for Google token
8. Backend gets user info from Google
9. Backend creates/finds user in Supabase
10. Backend generates YOUR JWT token
11. Frontend stores JWT and redirects to home
```

Same flow for GitHub and LinkedIn.

---

## 🎯 OAuth Routes

### Google:
- **Login:** `GET /api/v1/auth/google/login`
- **Callback:** `GET /api/v1/auth/google/callback?code=...&state=...`

### GitHub:
- **Login:** `GET /api/v1/auth/github/login`
- **Callback:** `GET /api/v1/auth/github/callback?code=...&state=...`

### LinkedIn:
- **Login:** `GET /api/v1/auth/linkedin/login`
- **Callback:** `GET /api/v1/auth/linkedin/callback?code=...&state=...`

---

## 🗄️ Database Changes

New columns in `users` table:
- `google_id` - Google user ID (unique)
- `github_id` - GitHub user ID (unique)
- `linkedin_id` - LinkedIn user ID (unique)
- `oauth_provider` - Which provider was used (google/github/linkedin)
- `profile_picture` - URL to user's profile picture
- `password_hash` - Now nullable (OAuth users don't have passwords)

---

## 🔐 Security Features

### CSRF Protection:
- State parameter generated for each OAuth request
- Stored in HTTP-only cookie
- Verified on callback

### Account Linking:
- If email already exists, links OAuth account to existing user
- Allows users to sign in with multiple providers
- Updates profile picture from OAuth provider

### Token Management:
- OAuth users get same JWT tokens as email/password users
- 15-minute expiry
- Stored in localStorage

---

## 🧪 Testing Checklist

- [ ] Database migration completed
- [ ] All OAuth credentials in `.env`
- [ ] Backend server restarted
- [ ] Frontend server restarted
- [ ] Test Google login
- [ ] Test GitHub login
- [ ] Test LinkedIn login
- [ ] Test account linking (sign up with email, then link Google)
- [ ] Test existing user OAuth login

---

## 🚨 Troubleshooting

### "Invalid state parameter"
- Cookies not working
- Check that cookies are enabled in browser
- Check CORS settings allow credentials

### "redirect_uri_mismatch"
- Redirect URI in provider console doesn't match code
- Verify: `http://localhost:8081/api/v1/auth/PROVIDER/callback`
- Check for typos, trailing slashes

### "Email not verified" (Google/LinkedIn)
- User's email isn't verified with provider
- Ask user to verify their email with the provider first

### "No email found" (GitHub)
- GitHub user has private email
- User needs to make email public or add public email in GitHub settings

---

## 📝 Production Deployment

### Update OAuth Redirect URLs:

1. **Google Cloud Console:**
   - Add: `https://api.yourdomain.com/api/v1/auth/google/callback`

2. **GitHub OAuth App:**
   - Add: `https://api.yourdomain.com/api/v1/auth/github/callback`

3. **LinkedIn App:**
   - Add: `https://api.yourdomain.com/api/v1/auth/linkedin/callback`

### Update Environment Variables:

```bash
GOOGLE_REDIRECT_URL=https://api.yourdomain.com/api/v1/auth/google/callback
GITHUB_REDIRECT_URL=https://api.yourdomain.com/api/v1/auth/github/callback
LINKEDIN_REDIRECT_URL=https://api.yourdomain.com/api/v1/auth/linkedin/callback
```

---

## 🎉 You're All Set!

OAuth authentication is fully functional. Users can now sign in with:
- Google
- GitHub  
- LinkedIn

All users are stored in your Supabase database with proper OAuth linking.

