# HIVMeet - Backend Integration Guide

**Purpose**: Comprehensive guide for API integration, HTTP client configuration, and backend communication.

---

## HTTP Client Configuration (Dio)

### Base Setup

**File**: `lib/data/services/api_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiService(this._dio, this._storage) {
    _configureClient();
  }

  void _configureClient() {
    _dio.options = BaseOptions(
      baseUrl: Constants.baseApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // Accept all status codes to handle them manually
        return status != null && status < 500;
      },
    );

    // Interceptors
    _dio.interceptors.add(AuthInterceptor(_storage));
    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
  }

  Dio get client => _dio;
}
```

---

## Authentication Interceptor

**Purpose**: Automatically inject auth token in every request

```dart
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  AuthInterceptor(this.storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login/register endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register')) {
      return handler.next(options);
    }

    // Get token from secure storage
    final token = await storage.read(key: 'auth_token');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }
}
```

---

## Error Handling Interceptor

**Purpose**: Centralized error handling, token refresh, retry logic

```dart
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired - trigger logout or refresh
      // TODO: Implement token refresh logic
      return handler.reject(err);
    }

    if (err.response?.statusCode == 403) {
      // Forbidden - user lacks permissions
      throw ServerException(
        message: 'Access forbidden. Check your subscription status.',
      );
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      throw NetworkException(
        message: 'Connection timeout. Please check your internet.',
      );
    }

    if (err.type == DioExceptionType.connectionError) {
      throw NetworkException(
        message: 'Network error. Please check your connection.',
      );
    }

    return handler.next(err);
  }
}
```

---

## Logging Interceptor (Debug Only)

**Purpose**: Log requests/responses for debugging (NO PII)

```dart
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('🚀 REQUEST: ${options.method} ${options.path}');
      print('📦 Data: ${_sanitizeData(options.data)}');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
      print('⏱️ Duration: ${response.requestOptions.sendTimeout}ms');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.path}');
      print('📄 Message: ${err.message}');
    }
    return handler.next(err);
  }

  // Remove sensitive data from logs
  Map<String, dynamic> _sanitizeData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final sanitized = Map<String, dynamic>.from(data);
      // Mask sensitive fields
      if (sanitized.containsKey('password')) {
        sanitized['password'] = '***';
      }
      if (sanitized.containsKey('token')) {
        sanitized['token'] = '***';
      }
      if (sanitized.containsKey('email')) {
        sanitized['email'] = '***@***.***';
      }
      return sanitized;
    }
    return {};
  }
}
```

---

## API Endpoints Reference

**Source**: `API_DOCUMENTATION.md` (root directory - most recent)

### Authentication Module

```dart
class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage storage;

  AuthService(this.apiService, this.storage);

  // POST /api/v1/auth/register
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
    required DateTime birthdate,
    required String gender,
  }) async {
    final response = await apiService.client.post(
      '/api/v1/auth/register',
      data: {
        'email': email,
        'password': password,
        'username': username,
        'birthdate': birthdate.toIso8601String(),
        'gender': gender,
      },
    );

    if (response.statusCode == 201) {
      final user = UserModel.fromJson(response.data['user']);
      final token = response.data['token'];
      await storage.write(key: 'auth_token', value: token);
      return user;
    }

    throw ServerException(
      message: response.data['message'] ?? 'Registration failed',
    );
  }

  // POST /api/v1/auth/login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiService.client.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(response.data['user']);
      final token = response.data['token'];
      await storage.write(key: 'auth_token', value: token);
      return user;
    }

    throw ServerException(
      message: response.data['message'] ?? 'Login failed',
    );
  }

  // POST /api/v1/auth/logout
  Future<void> logout() async {
    final response = await apiService.client.post('/api/v1/auth/logout');

    if (response.statusCode == 200) {
      await storage.delete(key: 'auth_token');
      return;
    }

    throw ServerException(message: 'Logout failed');
  }
}
```

---

## Response Handling Pattern

### Standard Success Response

```dart
// Pattern for successful responses
if (response.statusCode == 200 || response.statusCode == 201) {
  // Parse data
  final data = response.data;
  
  // Transform to model
  final model = ModelClass.fromJson(data);
  
  return model;
}
```

### Standard Error Response

```dart
// Pattern for error responses
if (response.statusCode == 400) {
  // Bad request - validation error
  final errors = response.data['errors'] as Map<String, dynamic>?;
  throw ValidationException(errors: errors ?? {});
}

if (response.statusCode == 404) {
  // Not found
  throw NotFoundException(
    message: response.data['message'] ?? 'Resource not found',
  );
}

if (response.statusCode >= 500) {
  // Server error
  throw ServerException(
    message: 'Server error. Please try again later.',
  );
}
```

