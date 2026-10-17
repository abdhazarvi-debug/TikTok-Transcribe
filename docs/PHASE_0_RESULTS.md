# Phase 0 Results — TikTok Transcript

**Status:** BLOCKED — required measurements have not been run.  
**GO_DECISION: NOT SET**

## Recorded preflight observations

These observations were recorded when the project seed was prepared. They describe that agent/container environment, not a phone benchmark.

| Check | Result | Evidence / meaning |
|---|---|---|
| Git | Available | `git --version` reported 2.47.3 |
| CMake | Available | `cmake --version` reported 3.31.6 |
| FFmpeg | Available | `ffmpeg -version` reported 7.1.5 |
| C++ compiler | Available | Debian compiler 14.2.0 |
| Java | Available | OpenJDK 21.0.12.1 |
| Android SDK / `sdkmanager` | NOT FOUND | No `sdkmanager` on PATH in that environment |
| Gradle | NOT FOUND | No `gradle` on PATH in that environment |
| GitHub DNS/network | BLOCKED | `curl` reported it could not resolve `github.com` |
| Pinned whisper.cpp source | NOT FETCHED | Network restriction |
| Candidate Whisper models | NOT DOWNLOADED | No measured bytes or SHA-256 |
| Five reference Urdu clips | NOT ACQUIRED | No licensed dataset/reference transcripts staged |
| Transcription / WER / CER | NOT RUN | No model inference or reference set |
| TikTok acquisition tests | NOT RUN | No real network test |
| Android build / APK | NOT RUN | Feasibility gate not passed |

## Required measurements — not fabricated

| Model | Pinned source | Bytes | SHA-256 | Clips | Median WER | CER | Status |
|---|---|---:|---|---:|---:|---:|---|
| Candidate 1 | NOT SELECTED | NOT RUN | NOT RUN | 0 | NOT RUN | NOT RUN | BLOCKED |
| Candidate 2 | NOT SELECTED | NOT RUN | NOT RUN | 0 | NOT RUN | NOT RUN | BLOCKED |

No sample transcript is reported because model inference was not executed.

## Go / No-Go decision

**Decision: BLOCKED, not GO and not measured FAIL.** No WER-based decision can be made until model inference is run against at least five Urdu reference clips. Do not write production Android code until the required evidence exists and the prompt's Phase 0a network contradiction is resolved.

## Completing Phase 0a

1. Pin a `whisper.cpp` tag/commit and record it.
2. Download at least two candidate multilingual models; record measured byte size and SHA-256.
3. Obtain at least five license-clear Urdu clips with reliable reference transcripts.
4. Convert to 16 kHz mono PCM signed-16-bit WAV.
5. Run `whisper-cli -m MODEL -f CLIP.wav -l ur`.
6. Apply the master prompt's normalization rules; preserve ZWNJ/ZWJ.
7. Report per-clip WER and CER, corpus median, runtime, model identity, hashes, and hallucination observations for silence/music.
8. Set `GO_DECISION: GO` only if actual median WER is ≤ 35%. If median WER exceeds 35%, stop and report the recommendation instead of proceeding to production Android code.
