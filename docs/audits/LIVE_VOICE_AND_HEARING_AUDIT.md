# LIVE VOICE + HEARING AUDIT — Mimz
> Last updated: 2026-03-15

## The App Really Talks and Really Hears

This doc describes the real end-to-end live voice pipeline.

---

## Mic Input (Hearing)

### Implementation
- **Package:** `record ^6.2.0`
- **Service:** `LiveAudioCaptureService` (features/live/data/)
- **Format:** PCM 16-bit LE, 16kHz, mono
- **Stream:** Chunk-by-chunk `Uint8List` broadcast stream
- **Permission:** `requestPermission()` → `AudioRecorder.hasPermission()`

### Flow
```
User speaks
  → AudioRecorder.startStream(PCM 16-bit, 16kHz, mono)
  → Uint8List chunks
  → LiveSessionController._audioCaptureSub
  → LiveWebSocketClient.sendAudio(pcm) 
  → dart encode: {"realtimeInput": {"mediaChunks": [{"mimeType": "audio/pcm;rate=16000", "data": <base64>}]}}
  → WebSocket.add(json)
  → Gemini Live API
```

### Permission Guard
- `LivePermissionGuard.checkPermissions(needsMicrophone: true)`
- On failure: `phase = failed`, `LiveErrorRecovery.fatal`
- Shown to user in `LiveQuizScreen` overlay

---

## Audio Output (Talking)

### Implementation
- **Package:** `just_audio ^0.9.42`
- **Service:** `LiveAudioPlaybackService` (features/live/data/)
- **Format:** Raw PCM 24kHz → WAV header prepended → `StreamAudioSource`
- **Queue:** FIFO chunk queue, sequential playback

### Flow
```
Gemini emits audio
  → WebSocket receives: serverContent.modelTurn.parts[].inlineData
  → LiveMessageCodec decodes → AudioChunkReceived(data, mimeType)
  → LiveSessionController._handleEvent(AudioChunkReceived)
  → AudioPlaybackService.enqueue(Uint8List, mimeType)
  → _addWavHeader(pcmBytes, 24000)
  → AudioPlayer.setAudioSource(MemoryAudioSource)
  → AudioPlayer.play()
```

---

## Barge-In (Interruption)

- User taps mic button while model is speaking → `interruptWithUserSpeech()`
- `AudioPlaybackService.stopImmediately()` → clears queue, stops AudioPlayer
- `AudioCaptureService.startCapture()` resumes
- Phase → `userSpeaking`
- WebSocket remains open — no reconnect needed

---

## Session Lifecycle

```
idle → fetchingToken → connecting → handshaking
  → connected
    ↕ modelSpeaking ↔ userSpeaking ↔ waitingForToolResult
  → ended | failed | reconnecting
```

- `LiveReconnectPolicy`: exponential backoff, max N retries
- `inactivityTimer`: fires `SessionWarning` when no input for configured duration
- `_sessionDurationTimer`: hard cap per session type (e.g., quiz = 10 min)

---

## Turn Detection

- `LiveTurnDetector` processes `LiveEvent`s
- Tracks `modelSpeaking` vs `userSpeaking` based on audio events + playback state
- Exported as `turnStream: Stream<TurnState>`

---

## What Is Not Yet Perfect

| Gap | Impact | Fix |
|-----|--------|-----|
| Waveform shows static bars (no amplitude) | Visual only — bars animate by size, not mic energy | Medium: feed audio chunk RMS to waveform |
| No VAD (Voice Activity Detection) | Mic sends silence continuously | Low: record's `pauseOnSilence` flag if stable |
| Text transcript of user speech depends on Gemini returning transcript | If Gemini doesn't echo transcript, userTranscript stays empty | Low: acceptable |
| Audio chunks from Gemini are played as individual WAV files | Tiny pause between chunks possible | Medium: stream audio instead of chunk-by-chunk |

---

## Summary

**The app genuinely talks and genuinely hears.** The full pipeline from mic → WebSocket → Gemini → audio → speaker is real, using production-ready packages. Barge-in works. Reconnect works. Permission is guarded. Session lifecycle is correct.

The experience quality of the audio (voice naturalness, latency) depends on the Gemini Live API itself, not the Flutter app.
