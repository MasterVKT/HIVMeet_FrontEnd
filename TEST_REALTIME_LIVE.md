# Test Real-Time Messaging - Live Session

**Date**: 2026-07-27  
**Infrastructure Status**: ✅ READY

---

## ✅ Prerequisites Verified

- [x] **Redis**: Running on port 6379 (hivmeet-redis container - Up 2 hours)
- [x] **Backend**: Daphne ASGI server running on 0.0.0.0:8000 (PID: 29360)
- [x] **Frontend**: Flutter app ready with WebSocket integration
- [x] **Code**: No compilation errors

---

## 🧪 Test Execution Plan

### Test 1: WebSocket Connection (Infrastructure Validation)

**Objective**: Verify WebSocket connects successfully

**Steps**:
1. Launch Flutter app on emulator or physical device
2. Navigate to any conversation
3. Check debug console for WebSocket logs

**Expected Logs**:
```
✅ [WS] Connecting to ws://192.168.1.118:8000/ws/conversations/{id}/
✅ WebSocket event received: connected (or similar success message)
```

**Backend Logs** (check terminal):
```
✅ WebSocket CONNECTED: conversation_{id}
```

**If Failed**:
```
❌ [WS] Connection failed: ...
❌ Backend: redis.exceptions.ConnectionError: Error 61001 connecting to 127.0.0.1:6379
```

**Fix**: Restart Redis → `docker restart hivmeet-redis`

---

### Test 2: Real-Time Message Delivery (Core Feature)

**Setup Required**:
- Device 1: Emulator or physical device (User1)
- Device 2: Different emulator or physical device (User2)
- Both devices logged in as different users
- Both devices have same conversation open

**Steps**:
1. Open conversation between User1 and User2 on **both devices**
2. On Device 1 (User1): Send message "Test message from User1"
3. Watch Device 2 (User2) screen

**Expected Result**:
- ✅ Message appears on Device 2 within **1-2 seconds**
- ✅ No refresh needed
- ✅ No navigation away/back required
- ✅ Message shows correct timestamp and sender

**Backend Logs**:
```
✅ POST /api/v1/conversations/{id}/messages/ 201
✅ Message websocket dispatch successful: message_id=...
```

**If Message Doesn't Appear**:
1. Check backend logs for "Message websocket dispatch failed"
2. Verify Redis is running: `docker ps --filter "name=hivmeet-redis"`
3. Check WebSocket connection in frontend logs
4. Verify conversation_id is valid UUID

---

### Test 3: Typing Indicators

**Setup**: Same as Test 2 (both devices with conversation open)

**Steps**:
1. On Device 1: Tap message input field and start typing
2. Watch Device 2 screen

**Expected Result**:
- ✅ Within 1-2 seconds, Device 2 shows typing indicator
- ✅ Indicator displays: "User1 est en train d'écrire..."
- ✅ Animated dots (...) appear
- ✅ Indicator disappears after 3 seconds of inactivity
- ✅ Indicator reappears if User1 types again

**Backend Logs**:
```
✅ POST /api/v1/conversations/{id}/typing/ 200
✅ Typing event broadcast: conversation_{id}
```

**If Not Working**:
1. Check backend logs for typing endpoint calls
2. Verify WebSocket is connected
3. Check ChatBloc handler for typing events

---

### Test 4: Read Receipts (WhatsApp-Style Checkmarks)

**Setup**:
- User1 sends message to User2
- User2 has NOT opened conversation yet

**Steps**:
1. User1 sends message: "Hello, can you read this?"
2. User1 checks message status on their device
3. User2 opens conversation
4. User1 checks message status again

**Expected Result**:

**Before User2 opens**:
- ✅ User1 sees: ✓ (single gray check) = **sent**
- OR: ✓✓ (double gray check) = **delivered** (if backend marks as delivered on receipt)

**After User2 opens conversation**:
- ✅ User1 sees: ✓✓ (double **purple** check) = **read**
- Color changes from gray to purple within 1-2 seconds

**Backend Logs**:
```
✅ PUT /api/v1/conversations/{id}/messages/mark-as-read/ 200
✅ Read receipt broadcast: message_id=...
```

**If Not Working**:
1. Check if mark-as-read API is called when User2 opens conversation
2. Verify backend broadcasts `message_read` events
3. Check ChatBloc handler for `WsEventType.messageRead`
4. Verify `MessageBubble` renders correct icon based on `message.status`

---

### Test 5: Scroll Button Behavior

**Setup**: Open conversation with 10+ messages

**Steps**:
1. Scroll to bottom (all messages visible)
2. Verify button is **hidden**
3. Scroll up ~5 messages
4. Verify button **appears**
5. Verify button is **centered horizontally** (not right-aligned)
6. Tap button
7. Verify smooth scroll animation to bottom
8. Verify button hides again at bottom

**Expected Result**:
- ✅ Button hidden when at bottom
- ✅ Button appears when scrolled up > 200px
- ✅ Button centered (left: 0, right: 0, Center widget)
- ✅ Smooth scroll animation (300ms)
- ✅ Button has unique heroTag: 'scrollToBottom'

**If Not Working**:
1. Check `_showScrollToBottom` state in `chat_page.dart`
2. Verify `_onScroll()` listener is attached
3. Check `_buildScrollToBottomButton()` implementation

---

### Test 6: Scroll to First Unread Message

**Setup**:
- User2 has 5+ unread messages from User1
- User2 closes app or navigates away
- User1 sends 2 more messages

