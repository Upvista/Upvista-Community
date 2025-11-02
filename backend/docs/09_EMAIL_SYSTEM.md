# Email System Documentation

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** Email Templates & SMTP Configuration

---

## 📧 Email Templates (8 Total)

### **1. Email Verification**
- **Sent:** After registration
- **Contains:** 6-digit code
- **Purpose:** Verify email ownership
- **Expiry:** 1 hour

### **2. Welcome Email**
- **Sent:** After successful verification
- **Contains:** Welcome message, getting started tips
- **Purpose:** User onboarding

### **3. Password Reset**
- **Sent:** When user forgets password
- **Contains:** Reset link (1-hour expiry)
- **Purpose:** Account recovery

### **4. Password Changed**
- **Sent:** After password change
- **Contains:** Change timestamp, security alert
- **Purpose:** Security notification

### **5. Account Deleted**
- **Sent:** After account deletion
- **Contains:** Deletion confirmation
- **Purpose:** Final notification

### **6. Email Change Verification**
- **Sent:** To NEW email when changing
- **Contains:** 6-digit code
- **Purpose:** Verify new email ownership

### **7. Email Change Alert**
- **Sent:** To OLD email when changing
- **Contains:** Security alert, what's happening
- **Purpose:** Security notification

### **8. Username Changed**
- **Sent:** After username change
- **Contains:** Old → new username
- **Purpose:** Security notification

---

## 🎨 Design System

All emails follow professional, executive design:
- Dark gradient headers (#1a1f3a → #2d3561)
- Clean typography
- Responsive (mobile-friendly)
- No emojis, no childish colors
- Security notices highlighted
- Upvista branding

---

## 🔧 SMTP Configuration

### **Gmail (Development):**
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your@gmail.com
SMTP_PASSWORD=app_password_here
```

### **SendGrid (Production):**
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=SG.your_api_key
```

### **AWS SES (Enterprise):**
```bash
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USERNAME=AKIAIOSFODNN7EXAMPLE
SMTP_PASSWORD=wJalrXUtnFEMI/K7MDENG
```

---

**Created by Hamza Hafeez - Founder & CEO of Upvista**

