# API Configuration Guide

## Current Configuration
- **Base URL**: `http://192.168.100.187:8081/api/v1`
- **Your PC IP**: `192.168.100.187`
- **Port**: `8081`

## Platform-Specific Configuration

### Android Emulator
If you're using an Android emulator, you **MUST** use `10.0.2.2` instead of your local IP:

```dart
static const String baseUrl = 'http://10.0.2.2:8081/api/v1';
```

### Physical Android Device
Use your computer's IP address (must be on the same network):
```dart
static const String baseUrl = 'http://192.168.100.187:8081/api/v1';
```

### iOS Simulator
Use `localhost` or your Mac's IP:
```dart
static const String baseUrl = 'http://localhost:8081/api/v1';
// OR
static const String baseUrl = 'http://192.168.100.187:8081/api/v1';
```

## Troubleshooting Connection Timeouts

1. **Verify Backend is Running**:
   ```bash
   cd backend
   go run main.go
   ```
   You should see: `Starting server on port 8081`

2. **Test Backend from Browser**:
   Open: `http://localhost:8081/api/v1/health` (if health endpoint exists)
   Or: `http://192.168.100.187:8081/api/v1/health`

3. **Check Firewall**:
   - Windows: Allow port 8081 in Windows Firewall
   - Ensure backend is binding to `0.0.0.0:8081` (all interfaces)

4. **For Android Emulator**:
   - Change `api_config.dart` baseUrl to: `http://10.0.2.2:8081/api/v1`
   - This is the special IP that Android emulator uses to reach host machine

5. **For Physical Device**:
   - Ensure device and PC are on the same Wi-Fi network
   - Use PC's IP address (found via `ipconfig` on Windows)

## Quick Fix
If you're getting connection timeouts on Android emulator, update:
`mobile-app/lib/core/config/api_config.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8081/api/v1';
```
