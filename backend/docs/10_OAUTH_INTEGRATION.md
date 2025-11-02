# OAuth Integration Guide - Social Login Setup

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Complete OAuth Setup for Google, GitHub, LinkedIn

---

## 🔐 OAuth Providers Supported

✅ Google Sign-In  
✅ GitHub Login  
✅ LinkedIn Login

---

## 🎯 Google OAuth Setup

### **Step 1: Google Cloud Console**
1. Go to: https://console.cloud.google.com
2. Create new project: "Upvista Auth"
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add redirect URI: `http://localhost:8081/api/v1/auth/google/callback`
6. For production: Add `https://yourdomain.com/api/v1/auth/google/callback`

### **Step 2: Get Credentials**
- Client ID: `123456-abc.apps.googleusercontent.com`
- Client Secret: `GOCSPX-xxxxx`

### **Step 3: Add to .env**
```bash
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
GOOGLE_REDIRECT_URL=http://localhost:8081/api/v1/auth/google/callback
```

---

## 🎯 GitHub OAuth Setup

### **Steps:**
1. GitHub Settings → Developer settings → OAuth Apps
2. New OAuth App
3. Callback: `http://localhost:8081/api/v1/auth/github/callback`
4. Get Client ID and generate Secret

### **Add to .env:**
```bash
GITHUB_CLIENT_ID=Iv1.xxxxx
GITHUB_CLIENT_SECRET=xxxxx
GITHUB_REDIRECT_URL=http://localhost:8081/api/v1/auth/github/callback
```

---

## 🎯 LinkedIn OAuth Setup

### **Steps:**
1. LinkedIn Developers → Create app
2. Add redirect: `http://localhost:8081/api/v1/auth/linkedin/callback`
3. Request scopes: openid, profile, email
4. Get credentials

### **Add to .env:**
```bash
LINKEDIN_CLIENT_ID=xxxxx
LINKEDIN_CLIENT_SECRET=xxxxx
LINKEDIN_REDIRECT_URL=http://localhost:8081/api/v1/auth/linkedin/callback
```

---

## 🔄 OAuth Flow

1. User clicks "Login with Google"
2. Frontend calls: GET `/auth/google/login`
3. Backend returns auth URL + state
4. Frontend redirects to Google
5. User authorizes
6. Google redirects to callback
7. Backend redirects to frontend with code
8. Frontend calls: POST `/auth/google/exchange`
9. Backend exchanges code for token
10. User logged in!

---

**Created by Hamza Hafeez - Founder & CEO of Upvista**

