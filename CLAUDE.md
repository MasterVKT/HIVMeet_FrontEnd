# HIVMeet Frontend - AI Agent Rules (Claude Code)

**Version**: 2.0 (Optimized)  
**Date**: February 22, 2026  
**Project**: HIVMeet - Dating App for People Living with HIV/AIDS  
**Stack**: Flutter (Dart) + Django (Python) + Firebase  
**Architecture**: Clean Architecture + BLoC Pattern

---

## 🎯 Project Context

You are an expert developer specialized in **Flutter (Dart)** frontend development and **Django (Python)** backend integration. This is a dating application for people living with HIV/AIDS, requiring **sensitivity, respect, and strict privacy protection**.

**Core Responsibilities**:
- Develop the **Flutter frontend** independently from backend
- Strictly respect **backend API interface contracts**
- Follow specifications in `docs/` folder
- Support **French and English** internationalization (mandatory)

---

## ⚡ 8 Critical Rules (Non-Negotiable)

### 1. 🔗 Strict Backend API Contract Compliance

**Rule**: Always consult `API_DOCUMENTATION.md` (root) for ALL endpoints before implementation.

**Why**: This is the **most recent** and authoritative API reference (last updated: September 14, 2025, 449 lines). Ensures frontend-backend alignment.

**Implementation**:
```dart
// ✅ CORRECT - Use API_DOCUMENTATION.md endpoint
final response = await dio.post('/api/v1/auth/login',
  data: {'email': email, 'password': password}
);

// ❌ WRONG - Guessing endpoint structure
final response = await dio.post('/auth/login', ...);
```

**Action**: If API change needed, specify: exact endpoint, HTTP method, request/response payloads, status codes, error formats.

---

### 2. 🌍 Mandatory Internationalization (FR/EN)

**Rule**: ALL user-facing text MUST use `intl` package with ARB files. Zero hardcoded strings allowed.

**Implementation**:
```dart
// ✅ CORRECT - Internationalized text
Text(AppLocalizations.of(context)!.welcomeMessage)

// ❌ WRONG - Hardcoded text
Text('Bienvenue sur HIVMeet')
```

**Files**: `assets/translations/intl_fr.arb`, `assets/translations/intl_en.arb`

---

### 3. 🔐 Centralized API URL Configuration

**Rule**: Use ONLY `lib/core/config/constants.dart` for base URLs. Mode-based configuration (debug/profile/release).

**Implementation**:
```dart
// ✅ CORRECT - Using centralized config
import 'package:hivmeet/core/config/constants.dart';
final url = '${Constants.baseApiUrl}/api/v1/users/profile';

// ❌ WRONG - Hardcoded URL
final url = 'https://api.hivmeet.com/api/v1/users/profile';
```

---

### 4. 🛡️ Anti-Regression Safety Net

**Rule**: Before validating ANY correction, verify no regression was introduced. Test affected modules.

**Process**:
1. Implement fix
2. Test primary functionality
3. Test ALL related features
4. If regression detected → Fix immediately
5. Document root cause

---

### 5. 🔒 Sensitive Data Protection (PII)

**Rule**: NEVER log tokens, emails, user IDs, or PII. Use `flutter_secure_storage` for tokens.

**Implementation**:
```dart
// ✅ CORRECT - Secure token storage
final storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);

// ❌ WRONG - Insecure storage or logging
SharedPreferences prefs = await SharedPreferences.getInstance();
prefs.setString('auth_token', token); // INSECURE
print('User token: $token'); // NEVER LOG PII
```

---

### 6. 📋 Strict Specification Adherence

**Rule**: Consult `docs/Plan de Développement Frontend Détaillé - HIVMeet.txt` BEFORE implementation. Respect development order.

**Process**:
1. Read relevant specs in `docs/`
2. Validate development order
3. Implement according to specifications
4. Verify alignment with specs before completion

---

### 7. 🔄 Coordinated Backend-Frontend Changes

**Rule**: If backend change required, provide structured, unambiguous instructions:
- Exact endpoint path
- HTTP method
- Complete request/response JSON payloads
- Expected status codes
- Error format

**Example**:
```
Backend Change Required:
- Endpoint: POST /api/v1/users/{user_id}/verify-document
- Request: { "document_type": "id_card", "document_url": "https://..." }
- Response (200): { "verification_id": "abc123", "status": "pending" }
- Response (400): { "error": "invalid_document_type", "message": "..." }
```

---

### 8. ❤️ Domain Sensitivity (HIV/AIDS Community)

**Rule**: All content MUST be respectful, non-stigmatizing, inclusive, and privacy-focused.

**Guidelines**:
- Avoid stereotypes and judgmental language
- Promote safety and inclusivity
- Respect user privacy settings
- Auto-delete verification documents after processing

---

## 📚 Detailed Rules (On-Demand Import)

For comprehensive guidance, import these detailed rule files when needed:

- **Architecture & Patterns**: `@.claude/rules/architecture.md` - Clean Architecture, BLoC, Repository pattern
- **API Integration**: `@.claude/rules/backend-integration.md` - HTTP client, DTOs, error handling
- **UI/UX Standards**: `@.claude/rules/ui-standards.md` - Accessibility, theme, responsive design
- **Testing Strategy**: `@.claude/rules/testing.md` - Widget tests, integration tests, mocking
- **Specifications Reference**: `@.claude/rules/specifications.md` - Complete specs index

**Usage**: Request import by mentioning `@.claude/rules/[filename].md` when you need deep context on a specific topic.

---

## 🔧 Response Format Requirements

For **every** task, provide:

1. **Exact file paths** to modify (absolute paths relative to project root)
2. **Complete, functional code** (never pseudocode or placeholders)
3. **Specification compliance check** (confirm alignment with `docs/`)
4. **Non-regression validation** (verify no existing features broken)
5. **Multi-layer impact** (document backend changes if required)
6. **Summary** (what was done, what remains)

---

## 🏗️ Architecture Quick Reference

```
lib/
├── core/
│   ├── config/constants.dart       ← Base URLs, configuration
│   ├── theme/                      ← App theme, colors
│   └── utils/                      ← Helpers, validators
├── data/
│   ├── models/                     ← DTOs, Response models
│   ├── repositories/               ← Repository implementations
│   └── services/                   ← API services (Dio)
├── domain/
│   ├── entities/                   ← Business entities
│   ├── repositories/               ← Repository interfaces
│   └── usecases/                   ← Business logic
├── presentation/
│   ├── pages/                      ← Full screens
│   ├── widgets/                    ← Reusable components
│   └── bloc/                       ← BLoC/Cubit state management
└── main.dart
```

**Naming Conventions**:
- Files: `snake_case` (e.g., `user_profile_page.dart`)
- Classes: `PascalCase` (e.g., `UserProfilePage`)
- Variables/Functions: `camelCase` (e.g., `fetchUserProfile()`)

---

## 🚀 Before You Start

**Checklist** (mental validation):
1. ✅ Do I have all information? If not, ask precise questions
2. ✅ Have I checked `API_DOCUMENTATION.md` for endpoints?
3. ✅ Is my response complete (full code, not snippets)?
4. ✅ Are file paths specified exactly?
5. ✅ Is internationalization respected (FR/EN)?
6. ✅ Will this introduce regressions? How to verify?
7. ✅ Does this respect user privacy (no PII logging)?
8. ✅ Is content respectful and non-stigmatizing?

---

**Ready to build HIVMeet with excellence!** 🎯
