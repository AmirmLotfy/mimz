# Vision Pipeline

How camera frames flow from the device camera to Gemini Live API for vision quests.

## Architecture

```mermaid
flowchart LR
    CAM[Camera] --> CTRL_CAM[CameraController]
    CTRL_CAM --> RAW[Raw frame bytes]
    RAW --> PROCESS[Downscale + JPEG compress]
    PROCESS --> STREAM[frameStream]
    STREAM --> SESSION[LiveSessionController]
    SESSION --> WS[WebSocket — encodeImageFrame]
    WS --> GEMINI[Gemini Live API]
```

## Two Operating Modes

### One-Shot Mode
- Call `captureOneShot()` for a single frame
- Controller calls it via `attachCameraFrame()`
- User taps camera button → frame sent → Gemini analyzes

### Periodic Mode
- `startPeriodicCapture()` sends frames every N seconds (default: 2s)
- For active vision quest windows
- Controlled interval prevents flooding
- `stopPeriodicCapture()` stops the timer

## Frame Processing

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `jpegQuality` | 70 | Compression quality (0-100) |
| `maxDimension` | 640px | Downscale limit (preserves aspect ratio) |
| `frameInterval` | 2s | Time between periodic captures |

## Session Flow

```mermaid
sequenceDiagram
    participant User
    participant App as Flutter
    participant GL as Gemini Live

    App->>GL: Audio: "I see a bridge"
    GL-->>App: toolCall: start_vision_quest
    App->>App: Initialize camera
    App->>App: Start periodic frames
    App->>GL: realtimeInput { image/jpeg }
    GL-->>App: "I can see that bridge! Nice find."
    GL-->>App: toolCall: validate_vision_result
    App->>App: Backend confirms
    GL-->>App: toolCall: unlock_structure
    App->>App: Stop camera
```

## Known Limitations
- `camera` package requires platform setup (iOS NSCameraUsageDescription, Android)
- Frame processing (downscale) requires `image` package
- No video streaming — still frames only
- Camera session must be disposed on route pop
