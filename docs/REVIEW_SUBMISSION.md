# Rokid AIUI Studio Review & Submission Kit (`构建与提审`)

This document provides the exact metadata, permission purpose strings, network/data disclosures, package paths, and pre-submission verification checklist for our AIUI 0.18 agents in Rokid AIUI Studio (`构建与提审`).

- **Current Demo 2 Source of Truth**: **GCP Live Translator (`48c2e202270c469886dde77ef1ecc936`, package `v1.0.10` / Studio `reviewNativeVersion: 1.0.2`)** matches `demos/02-rokid-gcp-multimodal-agent/app.json`.
- **Historical Demo 2 Snapshot**: **GCP Multimodal Agent (`68e11a45486e4b279704e1e3c43b4b4b`, Studio `reviewNativeVersion: 1.0.8`)** corresponds to git commit `099e5fb` and remains in `checking` status.

---

## Studio Submission Status (`线上提审状态`, 2026-10-21)

| Agent Name (`agentName`) | Source Directory / Snapshot | Studio `agentId` | Studio `reviewNativeVersion` | Package `version` | `displayStatus` |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **Vision Voice Copilot** | `demos/01-rokid-vision-voice-copilot` | `059b26f3ffcd47ab8280a2d176b0f88a` | `1.0.9` | `1.0.8` | `checking` |
| **GCP Multimodal Agent** | `demos/02-rokid-gcp-multimodal-agent` (source = git `099e5fb`) | `68e11a45486e4b279704e1e3c43b4b4b` | `1.0.8` | `1.0.8` | `checking` |
| **GCP Live Translator** *(Source of Truth)* | `demos/02-rokid-gcp-multimodal-agent` (HEAD) | `48c2e202270c469886dde77ef1ecc936` | `1.0.2` | `1.0.10` | `checking` |

> **Note on `nativeVersion` Auto-Increment**: The Rokid AIUI Studio backend (`metis/agent/updateThirdAgent`) automatically increments `nativeVersion` by `+0.0.1` on every save call (new agents created via `saveAIUIAgent` / `--create` start at `1.0.0`). Call `updateThirdAgent` only once per release before calling `cozePublish`.

---

## Agent 1: Vision Voice Copilot (`01-rokid-vision-voice-copilot`)

### 1. Basic Metadata (`基础信息`)

| Studio Form Field (`构建与提审字段`) | Value (Exact Match with `app.json`) | Notes / Constraints |
| :--- | :--- | :--- |
| **Agent Name (`智能体名称` / `agentName`)** | `Vision Voice Copilot` | 20 chars (`<= 20` chars; no `test`/`beta`) |
| **Studio Agent ID (`agentId`)** | `059b26f3ffcd47ab8280a2d176b0f88a` | Submitted 2026-10-21 (`displayStatus: "checking"`) |
| **Category (`分类` / `category`)** | `work` (`工作` / `Efficiency & Tools`) | Hands-free voice & vision assistant |
| **Version (`版本号` / `reviewNativeVersion`)** | `1.0.9` | Server auto-increments `nativeVersion` by `+0.0.1` on each `updateThirdAgent` save |
| **Engine Requirement (`引擎版本` / `engine`)** | `>=0.18.0` | Packaged with `@yodaos-pkg/aix-cli@0.10.1` |
| **Icon (`应用图标` / `agentLogo`)** | `demos/01-rokid-vision-voice-copilot/assets/icon.png` | 512×512 PNG bundled at `assets/icon.png` |
| **Packaged `.aix` (`安装包路径`)** | `demos/01-rokid-vision-voice-copilot/dist/rokid-glasses-copilot.aix` | Optimized `.aix` archive |

- **Description (`智能体简介` / `agentDesc`, 250 chars, `<= 500` chars, truthful, no absolute claims)**:
  > Hands-free AI copilot for Rokid Glasses monochrome-green HUD. Voice Q&A uses the Rokid on-device assistant LLM (Metis), temple-tap scene analysis sends a camera photo to a Google Cloud (Vertex AI Gemini) proxy, and the dashboard shows IMU telemetry.

- **Opening Greeting (`开场白` / `agentPrompt`, 122 chars, `<= 300` chars, distinct from description)**:
  > Hello! I am your Vision & Voice Copilot. Tap the temple or speak a wake word to ask a question or analyze the scene ahead.

### 2. Permissions & Purpose Strings (`权限声明与用途说明`)

