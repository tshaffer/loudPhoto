# LoudPhoto

Photo capture app that records a linked audio clip (configurable duration)
starting the instant the shutter fires. Designed to eventually feed captures
into Tedography.

## First-time setup

1. Install XcodeGen if you don't have it:
   ```
   brew install xcodegen
   ```
2. Generate the Xcode project:
   ```
   xcodegen generate
   ```
3. Open `LoudPhoto.xcodeproj`, select your Development Team under
   Signing & Capabilities, and run on a real device (camera/mic don't work
   in the Simulator).

## Storage format

Each capture is stored in the app's Documents/Captures directory as three
files sharing a UUID basename:

- `<uuid>.jpg` — the photo
- `<uuid>.m4a` — the linked audio clip (absent if capture had no audio,
  which shouldn't normally happen, or audio failed)
- `<uuid>.json` — metadata (CaptureItem: dateCreated, configuredDurationSeconds,
  audioDurationSeconds, filenames)

This flat, self-describing layout is meant to be easy to import into
Tedography later — no database, just files.

## Architecture

- `Services/CameraService.swift` — AVCaptureSession, photo capture, pinch-zoom, flip camera
- `Services/AudioCaptureService.swift` — AVAudioRecorder, duration timer, early-stop
- `Services/CaptureStore.swift` — reads/writes the Captures directory
- `Views/CaptureView.swift` — capture screen (viewfinder, shutter, duration picker)
- `Views/ShutterButtonView.swift` — idle/recording shutter states (Spectre-style progress ring)
- `Views/GalleryView.swift` — grid of captures with audio badge
- `Views/DetailView.swift` + `AudioPlaybackView.swift` — full photo + audio playback
- `Views/SettingsView.swift` — audio duration setting

## Requirements not yet implemented

- Nothing pending — pinch-to-zoom, early-stop-via-shutter, and configurable
  duration are all wired up in this scaffold.
