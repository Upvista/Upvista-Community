# Extending the System - Developer Guide

> **Created by:** Hamza Hafeez - Founder & CEO of Upvista  
> **Document:** How to Add New Features

---

## 🎯 Adding a New Endpoint

### **Example: Add "Change Phone Number" Feature**

**Step 1: Add Model** (`internal/models/user.go`)
```go
type ChangePhoneRequest struct {
    NewPhone string `json:"new_phone" validate:"required"`
    Password string `json:"password" validate:"required"`
}
```

**Step 2: Add Repository Method** (`internal/repository/user.go`)
```go
UpdatePhone(ctx context.Context, userID uuid.UUID, phone string) error
```

**Step 3: Implement Repository** (`internal/repository/supabase_user_repository.go`)
```go
func (r *SupabaseUserRepository) UpdatePhone(ctx, userID, phone) error {
    update := map[string]interface{}{"phone": phone}
    // ... Supabase PATCH request
}
```

**Step 4: Add Service Method** (`internal/account/service.go`)
```go
func (s *AccountService) ChangePhone(ctx, userID, req) error {
    // Validate password
    // Check phone format
    // Update database
    // Send notification email
}
```

**Step 5: Add Handler** (`internal/account/handlers.go`)
```go
func (h *AccountHandlers) ChangePhoneHandler(c *gin.Context) {
    // Parse request
    // Call service
    // Return response
}
```

**Step 6: Register Route** (`internal/account/handlers.go`)
```go
account.POST("/change-phone", h.ChangePhoneHandler)
```

**Done!** New endpoint ready to use.

---

## 📧 Adding Email Template

### **Example: "Phone Changed" Email**

In `internal/utils/email.go`:
```go
func (e *EmailService) SendPhoneChangedEmail(to, displayName, newPhone) error {
    subject := "Phone Number Changed - Upvista Community"
    body := fmt.Sprintf(`
        <!DOCTYPE html>
        <html>
        <body>
            <!-- Professional template here -->
            <p>Your phone: %s</p>
        </body>
        </html>
    `, newPhone)
    return e.sendEmail(to, subject, body)
}
```

---

## 🔐 Adding OAuth Provider

### **Example: Add Apple Sign-In**

**Step 1:** Create `internal/auth/oauth_apple.go`  
**Step 2:** Implement GetAuthURL and HandleCallback  
**Step 3:** Add to config  
**Step 4:** Register routes  

Pattern same as Google/GitHub/LinkedIn.

---

**Created by Hamza Hafeez - Founder & CEO of Upvista**