| Permission (`权限名`) | Purpose String (`权限用途说明`) | Code Call Site |
| :--- | :--- | :--- |
| `CAMERA` | Used when the user taps the temple in `VISION` mode to capture a single scene photo (`wx.media.createCameraContext().takePhoto`) for multimodal object and scene recognition. | `pages/index/index.ink` (`captureAndAnalyze`) |
| `RECORD_AUDIO` | Used when the user triggers voice interaction in `CHAT` mode to transcribe spoken queries (`new SpeechRecognition()`) for hands-free Q&A. | `pages/index/index.ink` (`startVoiceTurn`) |

*(Note: IMU pitch/roll in `DASHBOARD` mode reads `Gyroscope` at 5 Hz, which does not require a manifest permission entry in AIUI 0.18.)*

### 3. Network & Data Disclosure (`网络与数据说明`)

- **Endpoints**:
  - **Voice Q&A (`CHAT` mode)**: Rokid AIUI host runtime `LanguageModel` service (Rokid Metis LLM endpoint).
  - **Scene Analysis (`VISION` mode)**: Google Cloud Run authenticated relay proxy at `https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app` (`/api/auth/verify` and `/api/gemini`, backed by Vertex AI `gemini-4-argon` on `locations/global`).
- **Data Sent**:
  - **Voice Q&A (`CHAT` mode)**: System prompt + user's transcribed voice query (`session.promptStreaming(query)`) sent to Rokid Metis (`LanguageModel`).
  - **Vision Analysis (`VISION` mode)**: Base64-encoded camera photo (`image/webp` from `takePhoto({ quality: 'low' })`, captured only when the user taps the temple) + short English scene description prompt (`POST /api/gemini` with 25s timeout) sent to the Google Cloud Run Vertex AI proxy (`https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app/api/gemini`).
- **Fallback Behavior**: If the host LLM, ASR, camera, or cloud vision proxy is unavailable, the agent gracefully falls back to deterministic local responses labeled `[OFFLINE SAMPLE]` and clears all busy states so the HUD remains responsive.

### 4. Preview & Review Assets (`预览与提审素材`)

- **Video (`演示视频`, 15–45s MP4, `<= 50 MB`)**: `demos/01-rokid-vision-voice-copilot/assets/review/demo.mp4`
- **Cover Image (`封面图`, 1080×1080 PNG)**: `demos/01-rokid-vision-voice-copilot/assets/review/cover.png`
- **Screenshots (`预览截图`, 480×352 PNG, `>= 1` image)**:
  - `demos/01-rokid-vision-voice-copilot/assets/review/shot1.png` (`CHAT` mode standby HUD)
  - `demos/01-rokid-vision-voice-copilot/assets/review/shot2.png` (`CHAT` mode voice Q&A response)
  - `demos/01-rokid-vision-voice-copilot/assets/review/shot3.png` (`VISION` mode scene recognition)

---

## Agent 2 (Current Source of Truth): GCP Live Translator (`02-rokid-gcp-multimodal-agent`, v1.0.10)

### 1. Basic Metadata (`基础信息`)

| Studio Form Field (`构建与提审字段`) | Value (Exact Match with `app.json`) | Notes / Constraints |
| :--- | :--- | :--- |
| **Studio Agent ID (`agentId`)** | `48c2e202270c469886dde77ef1ecc936` | Created via `saveAIUIAgent` (`--create`), submitted `2026-10-21` (`displayStatus: "checking"`) |
| **Agent Name (`智能体名称` / `agentName`)** | `GCP Live Translator` | 19 chars (`<= 20` chars; no `test`/`beta`) |
| **Category (`分类` / `category`)** | `work` (`工作`) | Real-time speech-to-speech translation & vision |
| **Version (`版本号` / `nativeVersion`)** | `1.0.10` (Studio `reviewNativeVersion`: `1.0.2`) | New Studio agents start at `1.0.0` and increment `+0.0.1` per save |
| **Engine Requirement (`引擎版本` / `engine`)** | `>=0.18.0` | Packaged with `@yodaos-pkg/aix-cli@0.10.1` |
| **Icon (`应用图标` / `agentLogo`)** | `demos/02-rokid-gcp-multimodal-agent/assets/icon.png` | 512×512 PNG bundled at `assets/icon.png` |
| **Packaged `.aix` (`安装包路径`)** | `demos/02-rokid-gcp-multimodal-agent/dist/rokid-gcp-multimodal-agent.aix` | Optimized `.aix` archive |

- **Description (`智能体简介` / `agentDesc`, 318 chars, `<= 500` chars, truthful, no absolute claims)**:
  > Real-time speech-to-speech translator into English for Rokid Glasses monochrome-green HUD. Powered by Gemini Live on Google Cloud, it auto-detects source languages, translates all nearby speech into spoken English with on-HUD bilingual transcripts, and includes Gemini 4 camera vision Q&A plus a cloud status console.

