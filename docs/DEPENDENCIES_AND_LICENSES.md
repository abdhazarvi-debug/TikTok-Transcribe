# Dependencies and Licenses — Verification Pending

No third-party Android artifact is verified yet. Candidate versions and licenses must be inspected in the actual build environment.

| Component | Requirement / candidate | Status |
|---|---|---|
| Kotlin / Jetpack Compose | Pin mutually compatible stable versions in `gradle/libs.versions.toml` | NOT SELECTED |
| Android Gradle Plugin / Gradle / JDK | Pin compatible trio and commit wrapper | NOT SELECTED |
| Android NDK / CMake | NDK 27+ and CMake 3.22.1 per supplied prompt | NOT VERIFIED |
| yt-dlp Android downloader | Candidate Maven coordinates in master prompt | NOT RESOLVED |
| Bundled FFmpeg / audio processing | Prefer bundled FFmpeg if verified; otherwise documented MediaCodec path | NOT SELECTED |
| whisper.cpp | Pin exact tag/commit, vendor or submodule; never use moving `main` | NOT FETCHED |
| Whisper models | Multilingual only; measure actual bytes and SHA-256 after download | NOT DOWNLOADED |
| Urdu font | Decide Nastaliq vs system font and verify redistribution rights | NOT SELECTED |

Before distribution, inspect dependency POM/AAR artifacts and their actual license files, and record exact coordinate/version, license identifier, source URL, notices, and any source-distribution obligations. The repository currently contains an MIT LICENSE; this does not establish that all dependency licenses are compatible. No release should be made until this is resolved.
