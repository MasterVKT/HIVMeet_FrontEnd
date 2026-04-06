# Backend Change Required - Discovery Filters Contract Gaps

## Scope
This document lists backend-side risks that can still block full end-to-end behavior for Discovery filters, even after frontend contract compliance updates.

## 1. Relationship Types Filtering Can Over-Exclude Profiles

Endpoint: GET /api/v1/discovery/profiles

Observed Risk:
- In some environments, applying relationship_types may return zero profiles even when compatible profiles exist.
- Frontend now sends contract-compliant values (friendship, long_term, short_term, casual), including [] for no filter.

Expected Backend Behavior:
- [] must mean no relationship filter.
- ["all"] must be normalized to [] before filtering.
- relationship_types filter must perform overlap semantics with target profile relationship_types_sought (or open profiles).

Request Example:
```json
{
  "age_min": 25,
  "age_max": 40,
  "distance_max_km": 50,
  "genders": [],
  "relationship_types": ["long_term", "casual"],
  "verified_only": true,
  "online_only": false
}
```

Expected Response (200):
```json
{
  "count": 10,
  "next": "?page=2&page_size=10",
  "previous": null,
  "results": [],
  "daily_likes_remaining": 9,
  "daily_likes_limit": 10,
  "daily_likes_used_today": 1,
  "daily_likes_reset_at": "2026-03-28T00:00:00+00:00",
  "is_premium": false,
  "super_likes_remaining": 1
}
```

Error Response (400):
```json
{
  "error": true,
  "message": "Validation error",
  "details": {
    "relationship_types": ["Invalid relationship types: unknown_type"]
  }
}
```

Rationale:
- Prevent false empty discovery results and align with documented contract semantics.

## 2. Deterministic Contract Test Data Setup Endpoint/Procedure Needed

Need:
- A deterministic test-data setup procedure for Discovery filters contract tests in non-production environments.
- Current frontend API contract tests are deterministic by payload/assertions, but backend data state must also be deterministic to validate profile selection behavior reliably.

Requested Backend Support (one option):
- Option A: documented admin-only seed script/procedure with fixed users/profiles/interactions.
- Option B: protected test endpoint to reset and seed discovery fixture data.

Suggested Endpoint (if Option B):
- POST /api/v1/testing/discovery/seed

Suggested Request:
```json
{
  "fixture": "filters_contract_v1",
  "reset": true
}
```

Suggested Success Response (200):
```json
{
  "status": "success",
  "fixture": "filters_contract_v1",
  "profiles_seeded": 20,
  "interactions_seeded": 0
}
```

Rationale:
- Guarantees reproducible API-level verification for all filter combinations.

## 3. Validation Reminder for Error Contract

Endpoints:
- PUT /api/v1/discovery/filters
- GET /api/v1/discovery/filters/get

Expected validation codes/messages:
- 400 for invalid bounds/enums
- 401 for missing/invalid auth
- 404 for missing profile

Rationale:
- Frontend now maps and validates by this contract; behavior divergence causes user-facing inconsistency.