- **Opening Greeting (`开场白` / `agentPrompt`, 185 chars, `<= 300` chars, distinct from description)**:
  > Hello! I am GCP Live Translator. Start Live Translate to stream nearby speech for real-time spoken English and HUD transcripts, or tap the temple in Vision mode to analyze a scene.

### 2. Permissions & Purpose Strings (`权限声明与用途说明`)

| Permission (`权限名`) | Purpose String (`权限用途说明`) | Code Call Site |
| :--- | :--- | :--- |
| `CAMERA` | Captures a single scene photo (`wx.media.createCameraContext().takePhoto`) only when the user taps the temple in `VISION` mode for Gemini 4 visual Q&A. | `pages/index/index.ink` (`triggerGeminiVisionCapture`) |
| `RECORD_AUDIO` | Streams nearby speech to Google Cloud Gemini Live for real-time speech-to-speech translation into spoken English and on-HUD bilingual transcripts. | `pages/index/index.ink` (`startLiveTranslation`) |

### 3. Network & Data Disclosure (`网络与数据说明`)

- **Cloud Run Relay Endpoint**: `https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app` (active revision `rokid-aiui-gcp-proxy-00006-vin` at 100% traffic; revisions `00001`–`00003` retained for rollback).
- **Data Sent & Privacy Boundaries**:
  - **Authentication (`POST /api/auth/verify`)**: Sends the Rokid account identifier and one-time verification code to obtain a short-lived HMAC-SHA256 Bearer session token (`expiresIn: 3600`).
  - **Live Speech-to-Speech Translation (`WSS /ws/live-translate?token=<Bearer>&target=en`)**:
    - When the user taps the temple in `LIVE TRANSLATE` mode, the glasses microphone (`navigator.mediaDevices.getUserMedia` with `microphoneMode: 'far-field'`, 16 kHz mono PCM extracted from `MediaRecorder` `audio/wav` chunks) streams nearby speech over an authenticated WebSocket to the Cloud Run relay, which forwards it to **Google Cloud Vertex AI Gemini Live (`gemini-3.5-live-translate-preview`, `locations/global`)**.
    - The server streams back **24 kHz PCM** translated English speech audio (played via `AudioContext.createBuffer(1, n, 24000)`) and live bilingual transcripts (`input_transcript` with detected language code + `output_transcript` in English).
    - **Capture & Session Cap**: `far-field` beamforming focuses on the speaker in front (falls back to `omnidirectional`); the uplink always carries real mic audio and English echo is not re-translated (`echoTargetLanguage=false`). Tap starts/stops the session; sessions auto-stop at **4:50 (`290s`)** and tear down immediately on mode switch, `onHide`, `onUnload`, or Back key.
    - **No Sample Fallback**: Sample-sentence and text-translation fallback paths are removed; if the network or upstream fails, the HUD shows `LIVE TRANSLATION UNAVAILABLE · <reason>`.
  - **Camera Vision Q&A (`POST /api/gemini`)**:
    - Captures a single camera photo (`takePhoto` timeout **12s**) **only when the user taps the temple** in `GEMINI 4 LIVE` mode and forwards the Base64 image + concise English prompt to **Vertex AI Global `gemini-4-argon`**.
    - **No Photo = No Model Call**: If no photo is available or capture times out, the HUD displays `"Camera unavailable · tap to retry"` (`NO CAM`) and never asks the model to invent a scene.
  - **Health Check (`GET /health`)**: Read-only status probe in `CLOUD CONSOLE` mode.
- **API Key / Secret Audit (`gcp_config.js`)**:
  - Verified `demos/02-rokid-gcp-multimodal-agent/gcp_config.js` contains **no** client-side GCP API keys or placeholders. All Google Cloud credentials remain on the Cloud Run server via Application Default Credentials (ADC).

### 4. Preview & Review Assets (`预览与提审素材`)

