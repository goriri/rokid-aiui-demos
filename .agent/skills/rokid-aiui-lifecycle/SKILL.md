---
name: rokid-aiui-lifecycle
description: End-to-end lifecycle for Rokid Glasses AIUI agents — migrate to the current AIUI spec, pack .aix, deploy over ADB, test on device, record review videos with sound, wire Google Cloud (Cloud Run + Vertex Gemini), upload to Rokid AIUI Studio and submit for review. Use for any deploy/test/record/publish task on Rokid Glasses; use aiui-dev for writing AIUI code itself.
---

# Rokid AIUI Lifecycle (develop → deploy → test → record → publish)

Pair with `aiui-dev` (code/API/WXSS reference). This skill is the operations runbook. Every phase ends with a **content** check: a file existing, an exit code 0, or "LIVE" in a log does not prove the result is correct.

## Phase 0 — Environment
- `adb devices -l` → `model:RG_glasses`. Several devices → ask the user which one.
- Network: the glasses usually have Wi-Fi OFF and reach the internet through the **phone companion over Bluetooth**. Before testing anything that uses the network, check `adb shell dumpsys bluetooth_manager | grep ConnectionState` and grep logcat for `HCI_ERR_PAGE_TIMEOUT`. If the link is down, ask the user to reconnect the phone. Don't try to configure Wi-Fi.
- **Bluetooth & companion link troubleshooting**:
  - Bluetooth can be persisted OFF after a reboot (`enabled: false` in `dumpsys bluetooth_manager`) → re-enable with `adb shell svc bluetooth enable`.
  - A2DP `ConnectionState: STATE_CONNECTED` alone does **not** guarantee the Rokid companion data link is up: verify logcat shows `updateBluetoothApp -> connect:true` and active `cxr-service` messages (or `NetProxyEngine` traffic).
  - The glasses can also receive Wi-Fi credentials provisioned from the phone companion app (`adb shell dumpsys wifi | grep "mNetworkInfo"`).
- Toolchain per demo: `@yodaos-pkg/aix-cli@^0.10.1` (devDependency); run `npx aix` from inside the demo dir. Runtime check: `npx aix runtime current` (must satisfy `inkVersion`).
- Credentials (Rokid account, GCP) go only in a gitignored `.env`. Never echo them. If a user pastes one in chat, store it in `.env` and recommend changing it.

## Phase 1 — Spec compliance (AIUI 0.18 checklist)
Source of truth: `github.com/yodaos-project/AIUI` `documentation/8-changelog/latest.md` and `open-agent-format/app-json.md`; check npm `@yodaos-pkg/ink` / `aix-cli` versions.
- `app.json`: `inkVersion` + `engine` `">=0.18.0"`; `permissions` UPPERCASE and only what the code actually calls (`CAMERA`, `RECORD_AUDIO`, …); `agentName` ≤20 chars (no test/beta), `agentDesc` ≤500 (truthful, no "100%/best"), `agentPrompt` ≤300 (different from desc), `agentLogo`/`logo` → `assets/icon.png` (custom art, no text/QR, 512px); `version`.
- Keys: `onKeyDown/onKeyUp/onVoiceWakeup` are page methods, not template attributes. `preventDefault()` only for handled keys — **never** for Backspace/Escape/Back (review rule 3.4).
- TTS: `utterance.onend` may never fire. Always arm a length-based timeout (`clamp(1500+220·chars, 3s, 20s)`), use `speak(u,'immediate')`, and add turn-id ownership so an old timer can't clear a new turn. `wx.speech.playTTS(text)` takes a string.
- Busy flags are cleared on every error/timeout branch; re-entry guards on every trigger.
- WXSS: no `white-space`, `text-overflow`, `-webkit-line-clamp`, `position: sticky`, `top/left` offsets; 1px lines, weight ≤500, `overflow:hidden` on fixed-height text boxes.
- `.aixignore` must not exclude `assets/` as a whole (it drops the icon). Exclude `assets/{recordings,screenshots,review}` only.

