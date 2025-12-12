# Feature Integration Guide

Quick reference for integrating features with the backend API.

## ✅ Current Status - Ready for Integration

All core infrastructure is complete and tested:
- ✅ API Client configured and working
- ✅ Token management ready
- ✅ Error handling complete
- ✅ Network monitoring active
- ✅ No compilation errors
- ✅ All dependencies installed

## Quick Start for Feature Integration

### 1. Create Feature Service

```dart
// Example: lib/features/auth/data/services/auth_service.dart
import 'package:asteria/core/api/api_client.dart';
import 'package:asteria/core/api/models/api_response.dart';
import 'package:asteria/core/config/api_config.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<User>> login(String email, String password) async {
    final response = await _apiClient.post<ApiResponse<User>>(
      '${ApiConfig.auth}/login',
      data: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => ApiResponse.fromJson(json, User.fromJson),
    );
    return response;
  }
}
```

### 2. Create Data Models

```dart
// Example: lib/features/auth/data/models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String username;
  final String displayName;
  
  User({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

Then run: `flutter pub run build_runner build`

### 3. Backend API Response Format

All backend responses follow this structure:
```json
{
  "success": true,
  "message": "Optional message",
  "data": { ... }
}
```

Or on error:
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

Our `ApiResponse<T>` model handles this automatically.

## Feature Integration Checklist

For each feature (Auth, Messages, Feed, etc.):

- [ ] Create data models (User, Post, Message, etc.)
- [ ] Create service class (AuthService, PostService, etc.)
- [ ] Add API endpoints to ApiConfig if needed
- [ ] Implement repository layer (optional, for business logic)
- [ ] Connect to UI screens
- [ ] Handle errors appropriately
- [ ] Test with backend

## Common Patterns

### GET Request
```dart
final response = await _apiClient.get<ApiResponse<User>>(
  '${ApiConfig.account}/profile',
  fromJson: (json) => ApiResponse.fromJson(json, User.fromJson),
);
```

### POST Request
```dart
final response = await _apiClient.post<ApiResponse<Post>>(
  '${ApiConfig.posts}',
  data: {
    'content': 'Post content',
    'type': 'text',
  },
  fromJson: (json) => ApiResponse.fromJson(json, Post.fromJson),
);
```

### File Upload
```dart
final response = await _apiClient.uploadFile<ApiResponse<String>>(
  '${ApiConfig.account}/profile-picture',
  imagePath,
  fileKey: 'file',
  onSendProgress: (sent, total) {
    // Update progress
  },
  fromJson: (json) => ApiResponse.fromJson(json, (data) => data as String),
);
```

### Paginated Request
```dart
final response = await _apiClient.get<PaginatedResponse<Post>>(
  '${ApiConfig.feed}/home',
  queryParameters: {
    'page': 1,
    'page_size': 20,
  },
  fromJson: (json) => PaginatedResponse.fromJson(json, Post.fromJson),
);
```

## Error Handling Pattern

```dart
try {
  final user = await authService.login(email, password);
  if (user.isSuccess && user.data != null) {
    // Handle success
  }
} on AuthenticationException {
  // Show login error
} on NetworkException {
  // Show offline message
} on ValidationException catch (e) {
  // Show validation errors
  print(e.errors);
} on ApiException catch (e) {
  // Handle other errors
  print(e.message);
}
```

## Backend Endpoints Reference

### Authentication
- `POST /auth/register` - Register
- `POST /auth/login` - Login
- `POST /auth/verify-email` - Verify email
- `POST /auth/refresh` - Refresh token
- `POST /auth/logout` - Logout

### Account
- `GET /account/profile` - Get profile
- `PATCH /account/profile` - Update profile
- `POST /account/profile-picture` - Upload picture

### Posts & Feed
- `GET /feed/home` - Home feed
- `GET /feed/following` - Following feed
- `POST /posts` - Create post
- `GET /posts/:id` - Get post

### Messages
- `GET /conversations` - Get conversations
- `GET /conversations/:id/messages` - Get messages
- `POST /conversations/:id/messages` - Send message

### Notifications
- `GET /notifications` - Get notifications
- `PATCH /notifications/:id/read` - Mark as read

### Search
- `GET /search/users` - Search users
- `GET /search/posts` - Search posts

## Important Notes

1. **Token Management**: Automatic - tokens are added to all requests automatically
2. **Token Refresh**: Automatic - happens on 401 errors
3. **Error Handling**: All errors are typed exceptions
4. **Network Check**: Connectivity is checked before requests
5. **Base URL**: Update in `api_config.dart` for production

## Ready to Start! 🚀

Everything is set up and ready. Just create your feature services and models, and start integrating!