- **Video (`演示视频`, 15–45s MP4, `<= 50 MB`)**: `demos/02-rokid-gcp-multimodal-agent/assets/review/demo.mp4`
- **Cover Image (`封面图`, 1080×1080 PNG)**: `demos/02-rokid-gcp-multimodal-agent/assets/review/cover.png`
- **Screenshots (`预览截图`, 480×352 PNG, `>= 1` image)**:
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot1.png` (`GEMINI 4 LIVE` vision mode)
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot2.png` (`LIVE TRANSLATE` speech-to-speech mode)
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot3.png` (`CLOUD CONSOLE` telemetry mode)

---

## Agent 3 (Historical Snapshot @ `git 099e5fb`): GCP Multimodal Agent (`68e11a45486e4b279704e1e3c43b4b4b`, v1.0.8)

> Retained for reference: this earlier submission of `demos/02-rokid-gcp-multimodal-agent` (built from commit `099e5fb`) is currently in `checking` status on Rokid AIUI Studio under `agentId = 68e11a45486e4b279704e1e3c43b4b4b` (`reviewNativeVersion = 1.0.8`).

### 1. Basic Metadata (`基础信息`)

| Studio Form Field (`构建与提审字段`) | Value (Snapshot @ `git 099e5fb`) | Notes / Constraints |
| :--- | :--- | :--- |
| **Agent Name (`智能体名称` / `agentName`)** | `GCP Multimodal Agent` | 20 chars (`<= 20` chars; no `test`/`beta`) |
| **Studio Agent ID (`agentId`)** | `68e11a45486e4b279704e1e3c43b4b4b` | Submitted 2026-10-21 (`displayStatus: "checking"`, `reviewNativeVersion: "1.0.8"`) |
| **Category (`分类` / `category`)** | `work` (`工作`) | Cloud vision Q&A & subtitle translation |
| **Version (`版本号` / `reviewNativeVersion`)** | `1.0.8` | Source = git commit `099e5fb` |
| **Engine Requirement (`引擎版本` / `engine`)** | `>=0.18.0` | Packaged with `@yodaos-pkg/aix-cli@0.10.1` |
| **Permissions (`权限名` / `permissions`)** | `["CAMERA"]` | Camera vision capture in `GEMINI` mode |

- **Description (`智能体简介` / `agentDesc`)**:
  > Google Cloud Vertex AI assistant for Rokid Glasses monochrome-green HUD, featuring camera vision Q&A, bilingual subtitle translation, and a cloud node status board.

- **Opening Greeting (`开场白` / `agentPrompt`)**:
  > Hello, I am the GCP Multimodal Agent. Tap the temple to capture a photo for Vertex AI vision analysis or swipe to switch between translation and cloud status modes.

---

## Pre-Submission Checklist (`提审前自检清单`)

- [x] **Naming & Copy Compliance**: All `agentName` values (`Vision Voice Copilot`, `GCP Live Translator`, `GCP Multimodal Agent`) are `<= 20` characters, contain no `test`/`beta` markers, and have distinct `agentDesc` (`<= 500` chars, no `100%`/`best` claims) and `agentPrompt` (`<= 300` chars).
- [x] **Engine & Packaging**: All `.aix` bundles are built with `@yodaos-pkg/aix-cli@0.10.1`, declare `"engine": ">=0.18.0"` and `"inkVersion": ">=0.18.0"`, and embed a 512×512 `assets/icon.png`.
- [x] **Least-Privilege Permissions**: Both active agents (`Vision Voice Copilot` and `GCP Live Translator`) declare `["CAMERA", "RECORD_AUDIO"]`, and every declared permission maps to an active on-device code path with an explicit purpose string.
- [x] **Launch, Interaction & Back/Exit Rule (Review Rule 3.4)**: Agents launch cleanly into their 480×352 HUD, respond to temple tap (`Enter`/`GlobalHook`/`Space`) and swipe (`Arrow*`/`Page*`), release microphone/WebSocket resources on exit, and **never** call `event.preventDefault()` on `Backspace`, `Escape`, or `GoBack`.
- [x] **Truthful Vision & Translation Behavior**: `GCP Live Translator` never asks Gemini to describe a scene when `takePhoto` (12s timeout) returns no photo (`"Camera unavailable · tap to retry"`), and `LIVE TRANSLATE` streams real microphone audio to Gemini Live without sample-sentence fallbacks.
- [x] **TTS Non-Blocking Completion**: `speechSynthesis.speak` and `wx.speech.playTTS(text)` are guarded by a length-based timeout fallback (`clamp(1500 + 220ms * chars, 3000ms, 20000ms)`) so turns never hang when `utterance.onend` is unexposed on device.
- [x] **WXSS & 480×352 Monochrome-Green HUD**: No unsupported WXSS properties (`white-space`, `text-overflow`, `-webkit-line-clamp`, `word-break`, `visibility`, `font-variant`, `position: sticky`), `1px` borders, `font-weight <= 500`, and no English text overflow at 480×352.
- [x] **No Shipped Client Keys**: `gcp_config.js` contains zero API keys or placeholders and delegates all Google Cloud authentication to the Cloud Run relay proxy.
