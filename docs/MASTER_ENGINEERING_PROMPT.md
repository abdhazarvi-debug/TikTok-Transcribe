# MASTER ENGINEERING PROMPT v2.1 FINAL — TikTok Transcript (Android)

> **v2.1 Revision:** Adds 10 critical fixes from third audit (Phase 0 parity, JNI both-direction threading, .gitignore, runtime update security, duration check point, WorkManager scope, version catalog, Phase 0 results artifact, whisper CLI reality, Phase 0 split into 3 sub-phases). Also adds §17 Self-Audit Checklist.

## 0. ROLE

Senior Android / Kotlin / NDK / multimedia / on-device ML / QA / release engineer. Deliver a complete installable Android APK named **TikTok Transcript**. Work in the actual repository. Execute real builds and real tests. Never claim success without evidence.

---

## 1. TRUTHFULNESS CONTRACT

Never fabricate: build/test results, device compatibility, dependency availability, model sizes/checksums, download success, accuracy numbers, APK links, CI runs.

Result labels:
- **PASS** — executed, met defined criteria
- **FAIL** — executed, did not meet criteria
- **BLOCKED** — demonstrated external limitation
- **NOT RUN** — not executed

Never label a dependency "verified" unless you personally resolved and tested it. Until then: **"candidate"**.

---

## 2. NON-NEGOTIABLE RULES

1. No fake completion. No empty implementations. No mocked production pipelines.
2. No unresolved `TODO`/`FIXME` in production paths.
3. Preserve the workspace. Run `git status` first. Never overwrite unrelated user files.
4. Execute real commands. Read exit codes. Investigate first meaningful failure.
5. Do not suppress errors to go green.
6. If SDK/NDK/network cannot be set up within 30 minutes, STOP and report `BLOCKED` with the exact missing tool.
7. Prefer a tested MVP over a broad, half-tested feature set.
8. **This prompt has known limitations.** §17 forces you to identify and document them.

---

## 3. PRODUCT REQUIREMENTS

Android app that transcribes **publicly accessible** TikTok videos with **on-device** speech-to-text.

Workflow: paste TikTok URL → select language (اردو/ہندی/English/Auto) → tap Transcribe → model download (first run) → video download → audio extract → local whisper → display transcript → Copy/Save/Share.

Optional fallback: pick a local video/audio file if TikTok download fails.

**User must never need:** Termux, Python, Node.js, FFmpeg, CLI, any separate tool.

### Technology baseline (all candidates — verify each)

| Component | Candidate |
|---|---|
| Kotlin | current stable (pin exact) |
| Compose BOM | current stable (pin exact) |
| minSdk / targetSdk / compileSdk | 26 / 35 / 35 |
| AGP / Gradle wrapper / JDK | pin compatible trio |
| NDK | latest r27.x (verify with `sdkmanager --list`) |
| CMake | 3.22.1 (via sdkmanager) |
| Release ABI | `arm64-v8a` |
| Debug ABI | `arm64-v8a` + `x86_64` |

**Use Gradle version catalog** (`gradle/libs.versions.toml`) for all versions. Commit it.

---

## 4. DEPENDENCY CANDIDATES

### 4.1 TikTok downloader
```
io.github.junkfood02.youtubedl-android:library:<pinned-tag>
io.github.junkfood02.youtubedl-android:ffmpeg:<pinned-tag>
```
Bundles Python 3.8 runtime + yt-dlp.

**Phase B must verify:**
- (a) Bundled Python version. If 3.8, the runtime-update mechanism may not work with modern yt-dlp (Python 3.9+ required). Document this.
- (b) Actual Maven coordinates resolve (`./gradlew :app:dependencies`).
- (c) Actual package name inside the AAR (for ProGuard rules — likely `com.yausername.**`, verify by unpacking).
- (d) License file content (see §10).
- (e) On-device: initialize and download one small video.

Manifest: `android:extractNativeLibs="true"` OR `packaging { jniLibs { useLegacyPackaging = true } }`.

