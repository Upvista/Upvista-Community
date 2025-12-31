# Mobile App Connection Troubleshooting Guide

## Quick Fix

### Step 1: Identify Your Setup

**Are you using:**
- ✅ Android Emulator → Use: `http://10.0.2.2:8081/api/v1`
- ✅ Physical Android Device → Use: `http://YOUR_PC_IP:8081/api/v1`
- ✅ iOS Simulator → Use: `http://localhost:8081/api/v1`

### Step 2: Get Your PC's IP Address

**Windows:**
```powershell
ipconfig | findstr IPv4
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
```

### Step 3: Update API Config

Edit `mobile-app/lib/core/config/api_config.dart`:

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8081/api/v1';
```

**For Physical Device (replace with your IP):**
```dart
static const String baseUrl = 'http://10.172.47.27:8081/api/v1';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8081/api/v1';
```

### Step 4: Restart Everything

1. **Restart the backend:**
   ```bash
   cd backend
   go run main.go
   ```

2. **Restart the Flutter app** (full restart, not hot reload)

3. **Try signing in again**

---

## Common Issues

### Issue 1: "Connection timeout" or "Cannot connect"

**Solution:**
- ✅ Check backend is running: `curl http://localhost:8081/health`
- ✅ Verify correct URL in `api_config.dart`
- ✅ Ensure phone/emulator and PC are on same Wi-Fi network (for physical device)
- ✅ Check Windows Firewall isn't blocking port 8081

### Issue 2: "Connection refused"

**Solution:**
- ✅ Backend might only be listening on localhost
- ✅ Check `netstat -ano | findstr :8081` shows `0.0.0.0:8081` (not just `127.0.0.1:8081`)
- ✅ Restart backend server

### Issue 3: Works on emulator but not physical device

**Solution:**
- ✅ Use your PC's actual IP address (not `10.0.2.2`)
- ✅ Ensure both devices on same Wi-Fi network
- ✅ Check firewall allows connections on port 8081

---

## Testing Connection

### Test 1: Backend Health Check
```bash
curl http://localhost:8081/health
```
Should return: `{"status":"healthy",...}`

### Test 2: From Emulator/Device
- Open browser in emulator/device
- Navigate to: `http://10.0.2.2:8081/health` (emulator) or `http://YOUR_IP:8081/health` (device)
- Should see JSON response

### Test 3: Check Backend Logs
When you try to sign in, check backend terminal for incoming requests. If you see nothing, the connection isn't reaching the server.

---

## Firewall Fix (Windows)

If firewall is blocking:

1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. TCP, Specific port: `8081` → Next
6. Allow the connection → Next
7. Apply to all profiles → Next
8. Name: "Backend API" → Finish

---

## Still Not Working?

1. **Check backend logs** - Are requests reaching the server?
2. **Try different URL** - Switch between emulator and physical device URL
3. **Verify backend port** - Make sure it's actually 8081 (check `.env` file)
4. **Test with Postman/curl** - Verify backend works independently

---

## Current Configuration

- **Your PC IP:** `10.172.47.27` (check with `ipconfig`)
- **Backend Port:** `8081`
- **Current mobile config:** Check `mobile-app/lib/core/config/api_config.dart`

