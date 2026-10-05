# HIVMeet Messaging — Frontend Integration Contract

**Audience**: Frontend AI agent / Flutter developers  
**Authority**: This document is generated from the implemented backend. It supersedes any prior version of `FRONTEND_MESSAGING_API.md`.  
**WebSocket contract**: `docs/MESSAGES_BACKEND_WEBSOCKET_FRONTEND.md` also valid; this document folds in all WS details so you only need this file.  
**Last updated**: 2026-05-21  
**Status**: Production-ready (post-audit fixes applied)

---

## 1. Authentication

Every REST endpoint requires:
```
Authorization: Bearer <jwt_access_token>
```

Obtain the JWT from `POST /api/v1/auth/firebase-exchange/`. All 401 responses mean the token is missing or expired — refresh and retry.

---

## 2. Base URL Conventions

```
REST:      https://api.hivmeet.com/api/v1/
WebSocket: wss://api.hivmeet.com/ws/conversations/{conversation_id}/
Local WS:  ws://localhost:8000/ws/conversations/{conversation_id}/
```

`conversation_id` is the **Match UUID** (not a separate Conversation model). It appears as `conversation_id` in all responses and must be passed as the UUID in the URL path.

---

## 3. Error Envelope

All error responses use:
```json
{
  "error": "Human-readable message",
  "details": { "field_name": ["validation error"] }
}
```
`details` is present only for 400 validation errors. For 401/403/404/429/500, only `error` is present.

---

## 4. REST Endpoints

### 4.1 List Conversations

```
GET /api/v1/conversations/
```

**Auth**: required  
**Query params**: `status=archived` returns empty list (archived support not implemented yet)

**Response 200**:
```json
{
  "count": 12,
  "next": "http://api.hivmeet.com/api/v1/conversations/?page=2",
  "previous": null,
  "results": [
    {
      "conversation_id": "uuid",
      "id": "uuid",
      "other_user": {
        "user_id": "uuid",
        "display_name": "Jane Doe",
        "main_photo_url": "https://...",
        "is_online": true,
        "last_active": "2026-05-21T14:00:00+00:00"
      },
      "last_message": {
        "message_id": "uuid",
        "content_preview": "Hello!",
        "sender_id": "uuid",
        "sent_at": "2026-05-21T14:00:00+00:00",
        "is_read_by_me": false
      },
      "unread_count_for_me": 2,
      "created_at": "2026-05-01T10:00:00+00:00",
      "last_message_at": "2026-05-21T14:00:00+00:00",
      "last_activity_at": "2026-05-21T14:00:00+00:00"
    }
  ]
}
```

**Notes**:
- `last_activity_at` equals `last_message_at` (alias field).
- Conversations with no messages yet are excluded.
- Ordered by `last_message_at` descending (most recent first).
- `is_online = true` when `last_active` is within the past 5 minutes.

---

### 4.2 Get Messages

```
GET /api/v1/conversations/{conversation_id}/messages/
```

**Auth**: required  
**Query params**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `before_message_id` | UUID | — | Cursor: return messages older than this |
| `limit` | int | 50 | Max messages to return |
| `page_size` | int | 50 | Alias for `limit` |

**Response 200**:
```json
{
  "count": 120,
  "next": "?before_message_id=<oldest-id>&page_size=50",
  "previous": null,
  "results": [],
  "has_more": true,
  "show_premium_prompt": false
}
```

**Notes**:
- Non-premium users are capped at the 50 most recent messages. `show_premium_prompt=true` when history is truncated.
- `next` is a relative query-string fragment, not an absolute URL.
- Fetching messages auto-marks all received unread messages as read and fires a read notification to the sender.

---

### 4.3 Message Object Shape

All endpoints that return a message use this shape:

```json
{
  "message_id": "uuid",
  "id": "uuid",
  "client_message_id": "4d1d8a35-c8f8-42bd-8d73-3808f90e95f1",
  "conversation_id": "uuid",
  "sender_id": "uuid",
  "is_mine": true,
  "content": "Hello!",
  "message_type": "text",
  "media_url": null,
  "media_type": null,
  "media_thumbnail_url": null,
  "status": "sent",
  "sent_at": "2026-05-21T14:00:00+00:00",
  "created_at": "2026-05-21T14:00:00+00:00",
  "delivered_at": null,
  "read_at": null,
  "read_at_by_recipient": null,
  "is_sending": false
}
```

