# API Reference - Complete Endpoint Documentation

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Complete API Reference for all 30 endpoints  
> **Base URL:** `http://localhost:8081/api/v1` (development)

---

## 📚 Quick Navigation

**Authentication (16 endpoints):**
- [POST /auth/register](#post-authregister) - Create account
- [POST /auth/verify-email](#post-authverify-email) - Verify email
- [POST /auth/login](#post-authlogin) - Login
- [POST /auth/logout](#post-authlogout) - Logout
- [GET /auth/me](#get-authme) - Get current user
- [POST /auth/refresh](#post-authrefresh) - Refresh token
- [POST /auth/forgot-password](#post-authforgot-password) - Request password reset
- [POST /auth/reset-password](#post-authreset-password) - Reset password
- [OAuth Google](#oauth-google-3-endpoints) - 3 endpoints
- [OAuth GitHub](#oauth-github-3-endpoints) - 3 endpoints
- [OAuth LinkedIn](#oauth-linkedin-3-endpoints) - 3 endpoints

**Account Management (14 endpoints):**
- [GET /account/profile](#get-accountprofile) - Get profile
- [PATCH /account/profile](#patch-accountprofile) - Update profile
- [POST /account/profile-picture](#post-accountprofile-picture) - Upload picture
- [POST /account/change-password](#post-accountchange-password) - Change password
- [POST /account/change-email](#post-accountchange-email) - Change email
- [POST /account/verify-email-change](#post-accountverify-email-change) - Verify new email
- [POST /account/change-username](#post-accountchange-username) - Change username
- [POST /account/deactivate](#post-accountdeactivate) - Deactivate account
- [DELETE /account/delete](#delete-accountdelete) - Delete account
- [GET /account/export-data](#get-accountexport-data) - Export data (GDPR)
- [GET /account/sessions](#get-accountsessions) - View sessions
- [DELETE /account/sessions/:id](#delete-accountsessionsid) - Logout from device
- [POST /account/logout-all](#post-accountlogout-all) - Logout all devices

---

## 🔑 Authentication

All account management endpoints require JWT token:
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Get token from: login, verify-email, or OAuth exchange responses.

---

## 📘 Authentication Endpoints

### POST /auth/register

Create a new user account.

**Request:**
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123",
  "username": "cooluser",
  "display_name": "John Doe",
  "age": 25
}
```

**Validations:**
- Email: Valid format, unique
- Password: Min 6 characters
- Username: 3-20 chars, alphanumeric, unique
- Display name: 2-50 chars
- Age: 13-120 years

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Registration successful. Please check your email for verification code.",
  "user_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

**Errors:**
- `409`: Email already exists
- `409`: Username already exists
- `400`: Invalid input (validation failed)

**Rate Limit:** 3 requests per minute per IP

**Email Sent:** Verification code (6 digits) to user's email

---

### POST /auth/verify-email

Verify email address with 6-digit code.

**Request:**
```http
POST /api/v1/auth/verify-email
Content-Type: application/json

{
  "email": "user@example.com",
  "verification_code": "123456"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Email verified successfully",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2025-11-01T15:45:00Z",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "username": "cooluser",
    "display_name": "John Doe",
    "age": 25,
    "is_email_verified": true,
    "is_active": true,
    "created_at": "2025-11-01T15:30:00Z"
  }
}
```

**Errors:**
- `400`: Invalid verification code
- `400`: Verification code expired (1 hour expiry)
- `404`: User not found

**Email Sent:** Welcome email after successful verification

---

### POST /auth/login

Login with email/username and password.

**Request:**
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email_or_username": "cooluser",
  "password": "SecurePassword123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2025-11-01T15:45:00Z",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "username": "cooluser",
    "display_name": "John Doe",
    "age": 25,
    "is_email_verified": true,
    "last_login_at": "2025-11-01T15:30:00Z"
  }
}
```

**Errors:**
- `401`: Invalid credentials
- `401`: Email not verified
- `403`: Account inactive

**Rate Limit:** 5 requests per minute per IP

**Session Created:** Automatically tracks this login

---

### POST /auth/logout

Logout current session.

**Auth Required:** ✅ Yes

**Request:**
```http
POST /api/v1/auth/logout
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

**What Happens:**
- JWT token blacklisted
- Session removed from database
- Token can't be used again

---

### GET /auth/me

Get current user information.

**Auth Required:** ✅ Yes

**Request:**
```http
GET /api/v1/auth/me
Authorization: Bearer <token>
```

**Response:** Same as login response (user object)

---

### POST /auth/refresh

Refresh JWT token (get new token before expiry).

**Auth Required:** ✅ Yes

**Request:**
```http
POST /api/v1/auth/refresh
Authorization: Bearer <current_token>
```

**Response:**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "token": "new_token_here",
  "expires_at": "2025-11-01T16:00:00Z"
}
```

---

### POST /auth/forgot-password

Request password reset link.

**Request:**
```http
POST /api/v1/auth/forgot-password
Content-Type: application/json

{
  "email": "user@example.com"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "If the email exists, a password reset link has been sent."
}
```

**Security Note:** Always returns success (doesn't reveal if email exists)

**Email Sent:** Password reset link (1-hour expiry)

---

### POST /auth/reset-password

Reset password with token from email.

**Request:**
```http
POST /api/v1/auth/reset-password
Content-Type: application/json

{
  "token": "reset_token_from_email",
  "new_password": "NewSecurePassword456"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

**Errors:**
- `400`: Invalid or expired token
- `400`: Password too short

---

## 🔐 OAuth Endpoints

### OAuth Google (3 endpoints)

**1. GET /auth/google/login**

Initiate Google OAuth flow.

**Response:**
```json
{
  "auth_url": "https://accounts.google.com/o/oauth2/v2/auth?client_id=...",
  "state": "random_state_string"
}
```

Frontend should:
1. Store `state` in sessionStorage
2. Redirect to `auth_url`

**2. GET /auth/google/callback**

Google redirects here after user authorizes.

**3. POST /auth/google/exchange**

Exchange authorization code for JWT.

**Request:**
```json
{
  "code": "authorization_code_from_google"
}
```

**Response:** Same as login (token + user)

---

### OAuth GitHub (3 endpoints)

- GET `/auth/github/login` - Initiate flow
- GET `/auth/github/callback` - GitHub redirects here
- POST `/auth/github/exchange` - Get JWT token

Same pattern as Google OAuth.

---

### OAuth LinkedIn (3 endpoints)

- GET `/auth/linkedin/login` - Initiate flow
- GET `/auth/linkedin/callback` - LinkedIn redirects here
- POST `/auth/linkedin/exchange` - Get JWT token

Same pattern as Google OAuth.

---

## 👤 Account Management Endpoints

### GET /account/profile

Get current user's profile.

**Auth Required:** ✅ Yes

**Request:**
```http
GET /api/v1/account/profile
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "username": "cooluser",
    "display_name": "John Doe",
    "age": 25,
    "is_email_verified": true,
    "oauth_provider": null,
    "profile_picture": "https://...",
    "is_active": true,
    "last_login_at": "2025-11-01T15:30:00Z",
    "created_at": "2025-10-15T08:00:00Z",
    "updated_at": "2025-11-01T15:30:00Z"
  }
}
```

---

### PATCH /account/profile

Update profile information.

**Auth Required:** ✅ Yes

**Request:**
```http
PATCH /api/v1/account/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "display_name": "Jane Smith",
  "age": 26,
  "profile_picture": "https://example.com/avatar.jpg"
}
```

**All fields optional** - only send what you want to update.

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": { updated user object }
}
```

**Validations:**
- display_name: 2-50 chars
- age: 13-120
- profile_picture: Valid URL

---

### POST /account/profile-picture

Upload profile picture (image file).

**Auth Required:** ✅ Yes

**Request:**
```http
POST /api/v1/account/profile-picture
Authorization: Bearer <token>
Content-Type: multipart/form-data

profile_picture=<file>
```

**curl example:**
```bash
curl -X POST http://localhost:8081/api/v1/account/profile-picture \
  -H "Authorization: Bearer $TOKEN" \
  -F "profile_picture=@/path/to/image.jpg"
```

**Response:**
```json
{
  "success": true,
  "message": "Profile picture uploaded successfully",
  "profile_picture": "https://xxx.supabase.co/storage/v1/object/public/profile-pictures/user-id/uuid.jpg"
}
```

**Validations:**
- File size: Max 5MB
- File type: jpeg, png, gif, webp only
- Field name: Must be "profile_picture"

---

### POST /account/change-password

Change password (requires current password).

**Auth Required:** ✅ Yes

**Request:**
```json
{
  "current_password": "OldPassword123",
  "new_password": "NewSecurePass456",
  "confirm_password": "NewSecurePass456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Errors:**
- `401`: Current password incorrect
- `400`: Passwords don't match
- `400`: New password same as current
- `400`: Cannot change password for OAuth-only accounts

**Email Sent:** Password changed notification

---

### POST /account/change-email

Request email change (Step 1 of 2).

**Auth Required:** ✅ Yes

**Request:**
```json
{
  "new_email": "newemail@example.com",
  "password": "current_password"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Verification code sent to new email address"
}
```

**Emails Sent:**
1. **To new address:** 6-digit verification code
2. **To old address:** Security notification

**Errors:**
- `401`: Password incorrect
- `400`: New email same as current
- `409`: Email already in use

---

### POST /account/verify-email-change

Complete email change (Step 2 of 2).

**Auth Required:** ✅ Yes

**Request:**
```json
{
  "verification_code": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Email changed successfully"
}
```

**Errors:**
- `400`: Invalid code
- `400`: Code expired (1 hour)
- `400`: No pending email change

---

### POST /account/change-username

Change username (once per 30 days).

**Auth Required:** ✅ Yes

**Request:**
```json
{
  "new_username": "newusername",
  "password": "current_password"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Username changed successfully"
}
```

**Errors:**
- `401`: Password incorrect
- `400`: Changed within last 30 days
- `409`: Username already taken
- `400`: Username invalid format

**Email Sent:** Username changed notification

**Restriction:** Can only change once every 30 days

---

### POST /account/deactivate

Soft delete account (reversible).

**Auth Required:** ✅ Yes

**Request:**
```json
{
  "password": "current_password",
  "reason": "Optional feedback message"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Account deactivated successfully"
}
```

**What Happens:**
- Sets `is_active = false`
- User can't login
- Data preserved (can reactivate later)

---

### DELETE /account/delete

Permanently delete account (irreversible).

**Auth Required:** ✅ Yes

**Request:**
```json
{
  "password": "current_password",
  "confirmation": "DELETE MY ACCOUNT"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

**Errors:**
- `401`: Password incorrect
- `400`: Confirmation text incorrect

**Email Sent:** Account deletion confirmation

**⚠️ Warning:** This permanently deletes all user data. Cannot be undone!

---

### GET /account/export-data

Export all user data (GDPR compliance).

**Auth Required:** ✅ Yes

**Request:**
```http
GET /api/v1/account/export-data
Authorization: Bearer <token>
```

**Response:** (Downloads as JSON file)
```json
{
  "personal_information": {
    "id": "...",
    "email": "...",
    "username": "...",
    "display_name": "...",
    "age": 25
  },
  "account_status": {
    "is_email_verified": true,
    "is_active": true,
    "oauth_provider": null
  },
  "profile": {
    "profile_picture": "..."
  },
  "account_dates": {
    "created_at": "...",
    "updated_at": "...",
    "last_login_at": "...",
    "username_changed_at": null
  },
  "active_sessions": [...],
  "export_metadata": {
    "exported_at": "2025-11-01T12:00:00Z",
    "export_version": "1.0",
    "format": "JSON"
  }
}
```

---

### GET /account/sessions

View all active login sessions.

**Auth Required:** ✅ Yes

**Response:**
```json
{
  "success": true,
  "sessions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "123e4567-e89b-12d3-a456-426614174000",
      "ip_address": "192.168.1.100",
      "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
      "expires_at": "2025-11-01T15:45:00Z",
      "created_at": "2025-11-01T15:30:00Z"
    }
  ]
}
```

---

### DELETE /account/sessions/:id

Logout from specific device.

**Auth Required:** ✅ Yes

**Request:**
```http
DELETE /api/v1/account/sessions/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Session deleted successfully. You have been logged out from that device."
}
```

---

### POST /account/logout-all

Logout from all devices.

**Auth Required:** ✅ Yes

**Response:**
```json
{
  "success": true,
  "message": "Logged out from all devices successfully"
}
```

**⚠️ Note:** This logs you out from ALL devices, including current one.

---

## 📊 Response Format

All endpoints follow consistent format:

**Success:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }  // Optional
}
```

**Error:**
```json
{
  "success": false,
  "message": "Human-readable error message"
}
```

**HTTP Status Codes:**
- `200` - Success
- `400` - Bad request (validation error)
- `401` - Unauthorized (invalid/missing token or wrong password)
- `403` - Forbidden (insufficient permissions)
- `404` - Not found
- `409` - Conflict (duplicate email/username)
- `429` - Too many requests (rate limited)
- `500` - Internal server error

---

## 🧪 Testing Examples

**Complete workflow:**
```bash
BASE="http://localhost:8081/api/v1"

# 1. Register
curl -X POST $BASE/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123","username":"test","display_name":"Test","age":25}'

# 2. Verify (check email for code)
curl -X POST $BASE/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","verification_code":"123456"}'

# 3. Save token
TOKEN="token_from_response"

# 4. Get profile
curl -X GET $BASE/account/profile \
  -H "Authorization: Bearer $TOKEN"

# 5. Update profile
curl -X PATCH $BASE/account/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"display_name":"Updated Name"}'

# 6. View sessions
curl -X GET $BASE/account/sessions \
  -H "Authorization: Bearer $TOKEN"

# 7. Export data
curl -X GET $BASE/account/export-data \
  -H "Authorization: Bearer $TOKEN" \
  -o my-data.json
```

---

## 📱 Frontend Integration Examples

### React/Next.js:

```typescript
const API_BASE = '/api/proxy/api/v1';

// Register
async function register(data) {
  const response = await fetch(`${API_BASE}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  return response.json();
}

// Login
async function login(emailOrUsername, password) {
  const response = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email_or_username: emailOrUsername, password })
  });
  const data = await response.json();
  if (data.success) {
    localStorage.setItem('token', data.token);
  }
  return data;
}

// Get Profile
async function getProfile() {
  const token = localStorage.getItem('token');
  const response = await fetch(`${API_BASE}/account/profile`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return response.json();
}

// Upload Profile Picture
async function uploadPicture(file) {
  const token = localStorage.getItem('token');
  const formData = new FormData();
  formData.append('profile_picture', file);
  
  const response = await fetch(`${API_BASE}/account/profile-picture`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: formData
  });
  return response.json();
}
```

---

**For complete details on all 30 endpoints, see the sections above.**

**Created by Hamza Hafeez - Founder & CEO of Upvista**

---

**[← Installation Guide](./04_INSTALLATION_GUIDE.md)** | **[Next: Database Schema →](./06_DATABASE_SCHEMA.md)**

