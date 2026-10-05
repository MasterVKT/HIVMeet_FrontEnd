# Test Plan: Real-Time Messaging Features

**Date**: 2026-07-27  
**Status**: Ready for testing  
**Prerequisites**: Redis running on port 6379

---

## ✅ Infrastructure Status

### Backend
- ✅ Redis Docker container: Running on `0.0.0.0:6379`
- ✅ Django Channels: Configured with Redis channel layer
- ✅ Daphne ASGI: Running and listening on `0.0.0.0:8000`
- ✅ WebSocket consumers: `ConversationConsumer` and `UserNotificationConsumer` registered
- ✅ Message signals: Broadcasting `message_created` events via WebSocket

### Frontend
- ✅ `ChatWebSocketService`: Implemented and connected when chat opens
- ✅ `ChatBloc`: Listening to WebSocket events (`message_created`, `message_read`, `typing`, `presence`)
- ✅ WebSocket URL: Auto-configured based on device type (emulator: `ws://10.0.2.2:8000`, physical: `ws://192.168.1.118:8000`)

---

## 🧪 Test Scenarios

### Test 1: Real-Time Message Delivery (Open Conversations)

**Setup**:
1. User1 opens conversation with User2 on Device1 (emulator)
2. User2 opens same conversation on Device2 (physical device)
3. Both devices show WebSocket connection in logs: `[WS] Connecting to ws://...`

**Action**:
- User1 sends message: "Test message 1"

**Expected Results**:
- ✅ Message appears instantly on User2's screen (< 2 seconds)
- ✅ No need to refresh or navigate away/back
- ✅ Backend logs show: `Message websocket dispatch failed: message_id=...` → Should now succeed
- ✅ Console logs on Device2: Show WebSocket event received

**Validation Commands**:
```bash
# Check Redis is running
docker ps --filter "name=hivmeet-redis"

# Check backend logs for WebSocket events
# Look for: "Message websocket dispatch failed" → Should disappear
# Look for: "Conversation websocket connected" → Should appear
```

---

### Test 2: Typing Indicators

**Setup**:
- Both users have conversation open

**Action**:
- User1 starts typing (enters text in input field)

**Expected Results**:
- ✅ User2 sees typing indicator appear within 1-2 seconds
- ✅ Indicator shows animated dots with text "User1 est en train d'écrire..."
- ✅ Indicator disappears after 3 seconds of inactivity
- ✅ Backend logs show: `POST /api/v1/conversations/{id}/typing/ 200`

**Frontend Implementation Status**:
- ✅ Backend: Typing events handled in `ConversationConsumer._handle_typing_start()`
- ✅ Frontend: `ChatBloc._onSetTypingStatus()` sends typing events via WebSocket
- ⚠️ UI Widget: Typing indicator widget may need to be created/enhanced

---

### Test 3: Message Read Receipts (Backend Broadcast)

**Setup**:
- User1 sends message to User2
- User2 opens conversation

**Action**:
- User2 views message (message marked as read)

**Expected Results**:
- ✅ Backend broadcasts `message_read` event via WebSocket
- ✅ Backend logs: `PUT /api/v1/conversations/{id}/messages/mark-as-read/ 200`
- ⚠️ Frontend: May need to listen to `message_read` events and update UI

**Current Status**:
- ✅ Backend: Signal handler exists but may not broadcast read receipts via WebSocket
- ⚠️ Frontend: `ChatBloc` has handler for `WsEventType.messageRead` but needs verification

---

### Test 4: Conversation List Updates (New Message Preview)

**Setup**:
- User1 on Device1, User2 on Device2
- User2 navigates away from conversation list to another screen

**Action**:
- User1 sends message to User2

**Expected Results**:
- ⚠️ **KNOWN GAP**: Conversation list does NOT update in real-time
- ❌ Last message preview doesn't update automatically
- ❌ Unread badge count doesn't increment automatically
- ✅ Update occurs when User2 pulls to refresh or navigates back to list

**Root Cause**:
- `ConversationsBloc` doesn't listen to general notification WebSocket
- Backend broadcasts to `conversation_{id}` room, not to user's notification channel

**Solution Options**:
1. **Option A (Recommended)**: Create `NotificationWebSocketService` to listen to `user_{user_id}` group
2. **Option B**: Use Firebase Cloud Messaging push notifications
3. **Option C**: Implement periodic polling (every 30 seconds)

**Temporary Workaround**:
- Add pull-to-refresh on conversation list
- Refresh conversation list when app comes to foreground

---

### Test 5: Message Order Preservation

**Setup**:
- Both users have conversation open
- Rapid-fire multiple messages (5-10 messages in quick succession)

**Expected Results**:
- ✅ Messages appear in chronological order (oldest to newest)
- ✅ No duplicates
- ✅ No messages out of order
- ✅ Timestamps correctly preserved

