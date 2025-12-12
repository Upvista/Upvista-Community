# Asteria Backend API

> **Created by:** Hamza Hafeez - Founder & CEO  
> **Version:** 1.0.0  
> **Status:** Production-Ready ✅

A complete, enterprise-grade backend API system built with Go, featuring JWT authentication, OAuth social login, session management, GDPR compliance, and professional email notifications.

## ✨ Features

**Authentication (16 endpoints):**
- Email/password authentication with verification
- OAuth social login (Google, GitHub, LinkedIn)
- Password reset flow with email links
- JWT tokens with automatic expiry and blacklisting
- Session tracking across multiple devices

**Account Management (14 endpoints):**
- Complete profile management
- Profile picture upload (Supabase Storage)
- Change password, email, username (with restrictions)
- Deactivate or permanently delete account
- GDPR data export
- View and manage active sessions

**Email System:**
- 8 professional, branded email templates
- Automated security notifications
- SMTP support (Gmail, SendGrid, AWS SES)

**Security:**
- bcrypt password hashing, JWT authentication, rate limiting
- Session token hashing, email verification required
- CSRF protection for OAuth, input validation
- 15+ enterprise-grade security features

## 🚀 Quick Start

### Prerequisites

- Go 1.19 or higher
- Supabase account (free tier)
- SMTP credentials (Gmail/SendGrid)

### Installation (15 minutes)

1. **Clone and setup:**
   ```bash
   cd backend
   go mod tidy
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

3. **Run database migration:**
   - Open Supabase SQL Editor
   - Run `scripts/migrate.sql`

4. **Start server:**
   ```bash
   go run main.go
   ```

5. **Test:**
   ```bash
   curl http://localhost:8081/health
   ```

**✅ Server running!** See [📚 Documentation](#documentation) for complete guides.

The server will start on `http://localhost:8081`

## 📡 API Endpoints (30 Total)

### Authentication (16 endpoints)
- `POST /auth/register` - Create account
- `POST /auth/verify-email` - Verify email with code
- `POST /auth/login` - Login with credentials
- `POST /auth/logout` - Logout and blacklist token
- `GET /auth/me` - Get current user
- `POST /auth/refresh` - Refresh JWT token
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password
- OAuth Google (3 endpoints): login, callback, exchange
- OAuth GitHub (3 endpoints): login, callback, exchange
- OAuth LinkedIn (3 endpoints): login, callback, exchange

### Account Management (14 endpoints)
- `GET /account/profile` - Get profile
- `PATCH /account/profile` - Update profile
- `POST /account/profile-picture` - Upload picture
- `POST /account/change-password` - Change password
- `POST /account/change-email` - Request email change
- `POST /account/verify-email-change` - Verify new email
- `POST /account/change-username` - Change username
- `POST /account/deactivate` - Soft delete account
- `DELETE /account/delete` - Permanently delete
- `GET /account/export-data` - Export data (GDPR)
- `GET /account/sessions` - View active sessions
- `DELETE /account/sessions/:id` - Logout from device
- `POST /account/logout-all` - Logout all devices

**Complete API documentation:** [docs/05_API_REFERENCE.md](./docs/05_API_REFERENCE.md)

## Project Structure

```
backend/
├── main.go          # Main application file
├── go.mod           # Go module file
├── go.sum           # Go module checksums
└── README.md        # This file
```

## Development

To run in development mode:
```bash
go run main.go
```

To build the application:
```bash
go build -o asteria-backend main.go
```

## Deployment

### Deploy to Render

This application is configured for deployment on Render.com:

1. **Push your code to GitHub** (make sure the backend folder is in your repository)