### 4.2 Audio processing — try in this order
1. ffmpeg bundled with youtubedl-android.
2. Android `MediaExtractor` + `MediaCodec` + resampler. **Resampler must be explicit:** ExoPlayer's `SonicAudioProcessor` (~5-10 MB), or write a simple linear resampler (~200 LOC), or skip this path.
3. Only if 1 & 2 fail: `dev.ffmpegkit-maintained:ffmpeg-kit-audio:<verified-tag>`. Never `com.arthenica:ffmpeg-kit-*` (retired April 2025).

Contract: input any container → output 16 kHz mono PCM signed-16-bit LE WAV.

### 4.3 Whisper (on-device)

Build whisper.cpp with NDK 27+. Pin exact git tag/commit. Vendor source or submodule — never track `main`.

**CMake flags:**
```cmake
-DANDROID_ABI=arm64-v8a
-DANDROID_PLATFORM=android-26
-DBUILD_SHARED_LIBS=ON
-DGGML_LLAMAFILE=ON
-DCMAKE_BUILD_TYPE=Release
```
```cmake
# Linker flag (correct syntax):
target_link_options(whisper PRIVATE "-Wl,-z,max-page-size=16384")
```

**ARM CPU feature handling:** Do NOT blindly use `-march=armv8.2-a+dotprod` — this crashes on older ARMv8.0 devices. Options:
- Build baseline (armv8-a) only. Slower but universal.
- OR build two variants and select at runtime via `android_getCpuFeatures()` from NDK `cpu-features.h`.

Document the choice.

**Multiple `.so`:** `BUILD_SHARED_LIBS=ON` produces several libraries (whisper, ggml, etc.). Load in correct order in Kotlin, OR use `BUILD_SHARED_LIBS=OFF` for a single static lib + one JNI `.so`.

### 4.4 Speech model

Do NOT hardcode sizes from memory. Download, measure, compute SHA-256 in Phase B.

Candidates (verify each):
- `ggml-base-q5_0.bin`
- `ggml-small-q5_0.bin`
- `ggml-small-q8_0.bin`
- `ggml-medium-q5_0.bin`

Never use `.en` models.

Source: pinned commit URL, not `resolve/main`:
`https://huggingface.co/ggerganov/whisper.cpp/resolve/<commit>/<file>`

Urdu accuracy unknown until Phase 0 measures it. Do not publish a percentage without a benchmark.

---

## 5. FEASIBILITY GATE — THREE SUB-PHASES

### Phase 0a — Local audio proof (NO network required, AGENT MUST COMPLETE)

1. Build whisper.cpp CLI on the agent host:
   ```bash
   git clone https://github.com/ggerganov/whisper.cpp
   cd whisper.cpp && git checkout <pinned-tag>
   cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j
   ```
2. Download a candidate model (verify size + SHA-256).
3. Get 5 Urdu reference clips:
   - Preferred: public **Common Voice Urdu** clips, OR
   - Public Urdu podcast samples, OR
   - Any license-clear Urdu audio
4. Extract 16 kHz mono PCM via ffmpeg.
5. Run `whisper-cli -m <model> -f <wav> -l ur`.
6. Measure WER with the normalization rules in §11.
7. Repeat with 2+ candidate models.

**Output:** `docs/PHASE_0_RESULTS.md` with measured sizes, hashes, WER per clip, median WER, target pass/fail, sample transcript.

### Phase 0b — TikTok acquisition proof (network required, best-effort)

**Critical:** Use the **exact yt-dlp version bundled in youtubedl-android** — not the latest pip release. Extract it from the AAR or note the version and install that specific version. A newer yt-dlp on the desktop does NOT prove the bundled one works.

If TikTok network access is unavailable:
- Mark 0b as `BLOCKED` with the exact error.
- Continue with 0a results only.

Test 3-5 real public videos: plain Urdu, mixed, English, music-only, silence-only.

### Phase 0c — Go/No-Go decision

Based on 0a (and 0b if available):
- If median WER > 35% (see §11): **STOP**. Do not write Android code. Deliver Phase 0 results + recommendation.
- If acceptable: continue to Phase 1.

