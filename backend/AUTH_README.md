# UpVista Community - Authentication System

## 🚀 Quick Start

### 1. Environment Setup

Copy the environment template and configure your settings:

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```bash
# Database Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-minimum-32-characters-long
JWT_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=7d

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_NAME=UpVista Community
SMTP_FROM_EMAIL=noreply@upvista.com

# Server Configuration
PORT=8080
GIN_MODE=debug
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://your-app.vercel.app
```

### 2. Database Setup

Run the migration script in your Supabase SQL editor:

```sql
-- Copy and paste the contents of scripts/migrate.sql
-- This will create the users table and necessary indexes
```

### 3. Run the Server

```bash
go run main.go
```

The server will start on `http://localhost:8080`

## 📡 API Endpoints

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/auth/register` | User registration | No |
| POST | `/api/v1/auth/verify-email` | Email verification | No |
| POST | `/api/v1/auth/login` | User login | No |
| POST | `/api/v1/auth/logout` | User logout | Yes |
| POST | `/api/v1/auth/forgot-password` | Password reset request | No |
| POST | `/api/v1/auth/reset-password` | Password reset | No |
| GET | `/api/v1/auth/me` | Get current user | Yes |
| POST | `/api/v1/auth/refresh` | Refresh token | Yes |

## 🔐 Authentication Flow

### 1. User Registration

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "display_name": "John Doe",
    "username": "johndoe",
    "age": 25
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Registration successful. Please check your email for verification code.",
  "user_id": "uuid-here"
}
```

### 2. Email Verification

```bash
curl -X POST http://localhost:8080/api/v1/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "verification_code": "123456"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully",
  "token": "jwt-access-token",
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "username": "johndoe",
    "display_name": "John Doe",
    "is_email_verified": true
  }
}
```

### 3. User Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email_or_username": "user@example.com",
    "password": "password123"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "jwt-access-token",
  "expires_at": "2024-01-01T12:00:00Z",
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "username": "johndoe",
    "display_name": "John Doe",
    "is_email_verified": true
  }
}
```

### 4. Get Current User (Protected Route)

```bash
curl -X GET http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer your-jwt-token"
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "username": "johndoe",
    "display_name": "John Doe",
    "age": 25,
    "is_email_verified": true,
    "last_login_at": "2024-01-01T10:00:00Z",
    "created_at": "2024-01-01T09:00:00Z"
  }
}
```

## 🛡️ Security Features

- **Password Security**: bcrypt hashing with salt rounds = 12
- **JWT Tokens**: 15-minute expiry with secure generation
- **Email Verification**: 6-digit codes with 10-minute expiry
- **Input Validation**: Comprehensive validation for all fields
- **Rate Limiting**: Protection against brute force attacks
- **CORS**: Configured for frontend integration

## 📧 Email Configuration

The system supports SMTP email sending for:
- Email verification codes
- Password reset links
- Welcome emails

Configure your SMTP settings in the `.env` file. For Gmail, you'll need to:
1. Enable 2-factor authentication
2. Generate an app password
3. Use the app password in `SMTP_PASSWORD`

## 🗄️ Database Schema

### Users Table
- `id`: UUID primary key
- `email`: Unique email address
- `username`: Unique username (3-20 chars, alphanumeric + underscore)
- `password_hash`: bcrypt hashed password
- `display_name`: User's display name (2-50 chars)
- `age`: User's age (13-120)
- `is_email_verified`: Email verification status
- `email_verification_code`: 6-digit verification code
- `email_verification_expires_at`: Code expiry timestamp
- `password_reset_token`: Password reset token
- `password_reset_expires_at`: Reset token expiry
- `is_active`: Account status
- `last_login_at`: Last login timestamp
- `created_at`: Account creation timestamp
- `updated_at`: Last update timestamp

## 🔧 Development

### Project Structure
```
backend/
├── internal/
│   ├── auth/           # Authentication handlers, service, middleware
│   ├── models/         # Data models and request/response structs
│   ├── database/       # Database connection and operations
│   ├── utils/          # Utility functions (JWT, email, validation)
│   └── config/         # Configuration management
├── pkg/
│   └── errors/         # Custom error types
├── scripts/
│   └── migrate.sql     # Database migration script
└── main.go            # Application entry point
```

### Building
```bash
go build -o upvista-backend .
```

### Testing
```bash
go test ./...
```

## 🚀 Production Deployment

### Environment Variables
Ensure all required environment variables are set in production:
- Database credentials
- JWT secret (32+ characters)
- SMTP credentials
- CORS origins

### Security Considerations
- Use HTTPS in production
- Set `GIN_MODE=release`
- Use strong JWT secrets
- Configure proper CORS origins
- Monitor authentication attempts

## 📚 Next Steps

1. **Frontend Integration**: Connect your React/Next.js frontend
2. **Rate Limiting**: Implement Redis-based rate limiting
3. **Session Management**: Add Redis session storage
4. **Social Login**: Add OAuth providers (Google, GitHub)
5. **Two-Factor Authentication**: Implement TOTP-based 2FA
6. **Audit Logging**: Add comprehensive audit trails

## 🆘 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check Supabase URL and credentials
   - Ensure database is accessible
   - Verify SSL settings

2. **Email Not Sending**
   - Check SMTP credentials
   - Verify app password for Gmail
   - Check firewall settings

3. **JWT Token Invalid**
   - Ensure JWT_SECRET is set
   - Check token expiry
   - Verify token format

4. **CORS Issues**
   - Update CORS_ALLOWED_ORIGINS
   - Check frontend URL configuration

### Support

For issues and questions:
- Check the logs for detailed error messages
- Verify all environment variables are set
- Test database connectivity
- Validate email configuration

---

**Happy coding! 🎉**
