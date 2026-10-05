# Diagnostic Real-Time Messaging - HIVMeet

**Quick Check Script** - Run this before testing to verify everything is ready.

---

## 🔍 Step 1: Check Infrastructure

### Redis Status
```bash
docker ps --filter "name=hivmeet-redis" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected Output**:
```
NAMES           STATUS       PORTS
hivmeet-redis   Up ...       0.0.0.0:6379->6379/tcp
```

**If NOT running**:
```bash
docker start hivmeet-redis
# Or restart if needed:
docker restart hivmeet-redis
```

---

### Backend Status
```bash
netstat -ano | findstr :8000
```

**Expected Output**:
```
TCP    0.0.0.0:8000    0.0.0.0:0    LISTENING    [PID]
```

**If NOT running**:
1. Navigate to backend directory
2. Activate virtual environment
3. Run: `python manage.py runserver 0.0.0.0:8000`

---

### Frontend Status
```bash
flutter doctor
```

**Expected**: No critical issues

**Run App**:
```bash
# For multi-device testing (your script)
.\run_flutter_multi.ps1
```

---

## 🔍 Step 2: Test WebSocket Connection

### Backend Logs to Watch

When you open a conversation in the Flutter app, watch for these logs in the **backend terminal**:

```
✅ SUCCESS:
WebSocket CONNECTED: conversation_{uuid}
Channel layer configured: redis://127.0.0.1:6379

❌ FAILURE:
redis.exceptions.ConnectionError: Error 61001 connecting to 127.0.0.1:6379
→ Redis not running!

❌ FAILURE:
WebSocket DISCONNECT
→ Token expired or network issue
```

---

### Frontend Logs to Watch

In the **Flutter debug console**, watch for:

```
✅ SUCCESS:
[WS] Connecting to ws://192.168.1.118:8000/ws/conversations/{id}/
[WS] Connected successfully

❌ FAILURE:
[WS] Connection failed: WebSocketChannelException: Connection failed
→ Check backend URL in app_config.dart
→ Verify backend is running
```

---

## 🔍 Step 3: Test Message Delivery

### Quick Test (2 Devices)

1. **Device 1**: Login as User1, open conversation with User2
2. **Device 2**: Login as User2, open same conversation
3. **Device 1**: Send message "Test 123"
4. **Device 2**: Watch for instant appearance (< 2 seconds)

### Backend Logs
```
✅ SUCCESS:
POST /api/v1/conversations/{id}/messages/ 201
Message created: message_id={uuid}
Message websocket dispatch successful: message_id={uuid}

❌ FAILURE:
POST /api/v1/conversations/{id}/messages/ 201
Message created: message_id={uuid}
Message websocket dispatch failed: message_id={uuid}
→ Redis channel layer issue
```

### Frontend Logs (Device 2)
```
✅ SUCCESS:
WebSocket event received: message_created
New message added to list

❌ FAILURE:
(No WebSocket event logs)
→ WebSocket not connected or not broadcasting
```

---

## 🔍 Step 4: Test Typing Indicators

### Quick Test

1. **Device 1**: Open conversation, tap input field, start typing
2. **Device 2**: Watch for typing indicator

### Backend Logs
```
✅ SUCCESS:
POST /api/v1/conversations/{id}/typing/ 200
Typing event broadcast: conversation_{id}

❌ FAILURE:
POST /api/v1/conversations/{id}/typing/ 400
→ Invalid conversation ID or not authenticated
```

### Frontend Logs (Device 2)
```
✅ SUCCESS:
WebSocket event received: typing
Typing indicator shown

❌ FAILURE:
(No typing event received)
→ Typing event not broadcast or WebSocket issue
```

---

## 🔍 Step 5: Test Read Receipts

### Quick Test

1. **Device 1**: Send message to User2
2. **Device 1**: Check message status (should show ✓ or ✓✓ gray)
3. **Device 2**: Open conversation (marks as read)
4. **Device 1**: Check message status (should change to ✓✓ purple)

### Backend Logs
```
✅ SUCCESS:
PUT /api/v1/conversations/{id}/messages/mark-as-read/ 200
Messages marked as read: conversation_id={id}
Read receipt broadcast: message_id={uuid}

❌ FAILURE:
PUT /api/v1/conversations/{id}/messages/mark-as-read/ 400
→ Invalid conversation ID
```

### Frontend Logs (Device 1)
```
✅ SUCCESS:
WebSocket event received: message_read
Message status updated to read