| Field | Type | Notes |
|-------|------|-------|
| `message_id` | UUID | Canonical server ID; same as `id` |
| `id` | UUID | Alias for `message_id` |
| `client_message_id` | string | Echo of the dedup key you provided |
| `conversation_id` | UUID | Match UUID |
| `sender_id` | UUID | Sender's user UUID |
| `is_mine` | bool | `true` if sent by the authenticated user |
| `content` | string | Text content; empty for pure media |
| `message_type` | enum | `text`, `image`, `video`, `audio`, `call_log` |
| `media_url` | string\|null | Full URL to media file |
| `media_type` | string\|null | `image`/`video`/`audio`, null for text |
| `media_thumbnail_url` | string\|null | Thumbnail for image/video |
| `status` | enum | `sending`, `sent`, `delivered`, `read` |
| `sent_at` | ISO 8601 | Alias for `created_at` |
| `created_at` | ISO 8601 | Server creation timestamp |
| `delivered_at` | ISO 8601\|null | Delivery timestamp |
| `read_at` | ISO 8601\|null | Read timestamp |
| `read_at_by_recipient` | ISO 8601\|null | Alias for `read_at` |
| `is_sending` | bool | `true` only when `status == "sending"` |

---

### 4.4 Send Text/Media Message

```
POST /api/v1/conversations/{conversation_id}/messages/
Content-Type: application/json
```

> **IMPORTANT — field name asymmetry**: the input field for message type is **`type`** (not `message_type`). The output object and all WS events use `message_type`. This is by design. Do not confuse the two.