## Phase 2 — Known platform traps
- **The built-in `LanguageModel` (Rokid Metis) drops images.** `image_url` parts are silently stripped (test: an 8×8 PNG → "NO_IMAGE"). Use it for text chat only; send vision to a cloud multimodal model (Phase 6).
- `CameraContext.takePhoto()` returns **`image/webp`**: build `data:${photo.mimeType};base64,…`. Use `quality:'low'|'normal'` to keep uploads small. Allow a **12s timeout** on device (camera capture can take >4s while `screenrecord` is active), and if no photo is returned, show `"Camera unavailable · tap to retry"` — never ask the model to describe a scene without a photo.
- **Microphone modes (`microphoneMode`)**: `'wearer'` (the default, and the **only** mode `wx.getRecorderManager` supports) uses beamforming that rejects other speakers by ~`-60 dB`. For translating nearby speakers, use `navigator.mediaDevices.getUserMedia({ audio: { sampleRate: 16000, channelCount: 1, microphoneMode: 'far-field', echoCancellation: false } })` + `new MediaRecorder(stream, { mimeType: 'audio/wav' })` (`mr.start(100)`), strip the 44-byte WAV header to get 16 kHz PCM16LE, apply `0.7` gain with clamping, and mute uplink (send zero-filled PCM frames) while playback runs to prevent speaker-to-mic echo.
- **Web Audio (`AudioContext`) sample rate**: `new AudioContext({ sampleRate: 24000 })` **throws** on the glasses runtime, but default `new AudioContext()` followed by `ctx.createBuffer(1, sampleCount, 24000)` works and resamples cleanly for gapless 24 kHz PCM playback.
- **WebSocket over the phone proxy**: `new WebSocket('wss://...')` with `ws.binaryType = 'arraybuffer'` works over the Bluetooth companion proxy (~670 ms RTT) as long as the companion data link is up.
- Network path glasses → BT → phone → internet adds seconds: timeouts 25s for vision, 10s for other calls; show an `ANALYZING…` state.
- Fallback/sample text must say so (`OFFLINE SAMPLE`/`OFFLINE DEMO`). Never word a fallback as a live result.

## Phase 3 — Build & ADB deploy
```bash
cd demos/<demo> && npx aix pack . -o dist/<name>.aix -O && npx aix show dist/<name>.aix   # check inkVersion, permissions, agentLogo, nativeVersion
npx aix device -s $S set-dev
npx aix install -s $S dist/<name>.aix
npx aix launch-page -s $S dist/<name>.aix pages/index/index
```
- Every pack generates a new dev `agentId`, and `aix` has no uninstall, so stale dev copies pile up (tell the user).
- Fallback without aix-cli: `content call --uri content://com.rokid.aiui.develop --method switch --arg dev` → push exactly 1 `.aix` + 1 definition json (`agentId` `develop.rokid.*`) to `/sdcard/aiui/package/.staging/adb/` → `--method apply` → `--method open --arg '{"agentId":…,"path":"pages/index/index","target":"_blank"}'`.

## Phase 4 — On-device test
- Input: tap `input keyevent 66`, swipe `20`/`19`, back `67` or `4`. Voice: `say -v Samantha -o q.aiff "<question>"` then `afplay q.aiff` right after the tap; tap again when it finishes so room chatter isn't transcribed.
- Logcat: `Ink` (`ink_script::console`), `AssistServer_Log` (`NetProxyEngine TX/RX`, `AICameraViewManager`), `CloudASRService`, `AIUI_*`. Exit check: `dumpsys activity activities | grep -i resumed` → launcher.
- **Truth gate:** for every AI result, record LIVE vs OFFLINE with the logcat line (RX `success=true` vs `Proxy unreachable` / `timeout`), and check that the answer matches the real scene or question.

## Phase 5 — Review video with sound
Device facts: physical display 480×640, HUD region `crop=480:352:0:180`; screen-off timeout 5s.
1. Keep the screen awake: `settings put system screen_off_timeout 600000; svc power stayon true` (note the original values).
2. Video: `screenrecord --display-id <physical id from dumpsys SurfaceFlinger --display-id>`. Without it, or once the display sleeps, frames are **black**.
3. Audio: `scrcpy --no-video --audio-source=output --display-id=0` (logical id) captures device TTS. It mutes the temple speaker while recording, which is harmless. The Mac mic can NOT hear the glasses.
4. Question audio: the same `q.aiff` played with `afplay`, mixed in at its play offset. `scripts/record_demo_av.sh` does steps 2–4 (`start` / `say` / `stop`). If scrcpy can't be used: `scripts/mux_audio.sh` dubs TTS on the Mac at logcat times.
   - **A/V alignment:** the scrcpy audio file starts earlier than `screenrecord` and has capture latency, so device TTS can land ~3–4.5s late in the mix. Measure the offset (device-audio onset in the `.opus` file minus the logcat `RUN_START`/`Speech speak request accepted` time relative to t0) and `atrim=start=<offset>` the device audio before mixing.
5. Gate with `scripts/check_video.sh`: H.264/AAC yuv420p 480×352, 15–45s, ≤50MB; YMAX>20 on ≥90% of 1fps samples; volumedetect mean > −35 dB on the question and each TTS slice; mpdecimate distinct frames; **look at the 3×3 contact sheet**; every AI result LIVE; clean English.
6. **Live-translation & physical recording hygiene**:
   - **Never touch the right temple** while positioning or holding the glasses during a take — the temple capacitive touchpad fires `KeyUp: Enter`, which stops an active live translation session or triggers a duplicate turn.
   - Prefer `microphoneMode: 'far-field'` for translation: it passes the frontal speaker (peaks 12k–23k) and cut room chatter from 16k–23k to 0–7.7k vs `'omnidirectional'` (which translates everything nearby). Never zero-fill the uplink during playback: it splits turns mid-sentence. Still record in a quiet spot, glasses ~15 cm from the speaker.
   - Wait for the full response to finish (final transcript punctuation + ≥3s with no `RX` audio/transcript chunks and playback drained) before triggering the next action or stopping.