**Steps**:
1. User2 opens conversation
2. Observe scroll position

**Expected Result**:
- ✅ Conversation auto-scrolls to **first unread message** (not bottom)
- ✅ User can read messages in chronological order
- ✅ If no unread messages: scroll to bottom
- ✅ "Scroll to bottom" button visible if user wants to jump to latest

**If Not Working**:
1. Check `_scrollToFirstUnread()` method in `chat_page.dart`
2. Verify `WidgetsBinding.instance.addPostFrameCallback` is called
3. Check if messages have correct `isRead` flag

---

### Test 7: Conversation List Updates (Requires Integration)

**Status**: ⚠️ **PENDING** - Requires `NotificationWebSocketService` integration with `ConversationsBloc`

**Current Behavior**:
- ❌ Conversation list does NOT update in real-time
- ❌ Last message preview doesn't change automatically
- ❌ Unread badge count doesn't increment automatically
- ✅ Updates on pull-to-refresh or navigation back to list

**Expected After Integration**:
- ✅ User2 navigates away from conversation list
- ✅ User1 sends message
- ✅ User2's conversation list updates automatically
- ✅ Last message preview shows new message
- ✅ Unread badge increments

**Integration Required**:
1. Register `NotificationWebSocketService` in DI
2. Add listener in `ConversationsBloc` for `new_message` events
3. Trigger `RefreshConversations()` on new message
4. Connect service on app startup

---

## 📊 Test Results Template

Copy and fill this template as you test:

```markdown
### Test Results

**Test 1: WebSocket Connection**
- Status: [ ] PASS [ ] FAIL [ ] PENDING
- Device: [Emulator/Physical]
- Logs: [Paste relevant logs]
- Notes: [Any observations]

**Test 2: Real-Time Message Delivery**
- Status: [ ] PASS [ ] FAIL [ ] PENDING
- Device 1: [Emulator/Physical]
- Device 2: [Emulator/Physical]
- Latency: [Time in seconds]
- Logs: [Paste relevant logs]
- Notes: [Any observations]

**Test 3: Typing Indicators**
- Status: [ ] PASS [ ] FAIL [ ] PENDING
- Latency: [Time in seconds]
- Notes: [Any observations]

**Test 4: Read Receipts**
- Status: [ ] PASS [ ] FAIL [ ] PENDING
- Checkmarks observed: [ ] ✓ (sent) [ ] ✓✓ gray (delivered) [ ] ✓✓ purple (read)
- Latency: [Time in seconds]
- Notes: [Any observations]

**Test 5: Scroll Button**
- Status: [ ] PASS [ ] FAIL [ ] PENDING
- Auto-hide: [ ] Working [ ] Not working
- Centered: [ ] Yes [ ] No (right-aligned)
- Scroll animation: [ ] Smooth [ ] Janky
- Notes: [Any observations]

**Test 6: Scroll to First Unread**
- Status: [ ] PASS [ ] FAIL [ ] PENDING
- Scrolled to: [ ] First unread [ ] Bottom [ ] Middle
- Notes: [Any observations]

**Test 7: Conversation List Updates**
- Status: [ ] PENDING (requires integration)
```

---

## 🔍 Debugging Commands

### Check Redis
```bash
# Is Redis running?
docker ps --filter "name=hivmeet-redis"

# Test Redis connectivity
docker exec -it hivmeet-redis redis-cli ping
# Should return: PONG

# View Redis logs
docker logs hivmeet-redis
```

### Check Backend
```bash
# Is Daphne running on port 8000?
netstat -ano | findstr :8000

# Restart backend (if needed)
# In backend directory:
python manage.py runserver 0.0.0.0:8000
```

### Check Frontend
```bash
# Run Flutter app
flutter run

# View logs (if running on multiple devices)
# Check each device's debug console separately
```

### Common Issues & Fixes

**Issue**: WebSocket connection fails with "Connection refused"
**Fix**: 
1. Verify backend is running: `netstat -ano | findstr :8000`
2. Check frontend URL in `app_config.dart` matches backend IP
3. For emulator: use `ws://10.0.2.2:8000`
4. For physical device: use `ws://YOUR_LAPTOP_IP:8000`

**Issue**: "redis.exceptions.ConnectionError: Error 61001"
**Fix**: 
```bash
docker restart hivmeet-redis
# Verify: docker ps --filter "name=hivmeet-redis"
```

**Issue**: Messages appear but not in real-time (need refresh)
**Fix**:
1. Check backend logs for "Message websocket dispatch failed"
2. Verify Redis is running
3. Check WebSocket connection in frontend logs
4. Verify conversation_id is valid UUID

**Issue**: Typing indicator doesn't appear
**Fix**:
1. Check backend logs for typing endpoint calls
2. Verify WebSocket is connected
3. Check if typing event is broadcast to correct conversation room

---

## 📝 Next Steps After Testing

1. **Execute Tests**: Run through all 7 scenarios
2. **Document Results**: Fill in test results template
3. **Report Issues**: Share any failures or unexpected behavior
4. **Complete Integration** (if Test 7 is priority):
   - Register `NotificationWebSocketService` in DI
   - Integrate with `ConversationsBloc`
   - Test conversation list updates

---

**Ready to start testing!** 

Which test would you like to run first? I recommend starting with **Test 1 (WebSocket Connection)** to validate infrastructure, then **Test 2 (Real-Time Message Delivery)** for the core feature.

Let me know the results as you test! 🚀
