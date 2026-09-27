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

- `<uuid>.heic` — the photo (HEIC/HEVC on supported hardware; falls back to
  `.jpg` on the Simulator or older devices where HEIC capture isn't
  available). Matches how Tedography already treats HEIC — as an archival
  original it derives a display JPEG from, same as it does for RAW camera
  files.
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

## Sharing to Tedography

Gallery supports multi-select (`Select` button, top right); Detail has a
share icon for a single capture. Both package the photo + audio +
metadata.json into one `.zip` (one subfolder per capture) and hand it to
the standard iOS share sheet, so AirDrop / Messages / Save to Files all
work the same way they do from the Photos app today. A Tedography-side
importer to unzip and ingest these is still to be built.

Uses [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) (SPM
dependency, declared in project.yml) to build the zip — Xcode will
resolve it automatically on first build (needs network access once).

## Requirements not yet implemented

- Tedography-side import of the shared zip format
- Direct upload from LoudPhoto to Tedography's backend (currently AirDrop/Messages-based, matching the existing photo workflow)
