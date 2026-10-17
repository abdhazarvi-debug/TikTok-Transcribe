# Privacy and Use Notes

These are planned requirements, not a completed privacy/security audit. Review the implementation before release.

- Keep audio/video, model data, and transcripts on-device except for network requests needed to retrieve a user-submitted public TikTok URL and the one-time model download.
- Do not upload logs, URLs, cookies, full transcripts, media, or model data to an application backend.
- Store models/cache in app-private storage; clean temporary media/audio after success, failure, or cancellation.
- Redact URLs, cookies, and full transcript text by default in any debug screen.
- Only support publicly accessible media. Do not bypass login restrictions, DRM, or other access controls.
- TikTok access and terms can change. Check current terms and law before use/distribution.
- If runtime yt-dlp updating is implemented, use official releases, verify the published hash, confirm the expected version output, keep rollback, and retain the bundled version on any failure. Otherwise, rely on APK updates.
- No logs should be uploaded by the app.
