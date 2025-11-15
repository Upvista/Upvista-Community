# Debugging 500 Error on Post Creation

## Current Status
- ✅ Proxy route is working (receiving requests)
- ✅ Backend is receiving requests (`POST /api/v1/posts`)
- ❌ Backend returning 500 error
- ❌ Error message not visible in logs

## What to Check

### 1. Check Next.js Server Console
When you try to create a post, you should see detailed logs. Look for:

```
[Proxy] ==========================================
[Proxy] Backend returned 500 error
[Proxy] URL: http://127.0.0.1:8081/api/v1/posts
[Proxy] Method: POST
[Proxy] Response body: {
  "error": "actual error message here"
}
[Proxy] Raw response: ...
[Proxy] ==========================================
```

**If you don't see these logs:**
- Restart Next.js dev server to pick up the new logging code
- Check if you're looking at the correct terminal (Next.js server, not browser console)

### 2. Check Go Backend Console
The backend should show the error. Look for any error messages after:
```
[GIN] 2025/11/14 - 23:57:50 | 500 |    368.6918ms |             ::1 | POST     "/api/v1/posts"
```

### 3. Most Likely Causes

#### A. Database Table Missing
The `posts` table might not exist in Supabase.

**Check:**
1. Go to Supabase Dashboard → Table Editor
2. Verify `posts` table exists
3. If missing, run the migration script: `backend/scripts/posts_system_migration.sql`

#### B. Database Schema Mismatch
The table structure might not match what the code expects.

**Required columns in `posts` table:**
- `id` (uuid, primary key)
- `user_id` (uuid, foreign key to users)
- `post_type` (text: 'post', 'poll', 'article')
- `content` (text)
- `media_urls` (jsonb or text[])
- `media_types` (jsonb or text[])
- `visibility` (text: 'public', 'connections', 'private')
- `allows_comments` (boolean)
- `allows_sharing` (boolean)
- `is_published` (boolean)
- `is_draft` (boolean)
- `is_nsfw` (boolean)
- `published_at` (timestamp)
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### C. Supabase Connection Issue
The backend might not be able to connect to Supabase.

**Check:**
1. Verify Supabase URL and service key in backend `.env`
2. Test connection: `GET /api/v1/test-db`

#### D. Foreign Key Constraint
The `user_id` might not exist in the `users` table.

**Check:**
1. Verify the authenticated user exists in Supabase
2. Check if JWT token contains valid user ID

## Quick Fix Steps

1. **Restart Next.js dev server** to get detailed error logs
2. **Try creating a post again**
3. **Check Next.js console** for the full error message
4. **Check Go backend console** for any error logs
5. **Share the error message** so we can fix it

## Expected Error Format

The backend should return:
```json
{
  "error": "failed to create post: supabase error (status 400): ..."
}
```

This will tell us exactly what's wrong (missing table, wrong schema, constraint violation, etc.)

---

**Next Action:** Restart Next.js server and try again, then share the error message from the console.