**Request body**:
```json
{
  "client_message_id": "4d1d8a35-c8f8-42bd-8d73-3808f90e95f1",
  "type": "text",
  "content": "Hello!"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `client_message_id` | string | **yes** | Dedup key — resubmit same id = idempotent, returns existing message |
| `type` | enum | no (default `text`) | `text`, `image`, `video`, `audio` |
| `content` | string | if `type=text` | Max 1000 chars; HTML stripped; unsafe markup (script/data URI) rejected |
| `media_file_path_on_storage` | string | if `type=image/video/audio` | Path returned by generate-media-upload-url (§4.10) |

**Response 201**: Message object (§4.3)

**Response 400**: Validation error — content empty for text, media path missing, unsafe markup  
**Response 403**: Media type requires premium subscription  
**Response 404**: Conversation not found

**Deduplication**: If `client_message_id` matches an existing message in this conversation from this sender, the existing message is returned (idempotent, no duplicate created).

---

### 4.5 Mark Messages as Read (Bulk)

```
PUT /api/v1/conversations/{conversation_id}/messages/mark-as-read/
Content-Type: application/json
```

```json
{ "last_read_message_id": "uuid" }
```

`last_read_message_id` is optional. When omitted or null, **all** unread messages are marked as read. When provided, marks all messages up to and including that message as read.

**Response 200**:
```json
{ "messages_marked": 5 }
```

---

### 4.6 Mark Single Message as Read

```
PUT /api/v1/conversations/{conversation_id}/messages/{message_id}/read/
```

No request body required.

**Response 200**:
```json
{
  "message": "Message marked as read",
  "read_at": "2026-05-21T14:05:00+00:00"
}
```

**Response 403**: You are the sender (cannot mark own message as read)  
**Response 404**: Message not found

---

### 4.7 Delete Message (Soft Delete)

```
DELETE /api/v1/conversations/{conversation_id}/messages/{message_id}/
```

**Response 204**: No content (success)  
**Response 403**: You are not a participant  
**Response 404**: Message not found

Soft delete — message is hidden for the deleting user only. The other participant still sees it.

---

### 4.8 Typing Indicator

```
POST /api/v1/conversations/{conversation_id}/typing/
Content-Type: application/json
```

```json
{ "is_typing": true }
```

`is_typing: false` clears the indicator. Also broadcast over WS to other participant.

**Response 200**:
```json
{ "is_typing": true }
```

---

### 4.9 Conversation Presence

```
GET /api/v1/conversations/{conversation_id}/presence/
```

**Response 200**:
```json
{
  "participant": {
    "user_id": "uuid",
    "is_online": true,
    "last_active": "2026-05-21T14:00:00+00:00",
    "is_typing": false
  }
}
```

`is_online = true` when `last_active` is within the past 5 minutes.

---

### 4.10 Generate Media Upload URL

```
POST /api/v1/conversations/generate-media-upload-url/
Content-Type: application/json
```

```json
{
  "file_name": "photo.jpg",
  "content_type": "image/jpeg"
}
```

**Response 200**:
```json
{
  "upload_url": "https://storage.googleapis.com/hivmeet-media/messages/.../photo.jpg",
  "file_path_on_storage": "messages/{user_id}/{uuid}_photo.jpg",
  "content_type": "image/jpeg",
  "expires_in_seconds": 900
}
```

**Two-step media upload flow**:
1. Call this endpoint → receive `upload_url` and `file_path_on_storage`.
2. PUT the file binary directly to `upload_url` (Google Cloud Storage signed URL, client-to-GCS).
3. Send the message via §4.4 with `type=image` and `media_file_path_on_storage` = the value from step 1.

---

### 4.11 Send Media Message — Premium Shortcut (Multipart)

```
POST /api/v1/conversations/{conversation_id}/messages/media/
Content-Type: multipart/form-data
```

**Premium required** (subscription must have `media_messaging_enabled`). Non-premium → 402.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `media_file` | file | yes | Max 10 MB |
| `media_type` | enum | no (default `image`) | `image`, `video`, `audio` |
| `text` | string | no | Caption, max 500 chars |
| `client_message_id` | string | no | Dedup key |

**Response 201**: Message object (§4.3)

---

### 4.12 Calls

> **No trailing slash on call URLs**: `POST /api/v1/calls/initiate` not `/calls/initiate/`.

#### Initiate Call

```
POST /api/v1/calls/initiate
Content-Type: application/json
```

```json
{
  "target_user_id": "uuid",
  "call_type": "audio",
  "offer_sdp": "v=0\r\no=..."
}
```

`call_type`: `audio` or `video`

**Response 201**:
```json
{
  "call_id": "uuid",
  "status": "ringing",
  "message": "Call initiated. Waiting for response."
}
```

**Response 403**: Non-premium user or daily 30-min limit reached  
**Response 404**: Target user not found, or no active match

#### Initiate Premium Call (Explicit Gate)

```
POST /api/v1/calls/initiate-premium/
```

Same request body. Adds an explicit subscription check (`audio_video_calls_enabled`). On success returns the full **Call Object** (§4.12 Call Object Shape).

#### Answer Call

```
POST /api/v1/calls/{call_id}/answer
Content-Type: application/json
```

Only the callee may answer.

```json
{ "answer_sdp": "v=0\r\no=..." }
```

**Response 200**:
```json
{ "call_id": "uuid", "status": "answered", "message": "Call connected." }
```

#### Add ICE Candidate

```
POST /api/v1/calls/{call_id}/ice-candidate
Content-Type: application/json
```

Both caller and callee may submit candidates.

```json
{
  "candidate": {
    "candidate": "candidate:...",
    "sdpMid": "0",
    "sdpMLineIndex": 0
  }
}
```

**Response 204**: No content

#### Terminate Call

```
POST /api/v1/calls/{call_id}/terminate
Content-Type: application/json
```

Both caller and callee may terminate.

```json
{ "reason": "ended_by_caller" }
```

Valid `reason` values: `declined`, `ended_by_caller`, `ended_by_callee`, `no_answer`, `connection_failed`, `duration_limit_reached`

**Response 200**:
```json
{
  "call_id": "uuid",
  "status": "ended",
  "duration_seconds": 142,
  "message": "Call ended."
}
```

#### Call Object Shape

```json
{
  "id": "uuid",
  "call_type": "audio",
  "status": "ended",
  "caller_info": { "user_id": "uuid", "display_name": "Alice" },
  "callee_info": { "user_id": "uuid", "display_name": "Bob" },
  "initiated_at": "2026-05-21T14:00:00+00:00",
  "answered_at": "2026-05-21T14:00:10+00:00",
  "ended_at": "2026-05-21T14:02:32+00:00",
  "duration_seconds": 142,
  "end_reason": "ended_by_caller"
}
```

Call `status` values: `ringing`, `answered`, `ended`, `declined`

---

## 5. WebSocket — Real-Time Messaging

### 5.1 Connection

```
wss://api.hivmeet.com/ws/conversations/{conversation_id}/
```

**Authentication** — two methods (use whichever WebSocket client supports):
1. Header: `Authorization: Bearer <jwt_access_token>`
2. Query string: `?token=<jwt_access_token>` (Flutter / browser fallback)

**Close codes**:

| Code | Meaning |
|------|---------|
| 4000 | Token missing or invalid |
| 4001 | User not a participant, or conversation not found/not active |
| 4999 | Internal server error |

### 5.2 Real-Time Delivery Guarantee

Both write paths now deliver `message.created` to all connected WS participants:

- **REST POST** → `MessageService.send_message` → `post_save` signal → `channel_layer.group_send(conversation_{id}, message_created)`.
- **WS `message.send`** → same service → same signal → same broadcast.

The sender **also** receives the `message.created` echo (to get the server-assigned `message_id` and reconcile optimistic state).

### 5.3 Client → Server Events

#### Send Text Message
```json
{
  "type": "message.send",
  "content": "Hello via WebSocket",
  "client_message_id": "4d1d8a35-c8f8-42bd-8d73-3808f90e95f1"
}
```
- `content` required, non-empty after trim.
- `client_message_id` optional but strongly recommended for dedup and optimistic reconciliation.
- Text only via WS. For image/video/audio, use REST §4.11.

#### Typing Start / Stop
```json
{ "type": "typing.start" }
{ "type": "typing.stop" }
```

#### Ping
```json
{ "type": "ping" }
```

#### WebRTC ICE Candidate
```json
{
  "type": "ice.candidate",
  "candidate": "candidate:...",
  "sdpMid": "0",
  "sdpMLineIndex": 0
}
```

#### WebRTC Offer
```json
{
  "type": "offer",
  "call_id": "uuid-optional",
  "offer": { "type": "offer", "sdp": "v=0..." }
}
```

#### WebRTC Answer
```json
{
  "type": "answer",
  "call_id": "uuid-optional",
  "answer": { "type": "answer", "sdp": "v=0..." }
}
```

### 5.4 Server → Client Events

#### message.created
Received by all participants when any message is persisted (via REST or WS).
```json
{
  "type": "message.created",
  "message_id": "uuid",
  "conversation_id": "uuid",
  "sender_id": "uuid",
  "content": "Hello!",
  "message_type": "text",
  "sent_at": "2026-05-21T14:05:50+00:00",
  "client_message_id": "4d1d8a35-c8f8-42bd-8d73-3808f90e95f1"
}
```

Note: output field is `message_type` (not `type`).

#### typing.indicator
```json
{
  "type": "typing.indicator",
  "user_id": "uuid",
  "status": "typing"
}
```
`status`: `"typing"` or `"stopped"`. Sender does not receive their own typing events.

#### presence.update
```json
{
  "type": "presence.update",
  "user_id": "uuid",
  "status": "online",
  "timestamp": "2026-05-21T14:05:49+00:00"
}
```
`status`: `"online"` or `"offline"`. Self-events suppressed.

#### pong
```json
{ "type": "pong", "timestamp": "2026-05-21T14:05:50+00:00" }
```

#### ice.candidate (forwarded)
```json
{
  "type": "ice.candidate",
  "from_user_id": "uuid",
  "candidate": "candidate:...",
  "sdpMid": "0",
  "sdpMLineIndex": 0
}
```

#### webrtc.offer (forwarded)
```json
{
  "type": "webrtc.offer",
  "from_user_id": "uuid",
  "call_id": "uuid-or-null",
  "offer": { "type": "offer", "sdp": "v=0..." }
}
```

#### webrtc.answer (forwarded)
```json
{
  "type": "webrtc.answer",
  "from_user_id": "uuid",
  "call_id": "uuid-or-null",
  "answer": { "type": "answer", "sdp": "v=0..." }
}
```

#### incoming_call
Sent to all participants when a call enters ringing state. The caller does not receive this event.
```json
{
  "type": "incoming_call",
  "call": {
    "id": "uuid",
    "caller_id": "uuid",
    "caller_name": "Alice",
    "call_type": "audio",
    "match_id": "uuid"
  }
}
```

#### call_update
Sent to all participants when call status changes to answered, ended, or declined.
```json
{
  "type": "call_update",
  "call": {
    "id": "uuid",
    "status": "ended",
    "end_reason": "ended_by_caller"
  }
}
```
`end_reason` is non-null only when `status == "ended"`.

#### error
```json
{
  "type": "error",
  "message": "Message cannot be empty",
  "code": "EMPTY_MESSAGE"
}
```
Known codes: `INVALID_JSON`, `INTERNAL_ERROR`, `EMPTY_MESSAGE`, `CREATION_FAILED`, `SEND_FAILED`.

---

## 6. Premium Gating Summary

| Feature | Gate |
|---------|------|
| Message history beyond 50 messages | `is_premium = true` |
| Send media messages (image/video/audio) | Active subscription with `media_messaging_enabled` |
| Audio/video calls (`/calls/initiate`) | `is_premium` + 30-min/day cap enforced by service |
| Audio/video calls (`/calls/initiate-premium/`) | Subscription with `audio_video_calls_enabled` |

Premium error:
```json
{ "error": "This feature requires a premium subscription." }
```
HTTP 402 from the subscription gate, or HTTP 403 from the service layer.

---

## 7. HTTP Status Code Reference

| Code | Meaning |
|------|---------|
| 200 | Success (read, update) |
| 201 | Resource created (message sent, call initiated) |
| 204 | Action succeeded, no body (delete, ICE candidate) |
| 400 | Validation error (`details` field present) |
| 401 | JWT token missing or expired |
| 402 | Premium subscription required |
| 403 | Forbidden (not owner, premium required from service layer) |
| 404 | Resource not found |
| 429 | Rate limit exceeded |
| 500 | Server error |

---

## 8. Critical Implementation Notes

1. **`client_message_id` is the dedup key** across REST and WS. Always generate a UUID client-side before sending, store it locally, and use the `message_id` from `message.created` to replace any optimistic local ID.

2. **Input vs output naming**: REST POST uses `"type"` (input). All responses and WS events use `"message_type"` (output). These are different field names for the same concept.

3. **WS text only**: WS `message.send` supports text messages only. Media requires REST (§4.11).

4. **WS sender echo**: The sender also receives `message.created` for their own message — this is intentional and provides the server-assigned `message_id`.

5. **Both paths deliver to WS**: REST-sent and WS-sent messages both trigger `message.created` to all connected participants in the conversation group.

6. **Calls require an active match**: `Match.status == "ACTIVE"` between the two users. No match → 404.

7. **Call URL format**: `/api/v1/calls/initiate` (no trailing slash), unlike conversation endpoints which use trailing slashes.

8. **Conversation ID = Match ID**: There is no separate Conversation model. The UUID used in all messaging URLs is the Match UUID.

## Phase 2 ? Actions, masquage et alertes de lecture

- `PATCH /api/v1/conversations/{conversation_id}/messages/{message_id}/` modifie
  un texte intact appartenant ? l?auteur Premium dans les quinze minutes. La
  r?ponse contient `edited_at`; les erreurs m?tier sont stables et ne modifient
  jamais le message.
- `PUT /api/v1/conversations/{conversation_id}/restore/` annule un masquage de
  fa?on idempotente. Seul un nouveau message entrant r?tablit automatiquement
  la conversation chez son destinataire.
- `message.updated` contient `conversation_id`, `message_id`, `content` et
  `edited_at`; Flutter remplace la bulle sans recharger l??cran.
- Les doubles coches restent accessibles ? tous. Les alertes push de lecture
  exigent un abonnement Premium actif et la pr?f?rence
  `message_read_notifications`; elles ne figurent jamais dans la liste des
  notifications.

