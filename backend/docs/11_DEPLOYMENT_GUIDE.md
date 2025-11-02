# Production Deployment Guide

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Deploy to Production

---

## 🚀 Deployment Options

### **1. Render.com (Easiest, Free Tier)**

**Steps:**
1. Push code to GitHub
2. Connect Render to GitHub repo
3. Create Web Service
4. Set root directory: `backend`
5. Build command: `go build -o main main.go`
6. Start command: `./main`
7. Add environment variables
8. Deploy!

**Cost:** $0/month (free tier) or $7/month (starter)

---

### **2. Railway.app (Simple, $5/month)**

1. Connect GitHub repo
2. Select `backend` folder
3. Add environment variables
4. Auto-deploys on git push

---

### **3. Fly.io (Global Edge)**

1. Install flyctl CLI
2. `fly launch` in backend folder
3. Configure fly.toml
4. `fly deploy`

---

### **4. Docker (Any Platform)**

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o main main.go

FROM alpine:latest
COPY --from=builder /app/main /main
CMD ["/main"]
```

Build and run:
```bash
docker build -t upvista-auth .
docker run -p 8081:8081 --env-file .env upvista-auth
```

---

## ⚙️ Production Configuration

### **Environment Variables (Production):**

```bash
# Use production Supabase
SUPABASE_URL=https://prod-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=prod_key_here

# Strong JWT secret (48+ chars)
JWT_SECRET=production_secret_completely_different_from_dev

# Production mode
GIN_MODE=release

# Production frontend
FRONTEND_URL=https://yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com

# Production email (SendGrid recommended)
SMTP_HOST=smtp.sendgrid.net
SMTP_USERNAME=apikey
SMTP_PASSWORD=SG.production_key
```

---

## ✅ Pre-Deployment Checklist

- [ ] Create production Supabase project
- [ ] Run database migration in production
- [ ] Create Supabase storage bucket
- [ ] Setup production SMTP (SendGrid/SES)
- [ ] Generate strong JWT secret
- [ ] Configure all environment variables
- [ ] Test all endpoints in staging
- [ ] Setup domain and SSL
- [ ] Configure CORS for production domain
- [ ] Enable monitoring/logging
- [ ] Setup database backups
- [ ] Test email deliverability

---

**Created by Hamza Hafeez - Founder & CEO of Upvista**