2. **Connect to Render**:
   - Go to [render.com](https://render.com)
   - Sign up/Login with your GitHub account
   - Click "New +" and select "Web Service"

3. **Configure the service**:
   - Connect your GitHub repository
   - Set the following:
     - **Name**: `asteria-backend`
     - **Root Directory**: `backend`
     - **Environment**: `Docker`
     - **Dockerfile Path**: `./Dockerfile`
     - **Plan**: `Free` (or upgrade as needed)

4. **Environment Variables** (optional):
   - `GIN_MODE`: `release` (for production mode)
   - `PORT`: `10000` (Render's default port)

5. **Deploy**:
   - Click "Create Web Service"
   - Render will automatically build and deploy your application
   - Your API will be available at `https://your-app-name.onrender.com`

### Manual Docker Deployment

You can also deploy using Docker:

```bash
# Build the Docker image
docker build -t asteria-backend .

# Run the container
docker run -p 8080:8080 asteria-backend
```

## 📚 Documentation

**Complete documentation available in [docs/](./docs/) folder:**

### Getting Started
- **[01_OVERVIEW.md](./docs/01_OVERVIEW.md)** - System overview and features
- **[03_QUICK_START.md](./docs/03_QUICK_START.md)** - Get running in 15 minutes
- **[04_INSTALLATION_GUIDE.md](./docs/04_INSTALLATION_GUIDE.md)** - Complete setup guide

### Technical Reference
- **[02_ARCHITECTURE.md](./docs/02_ARCHITECTURE.md)** - System architecture and design
- **[05_API_REFERENCE.md](./docs/05_API_REFERENCE.md)** - All 30 endpoints documented
- **[06_DATABASE_SCHEMA.md](./docs/06_DATABASE_SCHEMA.md)** - Database structure
- **[07_SECURITY_GUIDE.md](./docs/07_SECURITY_GUIDE.md)** - Security features

### Configuration
- **[08_CONFIGURATION.md](./docs/08_CONFIGURATION.md)** - Environment variables
- **[09_EMAIL_SYSTEM.md](./docs/09_EMAIL_SYSTEM.md)** - Email templates & SMTP
- **[10_OAUTH_INTEGRATION.md](./docs/10_OAUTH_INTEGRATION.md)** - Social login setup

### Operations
- **[11_DEPLOYMENT_GUIDE.md](./docs/11_DEPLOYMENT_GUIDE.md)** - Production deployment
- **[12_TROUBLESHOOTING.md](./docs/12_TROUBLESHOOTING.md)** - Common issues
- **[13_EXTENDING_SYSTEM.md](./docs/13_EXTENDING_SYSTEM.md)** - Add custom features
- **[14_MIGRATION_CHANGELOG.md](./docs/14_MIGRATION_CHANGELOG.md)** - Version history

**Start here:** [docs/01_OVERVIEW.md](./docs/01_OVERVIEW.md)

---

## 🎯 What Can Users Do?

✅ Register with email verification  
✅ Login with password or social accounts (Google/GitHub/LinkedIn)  
✅ Reset forgotten passwords  
✅ Update profile information  
✅ Upload profile pictures  
✅ Change email, password, username securely  
✅ View all active login sessions  
✅ Logout from specific devices  
✅ Deactivate or delete account  
✅ Export all personal data (GDPR)  

---

## 📊 System Statistics

- **30 API Endpoints** - Complete functionality
- **8 Email Templates** - Professional communications
- **2 Database Tables** - Optimized schema
- **15+ Security Features** - Enterprise-grade
- **14 Documentation Guides** - Comprehensive
- **~3,000 Lines of Code** - Production-ready
- **3 OAuth Providers** - Social login

---

## 🛡️ Security Features

✅ bcrypt password hashing (cost 14)  
✅ JWT authentication with 15-min expiry  
✅ Rate limiting (prevents brute force)  
✅ Session tracking with token hashing  
✅ Email verification required  
✅ CSRF protection for OAuth  
✅ Input validation at multiple layers  
✅ SQL injection prevention  
✅ GDPR compliant data export  

---

## 💡 Use Cases

Perfect for:
- Social networking platforms
- SaaS applications
- E-commerce sites
- Educational platforms
- Community platforms
- Mobile app backends
- Corporate applications

---

## 🏆 Why This System?

**vs. Auth0/Firebase:**
- ✅ Free (self-hosted)
- ✅ Full source code access
- ✅ No vendor lock-in
- ✅ 100% data ownership
- ✅ Unlimited customization

**vs. Building from Scratch:**
- ✅ Saves 3-4 weeks development
- ✅ Production-ready security
- ✅ Professional email templates
- ✅ Comprehensive documentation
- ✅ Battle-tested code

---

## 🙏 Credits

**Created by:** Hamza Hafeez - Founder & CEO

**Purpose:** Build powerful, reusable systems that developers love

**License:** Free to use in personal and commercial projects

---

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Follow existing code patterns
4. Add tests for new features
5. Update documentation
6. Submit a pull request