❌ FAILURE:
(No message_read event)
→ Backend not broadcasting read receipts
```

---

## 🐛 Common Issues & Solutions

### Issue 1: WebSocket Won't Connect

**Symptoms**:
- Frontend logs: "Connection failed"
- Backend logs: Nothing

**Checklist**:
- [ ] Redis running: `docker ps --filter "name=hivmeet-redis"`
- [ ] Backend running: `netstat -ano | findstr :8000`
- [ ] Correct URL in `app_config.dart`:
  - Emulator: `ws://10.0.2.2:8000`
  - Physical: `ws://YOUR_IP:8000`

**Solution**:
```bash
# Restart everything
docker restart hivmeet-redis
# Restart backend
python manage.py runserver 0.0.0.0:8000
# Restart Flutter app
flutter run
```

---

### Issue 2: Messages Don't Appear in Real-Time

**Symptoms**:
- WebSocket connected
- Message sends successfully
- Recipient needs to refresh to see it

**Checklist**:
- [ ] Backend logs show "Message websocket dispatch successful"
- [ ] Redis is running
- [ ] Frontend WebSocket service is listening to events

**Solution**:
```bash
# Check Redis connectivity
docker exec -it hivmeet-redis redis-cli ping
# Should return: PONG

# Check backend channel layer configuration
# In settings.py:
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {"hosts": [("127.0.0.1", 6379)]},
    },
}
```

---

### Issue 3: Typing Indicators Not Showing

**Symptoms**:
- Typing indicator never appears
- No errors in logs

**Checklist**:
- [ ] WebSocket connected
- [ ] Typing API endpoint returns 200
- [ ] Backend broadcasts typing events

**Solution**:
1. Check `ConversationConsumer._handle_typing_start()` in backend
2. Verify typing event is sent to correct group: `conversation_{id}`
3. Check frontend `ChatBloc._onSetTypingStatus()` sends typing events

---

### Issue 4: Read Receipts Not Updating

**Symptoms**:
- Checkmarks stay gray
- Never turn purple

**Checklist**:
- [ ] Mark-as-read API returns 200
- [ ] Backend broadcasts `message_read` events
- [ ] Frontend listens to `WsEventType.messageRead`

**Solution**:
1. Check backend signal handler for `post_save` on Message
2. Verify read receipt broadcast logic
3. Check `ChatBloc._onWsMessageRead()` handler

---

## 📊 Quick Diagnostic Commands

### All-in-One Status Check
```bash
# Redis
echo "=== REDIS STATUS ==="
docker ps --filter "name=hivmeet-redis" --format "table {{.Names}}\t{{.Status}}"

# Backend
echo "=== BACKEND STATUS ==="
netstat -ano | findstr :8000

# Test Redis
echo "=== REDIS PING TEST ==="
docker exec -it hivmeet-redis redis-cli ping
```

---

## 🎯 Test Readiness Checklist

Before starting live testing, verify:

- [ ] Redis container running (Up status)
- [ ] Backend Daphne server running on port 8000
- [ ] Flutter app compiled without errors
- [ ] Two devices/emulators ready for testing
- [ ] Backend logs visible in separate terminal
- [ ] Frontend debug console accessible
- [ ] Test users logged in (User1 and User2)
- [ ] At least one conversation exists between users

---

## 📝 Test Session Log Template

```
=== TEST SESSION - 2026-07-27 ===

**Infrastructure**:
- Redis: [ ] Running [ ] Not running
- Backend: [ ] Running [ ] Not running
- Frontend: [ ] Compiled [ ] Errors

**Test 1: WebSocket Connection**
- Device 1: [ ] Connected [ ] Failed
- Device 2: [ ] Connected [ ] Failed
- Logs: [Paste relevant logs]

**Test 2: Real-Time Messages**
- Status: [ ] PASS [ ] FAIL
- Latency: ___ seconds
- Notes: [Observations]

**Test 3: Typing Indicators**
- Status: [ ] PASS [ ] FAIL
- Latency: ___ seconds
- Notes: [Observations]

**Test 4: Read Receipts**
- Status: [ ] PASS [ ] FAIL
- Checkmarks: [ ] Changed color [ ] Stayed gray
- Notes: [Observations]

**Issues Found**:
1. [Description]
2. [Description]

**Next Steps**:
1. [Action item]
2. [Action item]
```

---

**Ready to diagnose and test!** Run the diagnostic commands above and let me know what you find. 🚀
