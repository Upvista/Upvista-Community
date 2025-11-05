# Quick Testing Guide - Video & Media Features

## 🚀 Setup (Required Before Testing)

### 1. Database Migration
```bash
# Option A: Supabase SQL Editor
# Copy contents of backend/scripts/add_video_support.sql
# Paste and run in Supabase SQL Editor

# Option B: Command line (if you have psql)
cd backend
psql <your-connection-string> < scripts/add_video_support.sql
```

### 2. Restart Backend
```bash
cd backend
# Stop current server (Ctrl+C)
go run main.go
```

### 3. Frontend (Should Auto-Reload)
- Already running
- Should hot-reload automatically
- If issues: Refresh browser (Ctrl+Shift+R)

---

## ✅ Test Checklist

### Video Upload & Playback
- [ ] Click attachment → Video option appears (red icon)
- [ ] Select video file (MP4, WebM, or MOV)
- [ ] Quality dialog appears
- [ ] Choose "Standard" or "HD"
- [ ] See progress: "Compressing video... X%"
- [ ] Video uploads successfully
- [ ] Video appears in chat with thumbnail
- [ ] Click play → Video plays inline
- [ ] Controls work (play/pause, seek, speed, mute)
- [ ] Click video → Opens fullscreen in MediaViewer
- [ ] Video plays in MediaViewer with native controls

### Audio Compression
- [ ] Record voice message
- [ ] Send it
- [ ] Check console: "Audio compressed: XKB → YKB"
- [ ] Voice message plays normally
- [ ] File size is smaller than before

### Progressive Image Loading
- [ ] Send 5-10 images
- [ ] Scroll up to hide images
- [ ] Scroll down slowly
- [ ] See blur placeholder appear first
- [ ] See smooth fade-in to full image
- [ ] Check console: "[ImageCache] Cached image..."

### Single Media Playback
- [ ] Play audio message #1
- [ ] Play audio message #2
- [ ] **Verify**: #1 stops, only #2 plays
- [ ] Play video
- [ ] **Verify**: Audio stops, only video plays
- [ ] Play another video
- [ ] **Verify**: First video stops

### Error Handling
- [ ] Try uploading 150MB video
- [ ] **Expected**: Error toast "Video too large (max 100MB)"
- [ ] Try invalid file
- [ ] **Expected**: Error toast

---

## 🐛 Troubleshooting

### "Loading FFmpeg core..." never completes:
- Check browser version (Chrome 92+, Firefox 89+)
- Check console for SharedArrayBuffer errors
- Try different browser
- If fails: System will fall back to original file upload

### Video doesn't play in chat:
- Check if video uploaded successfully
- Check console for errors
- Verify message_type is 'video'
- Try opening in MediaViewer (click on video)

### Compression too slow:
- Normal for large videos (1-2 min for 5-min video)
- Watch progress bar
- CPU-intensive operation
- Consider using smaller videos for testing

### "Upload failed" error:
- Check backend logs
- Verify Supabase bucket exists: `chat-attachments`
- Check bucket allows `video/*` MIME types
- Verify file size < 100MB

---

## 📊 Expected Performance

### Compression Times:
- 10-second video: ~10 seconds
- 30-second video: ~20-30 seconds  
- 1-minute video: ~40-60 seconds
- 5-minute video: ~2-3 minutes

### File Size Reductions:
- Video (Standard): 60-70% smaller
- Video (HD): 40-50% smaller
- Audio (Voice): 70-80% smaller
- Images: Already optimized

---

## 🎯 What to Verify

### Video:
1. Uploads successfully
2. Compresses to smaller size
3. Plays inline with controls
4. Expands to fullscreen
5. Only one video plays at once
6. Thumbnail shows before play

### Audio:
1. Compresses smaller (check logs)
2. Quality still good
3. Only one audio plays at once
4. Pause actually pauses

### Images:
1. Blur placeholder appears
2. Smooth transition to full image
3. Loads only when in viewport
4. Cached for fast re-display

---

## ✅ Success Indicators

Console should show:
```
✅ [FFmpeg] FFmpeg.wasm loaded successfully!
✅ [ChatWindow] Video compressed 70% smaller!
✅ [AudioCompression] Compressed 70% reduction
✅ [ImageCache] Cached image: photo.jpg
✅ [VideoPlayer] PLAYING video: https://...
✅ [VideoPlayer] Pausing other video to play this one
```

Toast notifications should show:
```
✅ "Loading FFmpeg core... (~30MB)" (first time only)
✅ "Compressing video... 45%"
✅ "Video compressed 70% smaller!"
✅ "Video sent successfully!"
✅ "Compressed 70% smaller" (audio)
```

---

## 🎉 Ready to Test!

**All features implemented and ready for testing!**

Start with:
1. Run migration
2. Restart backend
3. Upload a small test video (10-20 seconds)
4. Watch the magic happen! 🎥✨

