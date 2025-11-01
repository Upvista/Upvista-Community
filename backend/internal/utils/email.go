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
	subject := "Verify Your Email Address - Upvista Community"
	body := fmt.Sprintf(`
<!DOCTYPE html>
	<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f7fa; line-height: 1.6;">
		<table width="100%%" cellpadding="0" cellspacing="0" style="background-color: #f5f7fa; padding: 40px 20px;">
		<tr>
			<td align="center">
					<table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); max-width: 600px;">
					<!-- Header -->
					<tr>
							<td style="background: linear-gradient(135deg, #1a1f3a 0%%, #2d3561 100%%); padding: 40px 50px; border-radius: 8px 8px 0 0;">
								<h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 600; letter-spacing: -0.5px;">UpVista Community</h1>
						</td>
					</tr>
					<!-- Content -->
					<tr>
							<td style="padding: 50px 50px 40px;">
								<h2 style="margin: 0 0 20px; color: #1a1f3a; font-size: 24px; font-weight: 600; letter-spacing: -0.3px;">Email Verification Required</h2>
								<p style="margin: 0 0 30px; color: #4a5568; font-size: 16px; line-height: 1.7;">Thank you for registering with UpVista Community. To complete your account setup, please verify your email address using the verification code below.</p>
							
							<!-- Verification Code Box -->
								<table width="100%%" cellpadding="0" cellspacing="0" style="margin: 35px 0;">
									<tr>
										<td align="center" style="background-color: #f7f9fc; border: 2px solid #e2e8f0; border-radius: 6px; padding: 30px 20px;">
											<div style="font-size: 36px; font-weight: 700; color: #1a1f3a; letter-spacing: 8px; font-family: 'Courier New', monospace;">%s</div>
									</td>
								</tr>
							</table>
							
								<p style="margin: 25px 0 0; color: #718096; font-size: 14px; line-height: 1.6;">This verification code will expire in <strong style="color: #1a1f3a;">10 minutes</strong>.</p>
								
								<div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e2e8f0;">
									<p style="margin: 0 0 15px; color: #718096; font-size: 13px; line-height: 1.6;">If you did not create an account with UpVista Community, please disregard this email. No further action is required.</p>
							</div>
						</td>
					</tr>
					<!-- Footer -->
					<tr>
							<td style="background-color: #f7f9fc; padding: 30px 50px; border-radius: 0 0 8px 8px; border-top: 1px solid #e2e8f0;">
								<p style="margin: 0 0 10px; color: #718096; font-size: 13px; line-height: 1.6;">UpVista Community</p>
								<p style="margin: 0; color: #a0aec0; font-size: 12px;">This is an automated message. Please do not reply to this email.</p>
									</td>
								</tr>
							</table>
					<!-- Footer Text -->
					<table width="600" cellpadding="0" cellspacing="0" style="max-width: 600px; margin-top: 20px;">
						<tr>
							<td align="center">
								<p style="margin: 0; color: #a0aec0; font-size: 12px;">© %d UpVista Community. All rights reserved.</p>
						</td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
</body>
</html>
	`, code, time.Now().Year())

	return e.sendEmail(to, subject, body)
}

// SendPasswordResetEmail sends a password reset email
func (e *EmailService) SendPasswordResetEmail(to, resetToken string) error {
	subject := "Password Reset Request - Upvista Community"
	resetURL := fmt.Sprintf("http://localhost:3000/reset-password?token=%s", resetToken)
	body := fmt.Sprintf(`
<!DOCTYPE html>
	<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f7fa; line-height: 1.6;">
		<table width="100%%" cellpadding="0" cellspacing="0" style="background-color: #f5f7fa; padding: 40px 20px;">
		<tr>
			<td align="center">
					<table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); max-width: 600px;">
					<!-- Header -->
					<tr>
							<td style="background: linear-gradient(135deg, #1a1f3a 0%%, #2d3561 100%%); padding: 40px 50px; border-radius: 8px 8px 0 0;">
								<h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 600; letter-spacing: -0.5px;">UpVista Community</h1>
						</td>
					</tr>
					<!-- Content -->
					<tr>
							<td style="padding: 50px 50px 40px;">
								<h2 style="margin: 0 0 20px; color: #1a1f3a; font-size: 24px; font-weight: 600; letter-spacing: -0.3px;">Password Reset Request</h2>
								<p style="margin: 0 0 25px; color: #4a5568; font-size: 16px; line-height: 1.7;">We received a request to reset the password for your UpVista Community account. Click the button below to proceed with resetting your password.</p>
							
							<!-- Reset Button -->
								<table width="100%%" cellpadding="0" cellspacing="0" style="margin: 35px 0;">
								<tr>
									<td align="center">
											<a href="%s" style="display: inline-block; background-color: #1a1f3a; color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 6px; font-size: 16px; font-weight: 600; letter-spacing: 0.3px; text-align: center;">Reset Password</a>
									</td>
								</tr>
							</table>
							
								<p style="margin: 25px 0 0; color: #718096; font-size: 14px; line-height: 1.6;">Alternatively, copy and paste this link into your browser:</p>
								<p style="margin: 10px 0 0; color: #4a5568; font-size: 13px; word-break: break-all; font-family: 'Courier New', monospace; background-color: #f7f9fc; padding: 12px; border-radius: 4px; border: 1px solid #e2e8f0;">%s</p>
								
								<p style="margin: 25px 0 0; color: #718096; font-size: 14px; line-height: 1.6;">This password reset link will expire in <strong style="color: #1a1f3a;">1 hour</strong>.</p>
								
								<div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e2e8f0;">
									<p style="margin: 0 0 15px; color: #718096; font-size: 13px; line-height: 1.6;">If you did not request a password reset, please ignore this email. Your account security remains unchanged.</p>
							</div>
						</td>
					</tr>
					<!-- Footer -->
					<tr>
							<td style="background-color: #f7f9fc; padding: 30px 50px; border-radius: 0 0 8px 8px; border-top: 1px solid #e2e8f0;">
								<p style="margin: 0 0 10px; color: #718096; font-size: 13px; line-height: 1.6;">UpVista Community</p>
								<p style="margin: 0; color: #a0aec0; font-size: 12px;">This is an automated message. Please do not reply to this email.</p>
									</td>
								</tr>
							</table>
					<!-- Footer Text -->
					<table width="600" cellpadding="0" cellspacing="0" style="max-width: 600px; margin-top: 20px;">
						<tr>
							<td align="center">
								<p style="margin: 0; color: #a0aec0; font-size: 12px;">© %d UpVista Community. All rights reserved.</p>
						</td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
</body>
</html>
	`, resetURL, resetURL, time.Now().Year())

	return e.sendEmail(to, subject, body)
}

