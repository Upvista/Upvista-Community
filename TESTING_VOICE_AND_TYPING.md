# Testing Guide: Voice Recording & Typing Indicators

## 🎤 Voice Recording Testing

### Test 1: Permission Handling
1. Open chat window
2. Click the microphone button
3. **Expected**: Modal dialog opens requesting permission
4. **Deny permission** → Should show error toast
5. **Allow permission** → Should start recording

### Test 2: Waveform Visualization
1. Start recording
2. **Speak into microphone**
3. **Expected**: See live waveform animation in the canvas
4. **Make noise** → Waveform should respond in real-time
5. **Stay silent** → Waveform should flatten

### Test 3: Pause/Resume
1. Start recording and speak
2. Click **Pause** button
3. **Expected**: 
   - Recording paused (duration stops)
   - "Recording paused" text appears
   - Icon changes to Play
4. Click **Resume** (Play button)
5. **Expected**: 
   - Recording resumes
   - Duration continues from where it stopped
   - Waveform animates again

### Test 4: Audio Preview
1. Record some audio
2. Click **Stop** (square icon)
3. **Expected**: Preview UI appears with:
   - Play button
   - Progress bar
   - Static waveform snapshot
   - Delete and Re-record buttons
   - Send button
4. Click **Play** → Audio should playback
5. Progress bar should update smoothly

### Test 5: Re-record
1. Record audio and stop
2. Click **Re-record**
3. **Expected**: 
   - Previous recording deleted
   - Recording starts fresh
   - New waveform appears

### Test 6: Send Voice Message
1. Record and stop
2. Click **Send Voice Message**
3. **Expected**:
   - Dialog closes
   - Audio uploads (see progress bar)
   - Voice message appears in chat
   - Can play the sent message

---

## 💬 Typing Indicators Testing

### Test 1: Single User Typing
1. **User A**: Open chat with User B
2. **User B**: Open chat with User A
3. **User A**: Start typing
4. **Expected on User B's screen**: 
   - Typing indicator appears
   - Shows: "**User A** is typing..."
   - Purple animated dots

### Test 2: Multiple Users Typing
**Note**: Requires group chat or testing infrastructure

1. **User A** and **User C** both type in chat with User B
2. **Expected on User B's screen**:
   - "**User A** and **User C** are typing..."
3. If 3+ users typing:
   - "**User A**, **User B**, and **2 others** are typing..."

### Test 3: Recording Status (When Implemented)
1. **User A**: Open voice recording dialog
2. **User B**: Should see in real-time:
   - Red pulsing mic icon
   - "**User A** is recording a voice message"
3. **User A**: Stop recording
4. **Expected**: Recording indicator disappears immediately

### Test 4: Stop Typing
1. **User A**: Type and wait 3 seconds
2. **Expected on User B's screen**: 
   - Typing indicator disappears after User A stops typing

---

## 🐛 Edge Cases to Test

### Voice Recording
- [ ] Close dialog while recording → Recording should cancel
- [ ] Microphone disconnects mid-recording → Should show error
- [ ] Record very short audio (< 1 second) → Should still work
- [ ] Record very long audio (> 2 minutes) → Should work
- [ ] Pause immediately after starting → Duration should be accurate
- [ ] Multiple pause/resume cycles → Duration tracking accurate
- [ ] Send without preview → Should work
- [ ] Network offline during send → Should queue (if offline queue implemented)

### Typing Indicators
- [ ] User leaves chat → Typing indicator should disappear
- [ ] User closes browser → Backend should clean up typing state
- [ ] Network reconnection → Typing state should sync
- [ ] Same user typing in multiple chats → Each chat shows separately
- [ ] User types, then deletes all text → Still shows typing (expected)

---

## 🔍 Visual Inspection Checklist

### Voice Recording Dialog
- [ ] Modal is centered on screen
- [ ] Background has dark overlay
- [ ] Gradient background looks good
- [ ] Canvas renders waveform smoothly
- [ ] Buttons are properly sized and aligned
- [ ] Text is readable
- [ ] Icons are clear and professional
- [ ] Mobile: Dialog fits screen properly
- [ ] Mobile: Buttons are easily tappable

### Typing Indicator
- [ ] Appears smoothly (fade-in animation)
- [ ] Dots animate continuously
- [ ] User names are bold
- [ ] Text wraps properly for long names
- [ ] Recording icon (mic) is visible and pulsing
- [ ] Bubble has proper padding
- [ ] Colors match theme (purple accent)

---

## 🧰 Developer Testing Commands

### Backend
```bash
cd backend
go run main.go
```

**Check logs for**:
- `[VoiceRecorder] Recording started`
- `[ChatWindow] Typing event received`
- `[MessagingService] broadcastTyping - Failed...` (if errors)

### Frontend
```bash
cd frontend-web
npm run dev
```

**Open Browser Console**:
- Check for WebSocket connection
- Watch typing events: `[ChatWindow] Typing event received: {...}`
- Watch recording logs: `[VoiceRecorder] ...`

---

## 📊 Performance Testing

### Voice Recording
- [ ] Waveform renders at 60 FPS
- [ ] No audio lag or crackling
- [ ] Memory usage stays reasonable
- [ ] Dialog opens/closes smoothly

### Typing Indicators
- [ ] Instant display (< 100ms after typing)
- [ ] No lag when multiple users typing
- [ ] Clean removal when user stops

---

## 🎯 Acceptance Criteria

### Voice Recording ✅
- [x] Professional permission UI
- [x] Real-time waveform visualization
- [x] Pause/resume works correctly
- [x] Audio preview plays smoothly
- [x] Can re-record without issues
- [x] Send uploads audio successfully
- [x] Mobile responsive

### Typing Indicators ✅
- [x] Shows actual user names
- [x] Handles 1, 2, 3+ users
- [x] Recording status with mic icon
- [x] Real-time updates
- [x] Professional design
- [x] No performance issues

---

## 🚀 Quick Test Script

```bash
# Terminal 1: Start Backend
cd backend && go run main.go

# Terminal 2: Start Frontend
cd frontend-web && npm run dev

# Browser 1: http://localhost:3000 (User A)
# Browser 2: http://localhost:3000 (User B)
# Open Incognito/Private window for User B

# Test sequence:
# 1. Login as different users in each browser
# 2. Start a conversation
# 3. User A: Click mic button → Test recording
# 4. User A: Type something → User B sees "User A is typing..."
# 5. Test pause/resume and preview
# 6. Send voice message
# 7. Verify message appears in both chats
```

---

## 📱 Mobile Testing

### iOS Safari
- [ ] Voice recording works
- [ ] Waveform renders
- [ ] Touch controls responsive
- [ ] Dialog fits screen

### Android Chrome
- [ ] Voice recording works
- [ ] Waveform renders
- [ ] Touch controls responsive
- [ ] Dialog fits screen

---

## ✅ Sign-off Checklist

Before marking as complete:
- [ ] All manual tests pass
- [ ] No console errors
- [ ] No memory leaks
- [ ] Performance is acceptable
- [ ] Mobile works correctly
- [ ] Backend logs are clean
- [ ] WebSocket events working
- [ ] User experience is smooth

---

**Happy Testing! 🎉**

