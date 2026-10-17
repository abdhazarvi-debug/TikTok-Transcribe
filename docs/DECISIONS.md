# Decisions and Feasibility Audit

Each item must be **Verified** with evidence or **Blocked** with an exact reason. Never infer verification from documentation alone.

| # | Audit item | Current status | Evidence / next action |
|---:|---|---|---|
| 1 | youtubedl-android Maven coordinates and internal package | BLOCKED | Resolve through Gradle, inspect the AAR and package contents. |
| 2 | Downloader license | BLOCKED | Read the actual license file inside the resolved AAR before release. |
| 3 | Bundled Python version and yt-dlp update feasibility | BLOCKED | Inspect bundled runtime; skip runtime updates unless secure version/hash/rollback checks are implemented. |
| 4 | Exact Android NDK version | NOT RUN | Record the version installed by `sdkmanager`. |
| 5 | ARM CPU feature strategy | NOT DECIDED | Use a safe baseline or verified runtime dispatch; do not blindly require dot-product support. |
| 6 | Foreground service types across API 26–35 | NOT RUN | Compile and test API-specific behavior, including API 34+ and timeout behavior. |
| 7 | Model byte size and SHA-256 | NOT RUN | Download actual model files and measure size/hash. |
| 8 | Urdu WER on 3+ clips (master prompt asks 5+) | NOT RUN | Benchmark at least five reference clips, per-clip and median. |
| 9 | Silence/music hallucination behavior | NOT RUN | Run actual inference on silence and music-only fixtures. |
| 10 | Signed/unsigned release APK | NOT RUN | Inspect build configuration and smoke-test installable APK. |
| 11 | Instrumented tests in current environment | NOT RUN | Record whether emulator/device tests ran; CI does not claim these tests. |
| 12 | Chosen audio processing path | NOT DECIDED | Verify bundled FFmpeg first; otherwise test explicit 16 kHz resampling. |
| 13 | `.gitignore` | VERIFIED | Present in repository and includes Android build output and signing-secret exclusions. |
| 14 | Project license vs dependency licenses | BLOCKED | Repository currently has an MIT LICENSE; inspect all dependencies and reconcile notices/license before distribution. |

## Contradiction in the supplied prompt

The master prompt calls Phase 0a “NO network required” but directs the agent to clone `whisper.cpp`, download model weights, and acquire public Urdu clips. Those instructions cannot all be completed in a fully offline environment unless source, weights, clips, and references are staged beforehand.

**Resolution required before Phase 0a:** stage these inputs locally, or explicitly allow network access for acquisition. Do not silently reinterpret the prompt.

## Additional guardrails

- A desktop run of a newer yt-dlp does not prove the version bundled in the Android AAR works.
- Keep native ARM baseline and 16 KB page alignment unverified until every bundled shared library is inspected.
- Do not publish Urdu accuracy percentages without an actual benchmark.
- Do not choose or change the final app license by assumption. If a dependency is GPL-3.0, assess compatible distribution/source obligations and update licensing accordingly.
- The existing MIT file was in the repository's initial commit; its presence is not a third-party-license audit.