---

## Pagination Handling

**Backend Pattern**: Cursor-based pagination

```dart
class PaginatedResponse<T> {
  final List<T> results;
  final String? nextCursor;
  final bool hasMore;

  PaginatedResponse({
    required this.results,
    this.nextCursor,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      results: (json['results'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'],
      hasMore: json['has_more'] ?? false,
    );
  }
}

// Usage
Future<PaginatedResponse<ProfileModel>> getDiscoveryProfiles({
  String? cursor,
  int limit = 20,
}) async {
  final response = await apiService.client.get(
    '/api/v1/discovery/profiles',
    queryParameters: {
      'cursor': cursor,
      'limit': limit,
    },
  );

  if (response.statusCode == 200) {
    return PaginatedResponse.fromJson(
      response.data,
      (json) => ProfileModel.fromJson(json),
    );
  }

  throw ServerException(message: 'Failed to load profiles');
}
```

---

## File Upload (Multipart)

**Use Case**: Profile photos, verification documents

```dart
Future<String> uploadProfilePhoto(File photo) async {
  final formData = FormData.fromMap({
    'photo': await MultipartFile.fromFile(
      photo.path,
      filename: 'profile_photo.jpg',
      contentType: MediaType('image', 'jpeg'),
    ),
  });

  final response = await apiService.client.post(
    '/api/v1/users/profile/photos',
    data: formData,
    options: Options(
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    ),
  );

  if (response.statusCode == 201) {
    return response.data['photo_url'];
  }

  throw ServerException(message: 'Photo upload failed');
}
```

---

## WebSocket Connection (Chat)

**Use Case**: Real-time messaging

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  final String wsBaseUrl = Constants.wsBaseUrl;

  Future<void> connect(String conversationId, String token) async {
    final uri = Uri.parse('$wsBaseUrl/ws/chat/$conversationId/?token=$token');
    
    _channel = WebSocketChannel.connect(uri);
    
    _channel!.stream.listen(
      (message) {
        // Handle incoming message
        final data = jsonDecode(message);
        print('Received: $data');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket closed');
      },
    );
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
```

---

## Retry Logic (Network Resilience)

```dart
Future<T> retryRequest<T>({
  required Future<T> Function() request,
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  int attempts = 0;
  
  while (attempts < maxAttempts) {
    try {
      return await request();
    } catch (e) {
      attempts++;
      
      if (attempts >= maxAttempts) {
        rethrow;
      }
      
      // Exponential backoff
      await Future.delayed(delay * attempts);
    }
  }
  
  throw Exception('Max retry attempts reached');
}

// Usage
final profiles = await retryRequest(
  request: () => profileService.getDiscoveryProfiles(),
  maxAttempts: 3,
);
```

---

## Backend Change Request Template

When you need a backend API change, use this template:

```markdown
### Backend Change Required

**Endpoint**: [HTTP_METHOD] /api/v1/[path]

**Request Payload**:
```json
{
  "field1": "type (description)",
  "field2": "type (description)"
}
```

**Response Payload (Success)**:
Status Code: [200/201/204]
```json
{
  "field1": "type (description)",
  "field2": "type (description)"
}
```

**Response Payload (Error)**:
Status Code: [400/401/403/404]
```json
{
  "error": "error_code",
  "message": "Human-readable error message",
  "details": {}
}
```

**Headers**:
- Authorization: Bearer {token} (if required)
- Content-Type: application/json

**Rationale**: [Why this change is needed]
```

---

## 🔧 Error Correction in Logs

**When errors are identified in logs (frontend or backend)**:

- ✅ **CORRECT ERRORS** in source code whenever possible
- ✅ **DO NOT ONLY** document or ignore minor errors
- ✅ **PRIORITIZE** fixes that have no impact on other features
- ✅ For critical or complex errors (requiring backend modification), create a markdown file `BACKEND_[TYPE]_[DESCRIPTION].md`

**Examples of errors to correct directly**:
- Dart compilation errors
- Type errors
- Empty URLs causing crashes
- Unhandled null values
- Incorrect UI states

**Examples requiring a markdown file**:
- Backend corrections required
- API modifications
- Database schema changes
- Complex performance issues

---

**Always refer to `API_DOCUMENTATION.md` for the latest endpoint specifications!**
