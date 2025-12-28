# Events System Setup Guide

**Created by:** Hamza Hafeez - Founder & CEO of Upvista  
**Date:** December 2024

## 📋 Prerequisites

1. **Database Migration**: Run the events system migration SQL script
2. **Supabase Storage Bucket**: Create bucket for event cover images
3. **Admin Email Configuration**: Update admin email in service

---

## 🗄️ Database Setup

### Step 1: Run Migration Script

Execute the SQL migration script in your Supabase SQL Editor:

```sql
-- File: backend/scripts/events_system_migration.sql
```

This creates:
- `events` table
- `event_applications` table
- `event_approval_requests` table
- `event_categories` table
- `event_comments` table
- All indexes, RLS policies, and triggers

---

## 🪣 Supabase Storage Bucket Setup

### Step 2: Create Event Covers Bucket

1. **Go to Supabase Dashboard** → Storage
2. **Create New Bucket**:
   - **Bucket Name**: `event-covers`
   - **Public**: ✅ Yes (so images can be accessed via public URL)
   - **File Size Limit**: 5MB (recommended)
   - **Allowed MIME Types**: `image/jpeg`, `image/png`, `image/webp`, `image/gif`

3. **Set Bucket Policies** (RLS):
   ```sql
   -- Allow authenticated users to upload
   CREATE POLICY "Users can upload event cover images"
   ON storage.objects FOR INSERT
   WITH CHECK (
     bucket_id = 'event-covers' 
     AND auth.uid()::text = (storage.foldername(name))[1]
   );

   -- Allow public read access
   CREATE POLICY "Public can view event cover images"
   ON storage.objects FOR SELECT
   USING (bucket_id = 'event-covers');
   ```

---

## ⚙️ Configuration

### Step 3: Update Admin Email

The admin email is currently set to `hamza@upvistadigital.com` in:
- `backend/internal/events/service.go` → `sendApprovalRequestEmail()` function

To change it, update line 439:
```go
adminEmail := "hamza@upvistadigital.com" // Change this to your admin email
```

---

## ✅ Approval Logic

### Auto-Approved Events:
- ✅ **Free** + **Online** + **Public** = Auto-approved (immediately visible)

### Requires Approval:
- ❌ **Paid** events
- ❌ **Private** events
- ❌ **Physical** location events
- ❌ **Hybrid** location events

### Approval Process:
1. User creates event → Status: `pending`
2. Email sent to:
   - **User**: Confirmation email with event details
   - **Admin** (`hamza@upvistadigital.com`): Approval request with full event details and Event ID
3. Admin manually approves in Supabase:
   - Go to `events` table
   - Find event by ID (from email)
   - Change `status` from `pending` to `approved`
4. Approved events automatically appear in event listing

---

## 📧 Email Templates

### Admin Approval Request Email Includes:
- Event ID
- Title & Description
- Category & Type (Public/Private)
- Pricing information
- Date & Time details
- Location information
- Creator information
- Instructions for manual approval in Supabase

### User Confirmation Email Includes:
- Event title
- Event ID
- Start date
- Status (Pending Approval)
- Notification that they'll be notified when approved

---

## 🖼️ Cover Image Upload

### Frontend:
- Image picker replaces URL input
- Supports: JPG, PNG, WebP, GIF
- Max size: 5MB
- Preview before upload
- Uploads to `event-covers` bucket

### Backend:
- Endpoint: `POST /api/v1/events/upload-cover-image`
- Requires authentication
- Returns public URL for use in event creation

---

## 🧪 Testing

1. **Create Free + Online + Public Event**:
   - Should be auto-approved
   - Should appear immediately in listing

2. **Create Paid/Private/Physical Event**:
   - Should require approval
   - Should send emails to user and admin
   - Should have status `pending`
   - Should NOT appear in public listing until approved

3. **Upload Cover Image**:
   - Should upload successfully
   - Should return public URL
   - Should display preview in form

---

## 📝 Notes

- Events are filtered by status in the listing (only `approved` events shown publicly)
- Admin can manually approve/reject events in Supabase dashboard
- Event ID is included in admin email for easy lookup
- Cover images are stored in `event-covers` bucket with path: `events/{user_id}/{uuid}_{filename}`