**Validation**:
- Check `ChatBloc._sortByCreatedAt()` method
- Verify backend orders by `created_at ASC`

---

### Test 6: Scroll-to-Bottom Button

**Setup**:
- Open conversation with many messages (scrollable)

**Action**:
- Scroll up to view old messages
- Scroll back down to bottom

**Expected Results**:
- ✅ Button appears when scrolled up
- ✅ Button disappears when at bottom
- ✅ Button centered horizontally (not right-aligned)
- ✅ Clicking button smoothly scrolls to last message
- ✅ Button doesn't obscure message content

**Current Issues** (from user report):
- ❌ Button always visible (doesn't auto-hide)
- ❌ Positioned on right (should be centered)
- ❌ Overlays message content

---

### Test 7: Scroll to First Unread Message

**Setup**:
- User2 has 5 unread messages from User1
- User2 opens conversation

**Expected Results**:
- ✅ Conversation auto-scrolls to first unread message
- ✅ User can read messages in chronological order
- ✅ "Scroll to bottom" button visible if user wants to jump to latest
- ✅ Fallback: Scroll to bottom if no unread messages

**Current Status**:
- ⚠️ May need implementation/enhancement

---

## 📊 Test Results Template

| Test | Status | Notes |
|------|--------|-------|
| 1. Real-time message delivery | ⏳ Pending | Awaiting test execution |
| 2. Typing indicators | ⏳ Pending | UI widget may need work |
| 3. Read receipts broadcast | ⏳ Pending | Backend may need enhancement |
| 4. Conversation list updates | ❌ Known gap | Requires notification service |
| 5. Message order preservation | ⏳ Pending | Awaiting test |
| 6. Scroll-to-bottom button | ⏳ Pending | UI fixes needed |
| 7. Scroll to first unread | ⏳ Pending | May need implementation |

---

## 🔧 Troubleshooting Guide

### Issue: WebSocket Connection Fails

**Symptoms**:
- Logs show: `WebSocket DISCONNECT` or `Connection refused`
- No real-time updates

**Checklist**:
1. ✅ Redis running: `docker ps --filter "name=hivmeet-redis"`
2. ✅ Backend running on correct IP: `netstat -ano | findstr :8000`
3. ✅ Frontend URL matches backend IP (check `app_config.dart`)
4. ✅ Firewall allows connections on port 8000

**Common Fixes**:
- Restart Redis: `docker restart hivmeet-redis`
- Restart backend: Ctrl+C, then `python manage.py runserver 0.0.0.0:8000`
- Update `app_config.dart` with correct physical device IP

---

### Issue: Messages Not Appearing in Real-Time

**Symptoms**:
- WebSocket connected but messages don't appear
- Backend logs show: `Message websocket dispatch failed`

**Checklist**:
1. ✅ Check Redis logs: `docker logs hivmeet-redis`
2. ✅ Check backend logs for Redis connection errors
3. ✅ Verify conversation_id is valid UUID format
4. ✅ Verify both users are authenticated

**Debug Steps**:
```bash
# Test Redis connectivity
docker exec -it hivmeet-redis redis-cli ping
# Should return: PONG

# Check backend Redis connection
# In backend logs, look for: "redis.exceptions.ConnectionError"
```

---

### Issue: Typing Indicators Not Showing

**Symptoms**:
- No typing indicator appears when user types

**Checklist**:
1. ✅ WebSocket connected
2. ✅ Typing API endpoint returns 200: `POST /conversations/{id}/typing/`
3. ✅ Frontend sends typing events: Check `ChatBloc._onSetTypingStatus()`
4. ✅ Backend broadcasts typing events: Check `ConversationConsumer._handle_typing_start()`

---

## 🎯 Next Steps After Testing

1. **Execute Tests**: Run through all 7 test scenarios
2. **Document Results**: Fill in test results table
3. **Fix Identified Issues**: Prioritize based on user impact
4. **Implement Missing Features**:
   - Notification WebSocket service (for conversation list updates)
   - Read receipt UI (WhatsApp-style checkmarks)
   - Typing indicator UI widget
   - Scroll-to-bottom button improvements
   - Auto-scroll to first unread message

---

## 📝 Notes

- **Redis is the key**: All real-time features depend on Redis being operational
- **Backend logs are critical**: They show exactly where WebSocket events fail
- **Test on both devices**: Emulator and physical device may have different network configurations
- **Gradual rollout**: Fix one feature at a time, test thoroughly, then move to next

---

**Last Updated**: 2026-07-27  
**Tested By**: [Your name]  
**Backend Version**: Django 4.2.7, Daphne 4.0.0  
**Frontend Version**: Flutter [version]