// SendWelcomeEmail sends a welcome email after successful verification
func (e *EmailService) SendWelcomeEmail(to, displayName string) error {
	subject := "Welcome to UpVista Community"
	body := fmt.Sprintf(`
	<!DOCTYPE html>
		<html>
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
	</head>
	<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f7fa; line-height: 1.6;">
		<table width="100%%" cellpadding="0" cellspacing="0" style="background-color: #f5f7fa; padding: 40px 20px;">
			<tr>
				<td align="center">
					<table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); max-width: 600px;">
						<!-- Header -->
						<tr>
							<td style="background: linear-gradient(135deg, #1a1f3a 0%%, #2d3561 100%%); padding: 40px 50px; border-radius: 8px 8px 0 0;">
								<h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 600; letter-spacing: -0.5px;">UpVista Community</h1>
							</td>
						</tr>
						<!-- Content -->
						<tr>
							<td style="padding: 50px 50px 40px;">
								<h2 style="margin: 0 0 20px; color: #1a1f3a; font-size: 24px; font-weight: 600; letter-spacing: -0.3px;">Welcome, %s</h2>
								<p style="margin: 0 0 25px; color: #4a5568; font-size: 16px; line-height: 1.7;">Your email address has been successfully verified. Your UpVista Community account is now active and ready to use.</p>
								
								<!-- Features Section -->
								<div style="margin: 35px 0; padding: 30px; background-color: #f7f9fc; border-radius: 6px; border-left: 4px solid #1a1f3a;">
									<p style="margin: 0 0 20px; color: #1a1f3a; font-size: 16px; font-weight: 600;">Get started with UpVista Community:</p>
									<table width="100%%" cellpadding="0" cellspacing="0">
										<tr>
											<td style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
												<p style="margin: 0; color: #4a5568; font-size: 15px; line-height: 1.6;">Connect with industry professionals and expand your network</p>
											</td>
										</tr>
										<tr>
											<td style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
												<p style="margin: 0; color: #4a5568; font-size: 15px; line-height: 1.6;">Showcase your projects and build your professional portfolio</p>
											</td>
										</tr>
										<tr>
											<td style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
												<p style="margin: 0; color: #4a5568; font-size: 15px; line-height: 1.6;">Discover exclusive freelance and collaboration opportunities</p>
											</td>
										</tr>
										<tr>
											<td style="padding: 12px 0;">
												<p style="margin: 0; color: #4a5568; font-size: 15px; line-height: 1.6;">Access premium resources and industry insights</p>
											</td>
										</tr>
									</table>
								</div>
								
								<div style="margin-top: 35px; padding: 25px; background-color: #f7f9fc; border-radius: 6px;">
									<p style="margin: 0 0 10px; color: #1a1f3a; font-size: 15px; font-weight: 600;">Need assistance?</p>
									<p style="margin: 0; color: #718096; font-size: 14px; line-height: 1.6;">Our support team is available to help you get the most out of your UpVista Community experience.</p>
								</div>
							</td>
						</tr>
						<!-- Footer -->
						<tr>
							<td style="background-color: #f7f9fc; padding: 30px 50px; border-radius: 0 0 8px 8px; border-top: 1px solid #e2e8f0;">
								<p style="margin: 0 0 10px; color: #718096; font-size: 13px; line-height: 1.6;">UpVista Community</p>
								<p style="margin: 0; color: #a0aec0; font-size: 12px;">Thank you for joining our community of professionals.</p>
							</td>
						</tr>
					</table>
					<!-- Footer Text -->
					<table width="600" cellpadding="0" cellspacing="0" style="max-width: 600px; margin-top: 20px;">
						<tr>
							<td align="center">
								<p style="margin: 0; color: #a0aec0; font-size: 12px;">© %d UpVista Community. All rights reserved.</p>
							</td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
		</body>
		</html>
	`, displayName, time.Now().Year())

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
