# API Configuration Guide

## ⚠️ IMPORTANT: Fix "No Internet Connection" Error

The API base URL is currently set to `localhost:8081`, which **won't work on physical devices or emulators**. This is why you're seeing "no internet connection" errors.

### Quick Fix (Required for Testing):

1. **Find your computer's IP address:**
   - **Windows**: Open Command Prompt and run `ipconfig`
   - Look for "IPv4 Address" under your active network adapter (usually `192.168.x.x` or `10.x.x.x`)

2. **Update the API config:**
   - Open: `mobile-app/lib/core/config/api_config.dart`
   - Change line 7 from:
     ```dart
     static const String baseUrl = 'http://localhost:8081/api/v1';
     ```
   - To (replace with YOUR IP):
     ```dart
     static const String baseUrl = 'http://192.168.1.100:8081/api/v1';
     ```

3. **Make sure:**
   - Your backend server is running on port 8081
   - Your phone and computer are on the same Wi-Fi network
   - Your firewall allows connections on port 8081

4. **Restart the Flutter app**

### For Android Emulator:
Use `10.0.2.2` instead of `localhost`:
```dart
static const String baseUrl = 'http://10.0.2.2:8081/api/v1';
```

### For iOS Simulator:
`localhost` should work, or use your Mac's IP address.

### Test Your Backend:
Open in browser: `http://YOUR_IP:8081/api/v1/auth/check-username?username=test`
If this doesn't work, your backend isn't accessible from your network.

## Sign-In Flow Fixed

The "Already have an account" flow now works correctly:
1. Shows cached user confirmation screen (if user logged in before)
2. If no cached user, goes to email/password sign-in
3. After confirmation, asks for password

## Connectivity Check

The connectivity check is now non-blocking - it won't prevent requests from being made. Actual network errors will be handled by the request itself.
