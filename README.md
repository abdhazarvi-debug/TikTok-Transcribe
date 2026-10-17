# TikTok Transcript — Android

An Android app project targeting on-device multilingual speech transcription for publicly accessible TikTok videos, with a focus on Urdu, Hindi, English, and automatic language detection.

> **Current status: FEASIBILITY BLOCKED.** This repository currently contains the project plan and verification workflow, not a completed Android app. No APK is claimed to exist. Whisper model/Urdu benchmark measurements and the Android build have not been completed.

## Intended app

1. Paste a public TikTok URL or select a local media file.
2. Choose Urdu, Hindi, English, or Auto Detect.
3. Check duration before downloading the full video (maximum 5 minutes).
4. Download permitted public media, normalize audio to 16 kHz mono PCM WAV, and transcribe on-device using multilingual Whisper.
5. Review, copy, save, or share TXT, Markdown, or JSON output.

On-device recognition is the goal. Downloading a speech model requires internet once; acquiring a TikTok video requires internet each time. A language hint is not translation.

## Start here

- [Master engineering prompt](docs/MASTER_ENGINEERING_PROMPT.md) — original supplied requirements.
- [Phase 0 results](docs/PHASE_0_RESULTS.md) — evidence and still-missing measurements.
- [Decisions and audit](docs/DECISIONS.md) — verified/blocker register.
- [Testing plan](docs/TESTING.md)
- [Privacy and use notes](docs/PRIVACY.md)
- [Dependencies and licenses](docs/DEPENDENCIES_AND_LICENSES.md)
- [Architecture target](docs/ARCHITECTURE.md)
- [Release report](docs/RELEASE_REPORT.md)

## Mandatory quality gate

**Do not implement the production Android pipeline until the Urdu feasibility gate has real evidence.** Benchmark at least five licensed Urdu speech clips against reference transcripts, using the supplied prompt's normalization rules. Report per-clip and median WER plus CER, model size and SHA-256, processing time, and hallucination behavior on silence/music. The specified initial gate is median WER ≤ 35%; if measured median WER is higher, stop and report rather than proceeding with UI work.

The supplied prompt calls Phase 0a “NO network required” while also requiring source/model/clip downloads. This contradiction is explicitly documented and must be resolved; do not silently mark an unexecuted benchmark as passed.

## CI behavior

GitHub Actions runs a feasibility gate. Android build and unit-test steps remain skipped until `docs/PHASE_0_RESULTS.md` contains the exact line `GO_DECISION: GO`. Once that line is present, missing Gradle/Android project files are reported as failures rather than treated as success. A successful gate-only workflow run is **not** an Android build and does not mean an APK exists.

CI must not test against live TikTok URLs. Instrumented tests/device smoke tests must be described as not run unless actually run on a configured emulator or physical device.

## Current verification state

- Production Android implementation: NOT RUN / NOT IMPLEMENTED.
- Whisper model download and transcription: BLOCKED / NOT RUN.
- Urdu WER/CER: NOT RUN.
- Android build and APK: NOT RUN.
- Physical-device validation: NOT RUN.
- GitHub Actions: workflow has been added; check the Actions tab for the actual run result after the commit.

## Legal, privacy, and platform notes

Only publicly accessible videos are in scope. Do not bypass DRM, login walls, or access controls. TikTok extraction can break when upstream behavior changes. Review current platform terms before using or distributing the application. The repository currently contains an MIT LICENSE from its initial setup, but dependency-license compatibility is **not** verified; do not distribute until the actual downloaded dependency licenses have been inspected and the project license/required notices reconciled.