7. Restore `screen_off_timeout` and `svc power stayon false`; leave the device on the launcher.
Deliverables per demo: `assets/review/{demo.mp4, cover.png (1080² padded), shot1..3.png}`.

## Phase 6 — Google Cloud (Cloud Run proxy → Vertex Gemini)
- The client never holds API keys: glasses → Cloud Run proxy (`/api/auth/verify` → bearer, `/api/gemini`, `/ws/live-translate`, `/api/translate`, `/api/tts`, `/health`).
- Latest models (Gemini 3.x / 4) are served only at Vertex **`locations/global`** (`us-central1` → 404): vision uses `gemini-4-argon`, and live speech-to-speech translation uses `gemini-3.5-live-translate-preview`. Probe candidates with a small image/audio clip, compare latency, then set the model in the proxy and redeploy. Keep earlier revisions for rollback (`gcloud run revisions list`, e.g. `00006-vin` serving 100% traffic while `00001`–`00003` are kept).
- **WebSocket live-translate relay pattern (`/ws/live-translate`)**: authenticate the bearer token on HTTP `upgrade`, open the upstream Vertex AI `BidiGenerateContent` WebSocket (`gemini-3.5-live-translate-preview`, `locations/global`) and wait for `setupComplete` before completing the client upgrade; relay binary 16 kHz PCM16 uplink → `realtimeInput.audio` and stream back binary 24 kHz PCM16 audio + JSON `input_transcript`/`output_transcript`/`turn_complete` (flushing 1.2s of silence on `audio_stream_end`).
- **Safe Cloud Run deploy workflow (`--no-traffic --tag`)**: when an existing agent version is under review, deploy proxy changes with `gcloud run deploy rokid-aiui-gcp-proxy --source ... --timeout 3600 --no-traffic --tag live`, verify against `https://live---...run.app`, and cut 100% traffic over (`gcloud run services update-traffic ... --to-revisions=<rev>=100`) only after host and device tests pass.
- Verify from the host: `scripts/test_gemini_image.mjs` (the answer must describe the image), `scripts/test_live_translate.mjs` (streams PCM16 speech and verifies 24 kHz audio + bilingual transcripts), and `npm run test:proxy` (all gates pass). Update HUD model labels and docs to match.

## Phase 7 — Rokid AIUI Studio upload & submit for review
Use `scripts/studio_upload.mjs` (repo root; `--dry-run` by default, `--execute` to write, `--create` to register a brand-new Studio agent). Flow:
1. Log in (`account-center.rokid.com/v2/login.do`, creds from `.env`) → `metis/agent/getAIUIAgentList` → map the existing drafts (update them, don't create duplicates), or pass `--create` when intentionally creating a new agent listing (calls `saveAIUIAgent` with `nativeVersion: "1.0.0"`, which allocates a new `agentId` starting at `1.0.0`).
2. OSS upload: `.aix` (`metis/<agentId>-<ts>.aix`), `cache.zip` (naming + MD5 rules in the deployment guide), icon, `previewMaterials` = 3–5 items, ≥1 video + ≥1 image, video first.
3. `metis/agent/updateThirdAgent` **once**. The server adds +0.0.1 to `nativeVersion` on every save call, so bump `app.json` version above the current Studio version and don't call save repeatedly.
4. Read back: `fileMd5`/`codeFileMd5` match local, permissions, 5 materials, `displayStatus: draft`.
5. Gate: `GET account-center.rokid.com/v3/accountsNoVoiceAuthed.do` must show `idcardCheckStatus === 1 || majorCheckStatus === 2`. If not, the user completes `https://account-web.rokid.com/verify?needLevel=2` (only they can).
6. Only with explicit user approval: `updateThirdAgent` → `POST rcs-internal.rokid.com/agentStore/developer/cozePublish` (`botId, name, description, prompt, logo, prologue, category, modelVendor:"native", versionLog, …`), one call per agent. Expect `code 0`, `check_not_pass:false`; read back `displayStatus: "checking"`.
7. Submission kit (listing text, permission purposes, data disclosures) lives in `docs/REVIEW_SUBMISSION.md`. Keep it consistent with `aix show`.

## Final report checklist
Studio IDs + review status, version under review, Cloud Run revision + rollback revisions, git commit pushed, device settings restored, stale dev copies noted, credential-rotation reminder.