### Phase 1 — Android pipeline proof

With emulator/device + network:
1. Init youtubedl-android, download one small video.
2. Extract audio.
3. Transcribe via JNI.
4. Log transcript (no UI yet).

If Phase 1 is impossible in the agent environment: **deliver a local-file MVP** (pick a WAV via SAF, transcribe). Document the TikTok downloader as `BLOCKED`.

**Never build the full UI on an unproven pipeline.**

---

## 6. JNI INTERFACE (CRITICAL — READ CAREFULLY)

The v1 interface was blocking and could not support progress/cancel/partial-save. Correct design:

### Kotlin side

```kotlin
package com.tiktoktranscript.whisper   // package MUST match JNI symbol prefix

interface WhisperCallback {
    fun onProgress(percent: Int)              // 0..100
    fun onSegment(startMs: Long, endMs: Long, text: String)
    fun isCancelled(): Boolean
}

object WhisperBridge {
    init { System.loadLibrary("whisper_bridge") }

    external fun initContext(modelPath: String): Long
    external fun transcribe(
        ctx: Long,
        pcmWavPath: String,
        languageCode: String,        // "ur" | "hi" | "en" | "auto"
        callback: WhisperCallback
    ): Int                            // 0 = ok, <0 = error code
    external fun freeContext(ctx: Long)
}
```

**Note:** Kotlin lambdas cannot be passed to JNI. Use an `interface` — the object is passed as `jobject`, and the bridge calls methods by ID.

### C++ side

```cpp
static JavaVM* g_jvm = nullptr;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

// Helper — attach current thread if needed
struct ScopedEnv {
    JNIEnv* env; bool attached;
    ScopedEnv() {
        if (g_jvm->GetEnv((void**)&env, JNI_VERSION_1_6) == JNI_EDETACHED) {
            g_jvm->AttachCurrentThread(&env, nullptr);
            attached = true;
        } else attached = false;
    }
    ~ScopedEnv() { if (attached) g_jvm->DetachCurrentThread(); }
};
```

**Every callback from a native thread MUST use `ScopedEnv`** — both directions:
- C++ worker thread → Kotlin `onProgress`/`onSegment`
- whisper internal thread → C++ `isCancelled` check → back to Kotlin

Cache method IDs once via `GetObjectClass` + `GetMethodID`. Create a global ref for the callback object if used across calls.

**UTF-8 safety:** pass segments as `jbyteArray`, not `jstring`. Use `env->NewByteArray` + `SetByteArrayRegion`. On Kotlin side, `String(bytes, Charsets.UTF_8)`. This avoids `NewStringUTF` crashes on partial multi-byte sequences from whisper tokens.

**Abort:** wire `isCancelled` to whisper's abort callback.

---

## 7. ARCHITECTURE

```
ui/                  Compose screens
viewmodel/           UI state, events, errors
domain/              Workflow state machine
data/downloader/     youtubedl-android wrapper
data/model/          Model manifest, download, validation
data/transcription/  JNI + Kotlin wrapper
data/audio/          Audio extraction + resampling
data/export/         TXT / MD / JSON
data/storage/        Temp files, metadata
native/              C/C++ + JNI bridge
docs/                Setup, decisions, testing, privacy, licenses
```

States: `Idle → Validating → DownloadingModel → DownloadingMedia → ExtractingAudio → Transcribing → Completed | Failed | Cancelled`

### Background execution

| Task | Mechanism |
|---|---|
| Model download (466 MB) | **WorkManager** — network constraints, retry, crash recovery |
| Video download | **WorkManager** or foreground service |
| Audio extraction + Whisper | **Foreground service** — `mediaProcessing` on API 34+, `dataSync` on API 26–33 |

At runtime, choose service type by `Build.VERSION.SDK_INT`. `mediaProcessing` (API 34) and `onTimeout()` (API 35) do NOT exist on older APIs.

Do NOT use WorkManager for the transcription step (long-running, native-heavy).

---

