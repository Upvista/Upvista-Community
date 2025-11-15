# Proxy Route 404 Debug Guide

## Issue
POST requests to `/api/proxy/v1/posts` are returning 404 errors.

## What We've Fixed

1. ✅ Added route segment config (`dynamic = 'force-dynamic'`, `runtime = 'nodejs'`)
2. ✅ Enhanced error handling with try-catch
3. ✅ Added comprehensive logging
4. ✅ Fixed WebSocket environment detection

## Debugging Steps

### Step 1: Verify Route File Exists
The route file should be at:
```
frontend-web/app/api/proxy/[...path]/route.ts
```

### Step 2: Check Next.js Server Console
When you try to create a post, check your **Next.js dev server console** (where you run `npm run dev`). You should see:

```
[Proxy Route] POST handler called
[Proxy Route] Resolved params: { path: ['v1', 'posts'] }
[Proxy Route] POST called with path: ['v1', 'posts']
[Proxy] POST request received
```

**If you DON'T see these logs**, the route handler isn't being called, which means Next.js isn't recognizing the route.

### Step 3: Test Simple Route
Test if API routes work at all:
```javascript
// In browser console:
fetch('/api/test')
  .then(r => r.json())
  .then(console.log)
```

Should return: `{ success: true, message: 'API routes are working!' }`

### Step 4: Restart Next.js Dev Server
**CRITICAL:** Next.js needs to be restarted after route changes:

```bash
# Stop the server (Ctrl+C)
cd frontend-web
npm run dev
```

### Step 5: Clear Next.js Cache
If restart doesn't work, clear the cache:

```bash
cd frontend-web
rm -rf .next
npm run dev
```

## Common Causes of 404

1. **Next.js dev server not restarted** - Most common!
2. **Route file in wrong location** - Should be `app/api/proxy/[...path]/route.ts`
3. **Next.js cache issue** - Delete `.next` folder
4. **Route segment config missing** - We've added this
5. **TypeScript compilation error** - Check for errors

## Expected Behavior After Fix

1. **Route is called** - You see logs in Next.js console
2. **Request forwarded** - Backend receives the request
3. **Post created** - Post appears in feed
4. **No 404 errors** - Request succeeds

## If Still Not Working

1. Check Next.js console for any errors
2. Verify backend is running on port 8081
3. Test `/api/test` route to verify API routes work
4. Check browser Network tab for exact request URL
5. Verify route file is saved and has no syntax errors

---

**Next Action:** Restart Next.js dev server and try again!

