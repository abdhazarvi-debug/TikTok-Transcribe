# Testing Plan and Actual Status

## Actual status at repository bootstrap

- Prompt and project constraints documented: PASS (content added; not a code validation).
- Whisper build/model test: BLOCKED / NOT RUN.
- Urdu WER/CER benchmark: NOT RUN.
- Android JVM tests: NOT RUN; there is not yet a Gradle Android project.
- UI/instrumented tests: NOT RUN.
- Release smoke test: NOT RUN; no APK exists.

## Required tests after the quality gate passes

Follow the master engineering prompt. At minimum test URL parsing, language mapping, filename sanitization, UTF-8 round-trip, Urdu/mixed-script handling, TXT/Markdown/JSON formatting, model checksum verification, retry logic, cancellation, temporary-file cleanup, and hallucination filtering.

Run real audio conversion fixtures plus short speech, silence-only, and music-only transcription fixtures. Then run `./gradlew testDebugUnitTest`, actual local-file transcription, `assembleRelease`, APK inspection, and a release smoke test on a physical device/emulator.

Instrumented tests are not claimed by CI unless an emulator/device is configured. CI must use recorded downloader fixtures rather than live TikTok URLs.

For every regression: reproduce with a failing test, fix the root cause, rerun the focused tests and the suite. Do not weaken/delete tests to make CI green.