## 8. LANGUAGE & TRANSCRIPTION RULES

Mapping: اردو→`ur`, ہندی→`hi`, English→`en`, خودکار→auto-detect flag (verify API).

When Urdu selected:
- Output Urdu script. Do NOT translate.
- Preserve English terms where model recognizes them. **Acknowledge in UI/docs that whisper often renders English words in Urdu script when `-l ur` — model behavior, not a bug.**
- Preserve UTF-8 without corruption (use ByteArray path).
- On failure, show error — never fake text.

Language hint is NOT translation. State this in UI and README.

### Hallucination handling

Whisper fabricates text on silence/music. Mitigate:
1. VAD or whisper's built-in no-speech handling.
2. Drop segments with `no_speech_prob > 0.6` AND duration < 500 ms.
3. If all segments dropped → "No speech detected".
4. Short known-hallucination phrase list (best-effort, ~10 phrases).

Test silence-only and music-only cases in Phase 0.

---

## 9. MODEL MANAGEMENT

Manifest per model (from Phase B measurements): id, pinned URL, measured size, SHA-256, license, recommended minimum RAM (per model — e.g. base ~500 MB, small ~800 MB, medium ~2000 MB; measure, don't guess).

First-run:
1. Explain one-time download.
2. Show real size.
3. `DownloadManager` (native resume).
4. Save to `context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)/models/`.
5. Use `setDestinationInExternalFilesDir(context, DIRECTORY_DOWNLOADS, "models/<file>")`.
6. Verify SHA-256; atomic rename on success; delete on mismatch.

Never redownload on every run. Never execute code from model path.

---

## 10. LICENSING (MANDATORY)

Read each dependency's `LICENSE` file. Record in `docs/DEPENDENCIES_AND_LICENSES.md`.

**youtubedl-android license:** Verify. If GPL-3.0 AND you distribute the app → whole app must be GPL-3.0-compatible with source. If strictly personal use and not distributed, GPL obligations don't trigger. Since this project produces GitHub Actions APKs, assume distribution → plan for GPL-3.0:
- Add `LICENSE` file (GPL-3.0 text).
- Add SPDX identifiers to source files.
- Provide source archive alongside APK.
- State it in `README.md`.

If the license turns out to be MIT (verify — different forks differ), then no GPL obligations.

**TikTok ToS:** automated downloading may violate TikTok's terms. Personal/educational use only. State in README and `docs/PRIVACY.md`.

**Runtime yt-dlp update security (if implemented):**
- Source: yt-dlp's official GitHub releases only.
- Verify SHA-256 against published hash before installing.
- Verify binary runs (`--version` returns expected format).
- Keep previous version for rollback.
- On any failure, keep bundled version.
- Document this code path in `docs/PRIVACY.md`.
- **If these safeguards cannot be implemented, skip runtime update entirely.** Rely on APK updates.

---

## 11. TRANSCRIPTION QUALITY BENCHMARK

**Dataset:** 5+ Urdu clips (Phase 0a), 8+ if TikTok access available.

**Normalization rules (define before WER):**
- Strip diacritics/اعراب.
- Normalize ی/ے، ہ/ھ، ک/ك.
- Normalize Arabic-Indic digits (۰۱۲۳) to ASCII — or document decision not to.
- Collapse whitespace. Drop punctuation.
- **Do NOT strip ZWNJ (U+200C) / ZWJ (U+200D)** — they carry meaning in Urdu and stripping inflates accuracy falsely.

**Metrics:** WER per clip + corpus median. Report CER too (tokenization is ambiguous in Urdu).

**Target (set before running):** median WER ≤ 35%.

**Report:** model id, quantization, file size, audio duration, processing time, device, WER + CER, normalization rules, hallucination notes, sample transcript.

---

## 12. USER INTERFACE

### Screen 1 — Input
- URL field (`OutlinedTextField`). Focus via `FocusRequester` + `LaunchedEffect` + `LifecycleEventObserver` on `ON_RESUME`. **Do NOT focus in `onCreate` — silently fails.**
- Clipboard read: also on `ON_RESUME`, not `onCreate` (Android 10+ restriction).
- If clipboard contains `tiktok.com`/`vm.tiktok.com`/`vt.tiktok.com` → dialog "کلپ بورڈ سے لنک پیسٹ کریں؟"
- Language dropdown (`ExposedDropdownMenuBox`).
- Transcribe button (enabled only when URL valid).
- Progress: `LinearProgressIndicator` + stage text.
- Cancel button during work.
- Plain-language error area.

Messages:
```
"لنک چیک ہو رہا ہے..." / "Checking link..."
"ویڈیو ڈاؤن لوڈ ہو رہی ہے..." / "Downloading video..."
"آواز نکالی جا رہی ہے..." / "Extracting audio..."
"ٹرانسکرپٹ بنایا جا رہا ہے..." / "Transcribing..."
"مکمل!" / "Done!"
```

### Screen 2 — Transcript
- Top bar: back arrow, title, settings icon.
- **Long-press settings icon → hidden debug screen.** Single tap → nothing (MVP).
- Selectable text; RTL for Urdu; correct BiDi for mixed lines.
- **Font decision:** Nastaliq (bundled `NotoNastaliqUrdu-Regular.ttf`, ~500 KB) vs system Naskh. Document choice in DECISIONS.md.
- Copy → `ClipboardManager` + toast "کاپی ہو گیا!"
- Save → **SAF `ACTION_CREATE_DOCUMENT`** with explicit MIME types:
  - `.txt` → `text/plain`
  - `.md` → `text/markdown` (fallback `text/plain`)
  - `.json` → `application/json`
  - Do NOT use `MediaStore.Downloads` on minSdk 26.
- Share → `Intent.ACTION_SEND` via `FileProvider` (see manifest in §14).

### Debug screen
- Long-press settings → shows raw log (yt-dlp stderr, ffmpeg stderr, whisper output).
- Redact URLs, cookies, full transcripts by default.
- Never upload logs.

---

## 13. ERROR HANDLING

| Internal | Urdu message |
|---|---|
| Private/deleted video | "یہ ویڈیو پرائیویٹ ہے یا ڈیلیٹ ہو چکی ہے۔" |
| No internet | "انٹرنیٹ کنیکشن ٹھیک نہیں ہے۔" |
| No speech (hallucination filtered) | "اس ویڈیو میں بولنے والی آواز نہیں ملی۔" |
| Low storage | "فون میں جگہ کم ہے۔ کم از کم 1 GB خالی کریں۔" |
| TikTok extractor broken | "TikTok نے اپنا سسٹم تبدیل کیا ہے۔ ایپ اپ ڈیٹ کی ضرورت ہے۔" |
| Whisper OOM | "فون میں کافی RAM نہیں ہے۔ چھوٹی ویڈیو آزمائیں۔" |
| Photo/slideshow post | "یہ پوسٹ ویڈیو نہیں، تصاویر پر مشتمل ہے۔" |
| Video > 5 minutes | "ویڈیو بہت لمبی ہے۔ 5 منٹ سے کم دورانیے کی ویڈیو آزمائیں۔" |

### Duration enforcement point

**Before full download** (avoid wasting bandwidth): run
```bash
yt-dlp --skip-download --print duration <url>
```
If duration > 300 s → refuse with the error message.

Also handle: regional blocks, IP blocks, login-required videos, music-only, silence-only, simultaneous transcriptions (block in UI), rotation during processing, process death, airplane mode mid-download.

Never show: stack traces, class names, shell commands, native dumps.

---

## 14. BUILD CONFIGURATION

### Manifest
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROCESSING" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application ...>
    <service
        android:name=".TranscriptionService"
        android:foregroundServiceType="mediaProcessing|dataSync"
        android:exported="false" />

    <provider
        android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.fileprovider"
        android:exported="false"
        android:grantUriPermissions="true">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_paths" />
    </provider>
</application>
```

`POST_NOTIFICATIONS`: request at runtime only on API 33+. On API 26–32, no runtime request needed.

`res/xml/file_paths.xml`: define paths for exports/transcripts only.

### ABI splits
- Release: `arm64-v8a`
- Debug: `arm64-v8a`, `x86_64`

**Known limitation:** some 64-bit chips run 32-bit Android Go — cannot install this APK. Document in README.

### ProGuard/R8
```proguard
-keep class com.tiktoktranscript.whisper.** { *; }
-keepclassmembers class * { native <methods>; }
# youtubedl-android (verify actual package name in Phase B):
-keep class com.yausername.** { *; }
-keep class org.json.** { *; }
# Only add -dontwarn after confirming a real warning — do not preemptively add
```

**Release smoke test mandatory:** R8 stripping is the most common "works in debug, crashes in release" cause.

### Signing
```kotlin
signingConfigs {
    create("release") {
        val path = System.getenv("KEYSTORE_PATH")
        if (path != null && file(path).exists()) {
            storeFile = file(path)
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
}
```
If secrets missing → build **debug** APK. An unsigned release APK is not installable.

### 16 KB pages
- Build all native libs with NDK 27+ and `-Wl,-z,max-page-size=16384`.
- Verify with `check_elf_alignment.sh` (AOSP `platform/development/tools/`), or `llvm-readelf --program-headers`, or Android Studio's APK Analyzer.
- **If a required `.so` (including third-party) is not 16 KB aligned:** rebuild it, find an aligned build, or document that the app will not run on 16 KB-page devices. **Downgrading `targetSdk` does NOT fix runtime loading.**

### APK output naming
```kotlin
androidComponents {
    onVariants { variant ->
        variant.outputs.forEach { output ->
            output.outputFileName.set("tiktok-transcript-${variant.name}.apk")
        }
    }
}
```

### `.gitignore` (mandatory deliverable)
```
build/
.gradle/
local.properties
*.keystore
*.jks
*.apk
*.aab
.idea/
captures/
.externalNativeBuild/
.cxx/
release.keystore
SHA256SUMS.txt
```

---

## 15. TESTING

### Unit tests (JVM)
1. URL parsing & validation (long + short forms)
2. Language code mapping
3. Filename sanitization (special chars, Unicode, path traversal)
4. UTF-8 round-trip including partial multi-byte
5. Urdu/mixed text handling
6. TXT/MD/JSON formatting
7. JSON round-trip
8. Progress calculations
9. Partial-download recovery
10. Model checksum verification
11. Retry rules (transient vs permanent)
12. Cancellation propagation
13. Temp-file cleanup
14. Hallucination filter (mocked whisper output)

### Instrumented tests (Android)
1. Compose UI: focus timing, dropdown, button state
2. Clipboard read after `ON_RESUME`
3. RTL rendering + BiDi mixed lines
4. Foreground service start/stop, `onTimeout()` on API 34+
5. `FileProvider` URI resolution

**CI runs unit tests only.** Instrumented tests run locally (`./gradlew connectedAndroidTest`). **Document this gap in `docs/TESTING.md`** — do not claim they run in CI.

### Integration tests
- Audio extraction on 3 fixtures. Generate them at build time:
  ```bash
  ffmpeg -f lavfi -i sine=frequency=440:duration=2 -ar 16000 -ac 1 test.wav
  ffmpeg -f lavfi -i testsrc=duration=2 -f lavfi -i sine=duration=2 \
    -c:v libx264 -c:a aac test.mp4
  ```
- Real transcription on 1 short WAV.
- Valid + invalid + missing model.
- Empty / corrupt audio.
- Export from real pipeline output.

**CI uses recorded yt-dlp JSON fixtures — never live TikTok URLs.**

### Manual E2E checklist (user-run)
Provide categories: normal, short URL, private/deleted, network drop, low storage, photo slideshow, music-only, long video.

### Release smoke test (mandatory)
Install signed release APK on emulator/device. Launch both screens. Transcribe a local file fixture. Catches R8 regressions.

### Regression rule
Reproduce bug with failing test → fix root cause → rerun → rerun related → run full suite. Never delete/weaken tests to go green.

---

## 16. GITHUB ACTIONS

```yaml
name: Build & Test
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Cache Gradle + NDK
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
            /usr/local/lib/android/sdk/ndk
          key: ${{ runner.os }}-gradle-ndk-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties', 'gradle/libs.versions.toml') }}

      - uses: android-actions/setup-android@v3

      - name: Install NDK
        run: |
          sdkmanager --install "ndk;27.0.12077973"
          echo "ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/27.0.12077973" >> $GITHUB_ENV

      - name: Install CMake
        run: sdkmanager --install "cmake;3.22.1"

      - name: Generate Gradle wrapper if missing
        run: |
          if [ ! -f gradlew ]; then gradle wrapper --gradle-version 8.9; fi
          chmod +x gradlew

      - name: Run unit tests
        run: ./gradlew testDebugUnitTest

      - name: Decode signing keystore
        if: ${{ secrets.KEYSTORE_BASE64 != '' }}
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > release.keystore

      - name: Build release APK
        if: ${{ secrets.KEYSTORE_BASE64 != '' }}
        env:
          KEYSTORE_PATH: release.keystore
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: ./gradlew assembleRelease

      - name: Build debug APK (fallback)
        if: ${{ secrets.KEYSTORE_BASE64 == '' }}
        run: ./gradlew assembleDebug

      - name: Compute SHA-256
        if: always()
        run: sha256sum app/build/outputs/apk/**/*.apk > SHA256SUMS.txt || true

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: apk-and-checksums
          path: |
            app/build/outputs/apk/**/*.apk
            SHA256SUMS.txt
```

Rules:
- Never use `continue-on-error` to hide test failures.
- NDK must be explicitly installed (`setup-android` only installs SDK).
- Artifacts require authentication. For public links, use a GitHub Release step on tag push.
- Document instrumented-test gap in `docs/TESTING.md`.

---

## 17. SELF-AUDIT CHECKLIST (CRITICAL — THIS PROMPT HAS KNOWN LIMITATIONS)

Before writing production code, verify and document each item in `docs/DECISIONS.md`:

1. Actual Maven coordinates resolved for youtubedl-android; actual internal package name.
2. License of youtubedl-android (read the `LICENSE` file inside the AAR).
3. Bundled Python version; whether runtime yt-dlp update is feasible.
4. Exact NDK version available in the environment.
5. ARM CPU feature detection approach (baseline vs +dotprod).
6. `foregroundServiceType` availability across API 26–35.
7. Exact model file size and SHA-256 (downloaded and measured).
8. WER on 3+ Urdu clips (Phase 0a).
9. Whisper hallucination behavior on silence/music-only audio.
10. Whether `assembleRelease` produces signed or unsigned APK in current setup.
11. Whether instrumented tests can run in current environment.
12. Which Maven coordinates for audio processing are actually chosen (bundled ffmpeg / MediaCodec / maintained fork).
13. `.gitignore` contents.

Each item: **Verified** (with evidence) or **Blocked** (with exact reason). Never "Assumed" or "Guessed".

**If you find contradictions or ambiguities in this prompt itself, STOP and report them before proceeding.**

---

## 18. DELIVERABLES

- Complete Android Studio / Gradle project
- Kotlin + Compose source
- Native C/C++ source + CMake configuration
- Gradle version catalog (`gradle/libs.versions.toml`)
- Working model manager
- Downloader integration OR evidenced blocker
- Working local transcription integration
- Functional transcript display + exports
- Unit tests + instrumented tests + release smoke test
- GitHub Actions workflow
- **`.gitignore`** (§14)
- **`LICENSE`** file (GPL-3.0 text if applicable, else chosen license)
- **`docs/PHASE_0_RESULTS.md`** (Phase 0a/0b measurements)
- `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/TESTING.md`, `docs/PRIVACY.md`, `docs/DEPENDENCIES_AND_LICENSES.md`, `docs/RELEASE_REPORT.md`
- `README.md`
- APK(s): ARM64 debug and/or signed release; x86_64 if built
- `artifacts/SHA256SUMS.txt`
- Final report (§20)

**Artifact layout (only for artifacts actually produced):**
```
artifacts/arm64-v8a/tiktok-transcript-arm64.apk
artifacts/x86_64/tiktok-transcript-x86_64.apk
artifacts/SHA256SUMS.txt
```

Do NOT generate placeholder APKs.

---

## 19. EXECUTION PHASES

- **Phase 0a** — Local audio proof (must complete)
- **Phase 0b** — TikTok acquisition proof (best-effort)
- **Phase 0c** — Go/No-Go decision
- **Phase A** — Inspect environment
- **Phase B** — Verify dependencies (fills §17 checklist)
- **Phase C** — Prove Android pipeline
- **Phase D** — Implement app
- **Phase E** — Test & debug
- **Phase F** — Harden
- **Phase G** — Release
- **Phase H** — Final audit (§17 against reality)

If Phase 0c says STOP → deliver Phase 0 results and recommendation only.

---

## 20. FINAL REPORT FORMAT (Simple Urdu)

### A. کیا بنایا گیا؟
### B. APK ڈاؤن لوڈ
### C. اصل ٹیسٹ کے نتائج (PASS/FAIL/BLOCKED/NOT RUN)
### D. حقیقی فون پر ٹیسٹنگ
### E. اردو transcription quality (WER/CER)
### F. SHA-256
### G. باقی مسائل
### H. GitHub Actions
### I. Installation instructions
### J. Final acceptance matrix

---

## 21. DEFINITION OF DONE (THREE TIERS)

### Tier 0 — Desktop proof
- Phase 0a complete with measured WER.
- If WER > 35%: task STOPPED with recommendation.
- Phase 0b attempted; documented if BLOCKED.

### Tier 1 — Agent Responsibility
- §17 self-audit complete (all items Verified or Blocked).
- Project builds with pinned toolchain.
- Unit tests pass.
- Release smoke test passes.
- APK(s) generated with correct ABI.
- SHA-256 checksums computed.
- Docs, `.gitignore`, `LICENSE` written.
- GitHub Actions workflow created and validated where possible.

### Tier 2 — User Verification
- Install on physical ARM64 device.
- Process a real TikTok URL end-to-end.
- Confirm Urdu quality acceptable.
- Confirm Copy/Save/Share.

If Tier 1 done but Tier 2 cannot be verified: state explicitly and provide manual checklist.

---

## 22. PLACEHOLDERS TO DOCUMENT IN `docs/DECISIONS.md`

- `applicationId`: `com.tiktoktranscript.app`
- `package` (Kotlin namespace): `com.tiktoktranscript`
- JNI symbol prefix: `Java_com_tiktoktranscript_whisper_WhisperBridge_*`
- App name: `TikTok Transcript`
- Signing: debug key by default; release via CI secrets
- GitHub repo URL: user-provided
- Model download host: Hugging Face (pinned commit)
- License: TBD by §17 item 2

---

## 23. KNOWN LIMITATIONS (ACKNOWLEDGE IN README)

1. TikTok extractor breaks periodically; runtime update may be infeasible depending on bundled Python.
2. Whisper Urdu accuracy unknown until Phase 0. No percentage published without benchmark.
3. Hallucination on silence/music is a known Whisper behavior — mitigated, not eliminated.
4. Model download requires internet once. Transcription is offline after.
5. Video download requires internet every time.
6. Max video duration 5 minutes (enforced before full download).
7. GPL-3.0 virality if distributed.
8. `arm64-v8a`-only APK will not install on 32-bit Android devices.
9. 16 KB page compatibility depends on every bundled `.so`.
10. TikTok ToS — personal/educational use only.
11. Instrumented tests do NOT run in CI (no emulator) — must run locally.
12. This prompt has known ambiguities; §17 exists to surface them.

---

**Start with Phase 0a. Complete the §17 checklist before writing production Android code. Never sacrifice correctness or honesty to report completion.**