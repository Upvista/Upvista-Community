package utils

import (
	"fmt"
	"math/rand"
	"time"

	"upvista-community-backend/internal/config"

	"net/smtp"

	"github.com/jordan-wright/email"
)

// EmailService handles email operations
type EmailService struct {
	config *config.EmailConfig
}

// NewEmailService creates a new email service
func NewEmailService(emailConfig *config.EmailConfig) *EmailService {
	return &EmailService{
		config: emailConfig,
	}
}

// GenerateVerificationCode generates a 6-digit verification code
func (e *EmailService) GenerateVerificationCode() string {
	rand.Seed(time.Now().UnixNano())
	return fmt.Sprintf("%06d", rand.Intn(1000000))
}

// SendVerificationEmail sends an email verification code
func (e *EmailService) SendVerificationEmail(to, code string) error {
	subject := "Verify Your UpVista Community Account"
	body := fmt.Sprintf(`
		<html>
		<body>
			<h2>Welcome to UpVista Community!</h2>
			<p>Thank you for registering. Please use the following code to verify your email address:</p>
			<h3 style="color: #007bff; font-size: 24px; letter-spacing: 2px;">%s</h3>
			<p>This code will expire in 10 minutes.</p>
			<p>If you didn't create an account, please ignore this email.</p>
			<br>
			<p>Best regards,<br>UpVista Community Team</p>
		</body>
		</html>
	`, code)

	return e.sendEmail(to, subject, body)
}

// SendPasswordResetEmail sends a password reset email
func (e *EmailService) SendPasswordResetEmail(to, resetToken string) error {
	subject := "Reset Your UpVista Community Password"
	resetURL := fmt.Sprintf("http://localhost:3000/reset-password?token=%s", resetToken)
	body := fmt.Sprintf(`
		<html>
		<body>
			<h2>Password Reset Request</h2>
			<p>You requested to reset your password. Click the link below to reset your password:</p>
			<a href="%s" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Reset Password</a>
			<p>This link will expire in 1 hour.</p>
			<p>If you didn't request a password reset, please ignore this email.</p>
			<br>
			<p>Best regards,<br>UpVista Community Team</p>
		</body>
		</html>
	`, resetURL)

	return e.sendEmail(to, subject, body)
}

// SendWelcomeEmail sends a welcome email after successful verification
func (e *EmailService) SendWelcomeEmail(to, displayName string) error {
	subject := "Welcome to UpVista Community!"
	body := fmt.Sprintf(`
		<html>
		<body>
			<h2>Welcome %s!</h2>
			<p>Your email has been successfully verified. You can now start using UpVista Community.</p>
			<p>Explore our features:</p>
			<ul>
				<li>Connect with professionals</li>
				<li>Share your projects</li>
				<li>Find freelance opportunities</li>
				<li>Build your network</li>
			</ul>
			<p>If you have any questions, feel free to contact our support team.</p>
			<br>
			<p>Best regards,<br>UpVista Community Team</p>
		</body>
		</html>
	`, displayName)

	return e.sendEmail(to, subject, body)
}

// sendEmail is a helper method to send emails
func (e *EmailService) sendEmail(to, subject, body string) error {
	mail := email.NewEmail()
	mail.From = fmt.Sprintf("%s <%s>", e.config.FromName, e.config.FromEmail)
	mail.To = []string{to}
	mail.Subject = subject
	mail.HTML = []byte(body)

	// Send email using SMTP
	err := mail.Send(fmt.Sprintf("%s:%d", e.config.Host, e.config.Port),
		smtp.PlainAuth("", e.config.Username, e.config.Password, e.config.Host))

	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}

	return nil
}

// ValidateEmailFormat validates email format (basic validation)
func ValidateEmailFormat(email string) bool {
	// Basic email validation - in production, use a more robust validator
	if len(email) < 5 {
		return false
	}

	hasAt := false
	hasDot := false

	for i, char := range email {
		if char == '@' {
			if hasAt || i == 0 || i == len(email)-1 {
				return false
			}
			hasAt = true
		}
		if char == '.' && hasAt {
			hasDot = true
		}
	}

	return hasAt && hasDot
}
