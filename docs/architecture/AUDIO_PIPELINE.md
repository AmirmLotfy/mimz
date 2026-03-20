# Audio Pipeline

How audio flows between the user's microphone, Flutter, and Gemini Live API.

## Capture Pipeline

```mermaid
flowchart LR
    MIC[Microphone] --> REC[record package]
    REC --> PCM[PCM 16-bit LE, 16kHz, mono]
    PCM --> STREAM[StreamController]
    STREAM --> CTRL[LiveSessionController]
    CTRL --> WS[WebSocket — encodeAudioChunk]
    WS --> GEMINI[Gemini Live API]
```

### Configuration
- Format: PCM 16-bit little-endian
- Sample rate: 16,000 Hz
- Channels: 1 (mono)
- Chunk size: ~640 bytes (20ms at 16kHz × 2 bytes)

### Lifecycle
1. Permission checked by `LivePermissionGuard`
2. `startCapture()` opens mic stream
3. Each chunk flows through `audioStream` to the controller
4. Controller calls `_ws.sendAudio(chunk)` which base64-encodes via codec
5. `pauseCapture()` / `resumeCapture()` for barge-in
6. `stopCapture()` + disposal on session end

## Playback Pipeline

```mermaid
flowchart LR
    GEMINI[Gemini Live API] --> WS[WebSocket]
    WS --> CODEC[LiveMessageCodec.decode]
    CODEC --> AUDIO[AudioChunkReceived event]
    AUDIO --> CTRL[Controller]
    CTRL --> QUEUE[Playback Queue]
    QUEUE --> PLAY[AudioPlayer / PCM writer]
    PLAY --> SPEAKER[Speaker]
```

### Queue Behavior
- Chunks are queued and played sequentially
- No overlap — next chunk plays only after current finishes
- Duration estimated from PCM size: `bytes / 48` ms (24kHz × 2 bytes)
- `stopImmediately()` clears queue + stops current playback (barge-in)
- `flushQueue()` discards remaining without stopping current
- State exposed via `playbackStateStream`

## Barge-In (Interruption)

```mermaid
sequenceDiagram
    participant User
    participant Mic as AudioCapture
    participant Play as AudioPlayback
    participant TD as TurnDetector
    participant Ctrl as Controller

    Note over Play: Model speaking...
    User->>Mic: Starts talking
    Mic->>TD: onMicActivity(true)
    TD->>Ctrl: TurnState.userSpeaking
    TD-->>Ctrl: shouldBargeIn() = true
    Ctrl->>Play: stopImmediately()
    Ctrl->>Mic: startCapture()
    Note over Ctrl: Phase → userSpeaking
```

## Known Limitations
- Actual `record` package integration requires platform setup (iOS Info.plist, Android manifest)
- PCM playback via `just_audio` needs temporary file writes
- No echo cancellation — relies on device AEC
