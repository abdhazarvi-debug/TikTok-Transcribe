# Planned Architecture — Not Yet Implemented

This is a target design based on the supplied master engineering prompt. It is not evidence that the components exist or have been tested.

```text
Compose UI
  └── ViewModel / workflow state machine
       ├── Model manager (download, checksum, atomic rename)
       ├── Public TikTok downloader wrapper (yt-dlp Android)
       ├── Audio normalization to 16 kHz mono signed-16-bit PCM WAV
       ├── Whisper JNI bridge (native multilingual whisper.cpp)
       ├── Hallucination filtering and transcript formatting
       └── SAF exports (TXT / Markdown / JSON)
```

Planned workflow states: `Idle → Validating → DownloadingModel → DownloadingMedia → ExtractingAudio → Transcribing → Completed | Failed | Cancelled`.

## Constraints

- Speech recognition runs on-device; language selection is a hint, not translation.
- Use a pinned `whisper.cpp` revision; never follow `main` for production.
- Verify model downloads with measured SHA-256 and atomically move only verified files into place.
- JNI callbacks must support progress, segments, cancellation, thread attachment, and UTF-8-safe strings.
- Do not use WorkManager for long-running native transcription; use a correctly declared foreground service.
- Enforce the five-minute limit before downloading the full video.
- Keep logs local and redact URLs, cookies, and transcript text by default.
- Implement production Android code only after the measured Urdu WER/CER gate permits continuation.
