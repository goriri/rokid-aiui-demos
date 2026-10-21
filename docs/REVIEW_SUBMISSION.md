# Rokid AIUI Studio Review & Submission Kit (`构建与提审`)

This document provides the exact metadata, permission purpose strings, network/data disclosures, package paths, and pre-submission verification checklist required to submit both AIUI 0.18 agents in Rokid AIUI Studio (`构建与提审`). All field values match the packaged `app.json` definitions.

---

## Agent 1: Vision Voice Copilot (`01-rokid-vision-voice-copilot`)

### 1. Basic Metadata (`基础信息`)

| Studio Form Field (`构建与提审字段`) | Value (Exact Match with `app.json`) | Notes / Constraints |
| :--- | :--- | :--- |
| **Agent Name (`智能体名称` / `agentName`)** | `Vision Voice Copilot` | 20 chars (`<= 20` chars; no `test`/`beta`) |
| **Studio Agent ID (`agentId`)** | `059b26f3ffcd47ab8280a2d176b0f88a` | Submitted 2026-10-21 (`displayStatus: "checking"`) |
| **Category Suggestion (`分类建议`)** | `Efficiency & Tools` (`效率工具` / `AI 助手`) | Hands-free voice & vision assistant |
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
  - **Scene Analysis (`VISION` mode)**: Google Cloud Run authenticated relay proxy at `https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app` (`/api/auth/verify` and `/api/gemini`, backed by Vertex AI `gemini-4-argon`).
- **Data Sent**:
  - **Voice Q&A (`CHAT` mode)**: System prompt + user's transcribed voice query (`session.promptStreaming(query)`) sent to Rokid Metis (`LanguageModel`).
  - **Vision Analysis (`VISION` mode)**: Base64-encoded camera photo (`image/webp` from `takePhoto({ quality: 'low' })`) + short English scene description prompt (`POST /api/gemini` with 25s timeout) sent to the Google Cloud Run Vertex AI proxy (`https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app/api/gemini`).
- **Fallback Behavior**: If the host LLM, ASR, camera, or cloud vision proxy is unavailable, the agent gracefully falls back to deterministic local responses labeled `[OFFLINE SAMPLE]` and clears all busy states so the HUD remains responsive.

### 4. Preview & Review Assets (`预览与提审素材`)

- **Video (`演示视频`, 15–45s MP4, `<= 50 MB`)**: `demos/01-rokid-vision-voice-copilot/assets/review/demo.mp4`
- **Cover Image (`封面图`, 1080×1080 PNG)**: `demos/01-rokid-vision-voice-copilot/assets/review/cover.png`
- **Screenshots (`预览截图`, 480×352 PNG, `>= 1` image)**:
  - `demos/01-rokid-vision-voice-copilot/assets/review/shot1.png` (`CHAT` mode standby HUD)
  - `demos/01-rokid-vision-voice-copilot/assets/review/shot2.png` (`CHAT` mode voice Q&A response)
  - `demos/01-rokid-vision-voice-copilot/assets/review/shot3.png` (`VISION` mode scene recognition)

---

## Agent 2: GCP Multimodal Agent (`02-rokid-gcp-multimodal-agent`)

### 1. Basic Metadata (`基础信息`)

| Studio Form Field (`构建与提审字段`) | Value (Exact Match with `app.json`) | Notes / Constraints |
| :--- | :--- | :--- |
| **Agent Name (`智能体名称` / `agentName`)** | `GCP Multimodal Agent` | 20 chars (`<= 20` chars; no `test`/`beta`) |
| **Studio Agent ID (`agentId`)** | `68e11a45486e4b279704e1e3c43b4b4b` | Submitted 2026-10-21 (`displayStatus: "checking"`) |
| **Category Suggestion (`分类建议`)** | `Efficiency & Tools` / `Translation` (`效率工具` / `翻译与视觉`) | Cloud vision Q&A & live speech-to-speech translator |
| **Version (`版本号` / `reviewNativeVersion`)** | `1.0.9` | Server auto-increments `nativeVersion` by `+0.0.1` on each `updateThirdAgent` save |
| **Engine Requirement (`引擎版本` / `engine`)** | `>=0.18.0` | Packaged with `@yodaos-pkg/aix-cli@0.10.1` |
| **Icon (`应用图标` / `agentLogo`)** | `demos/02-rokid-gcp-multimodal-agent/assets/icon.png` | 512×512 PNG bundled at `assets/icon.png` |
| **Packaged `.aix` (`安装包路径`)** | `demos/02-rokid-gcp-multimodal-agent/dist/rokid-gcp-multimodal-agent.aix` | Optimized `.aix` archive |

- **Description (`智能体简介` / `agentDesc`, 203 chars, `<= 500` chars, truthful, no absolute claims)**:
  > Google Cloud Vertex AI assistant for Rokid Glasses monochrome-green HUD, featuring camera vision Q&A, real-time speech-to-speech translation into English with Gemini Live, and a cloud node status board.

- **Opening Greeting (`开场白` / `agentPrompt`, 204 chars, `<= 300` chars, distinct from description)**:
  > Hello, I am the GCP Multimodal Agent. Tap the temple to capture a photo for Vertex AI vision analysis or switch to Live Translate for real-time speech-to-speech translation into English with Gemini Live.

### 2. Permissions & Purpose Strings (`权限声明与用途说明`)

| Permission (`权限名`) | Purpose String (`权限用途说明`) | Code Call Site |
| :--- | :--- | :--- |
| `CAMERA` | Used when the user taps the temple in `GEMINI` vision mode to capture a scene photo (`wx.media.createCameraContext().takePhoto`) for Vertex AI Gemini multimodal scene analysis. | `pages/index/index.ink` (`triggerGeminiVisionCapture`) |
| `RECORD_AUDIO` | Microphone streams nearby speech (`navigator.mediaDevices.getUserMedia` + `MediaRecorder`) to Google Cloud Gemini Live for real-time speech-to-speech translation into English in `LIVE TRANSLATE` mode. | `pages/index/index.ink` (`startLiveTranslation`) |

### 3. Network & Data Disclosure (`网络与数据说明`)

- **Endpoint**: Google Cloud Run authenticated relay proxy at `https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app` (`GCP_CONFIG.cloudRunUrl` / `GCP_CONFIG.liveTranslateBaseUrl` in `gcp_config.js`).
- **Data Sent**:
  - **Authentication (`POST /api/auth/verify`)**: Rokid account identifier and verification code to obtain a short-lived Bearer session token.
  - **Vision Analysis (`POST /api/gemini`)**: Base64-encoded camera frame (`imageBase64`) + text prompt (`prompt`) forwarded to Vertex AI (`gemini-4-argon`).
  - **Live Speech-to-Speech Translation (`WSS /ws/live-translate`)**: Microphone streams nearby speech (16 kHz mono PCM16 audio chunks) over an authenticated WebSocket to the Cloud Run relay proxy, which forwards it to Google Cloud Vertex AI Gemini Live (`gemini-3.5-live-translate-preview`) and streams back 24 kHz translated English speech audio plus live source and target transcripts. On connection or upstream failure, displays an explicit error notice (`LIVE TRANSLATION UNAVAILABLE · <reason>`) without sample fallbacks.
  - **Health Check (`GET /health`)**: Read-only status probe for the `CLOUD` node telemetry tab.
- **API Key / Secret Audit (`gcp_config.js`)**:
  - Verified `demos/02-rokid-gcp-multimodal-agent/gcp_config.js` contains **no** `'YOUR_GCP_GEMINI_API_KEY'` placeholder and **no** client-side GCP API keys.
  - All Vertex AI and Gemini Live calls are routed through the Cloud Run proxy, which authenticates to Google Cloud using server-side Application Default Credentials (ADC).

### 4. Preview & Review Assets (`预览与提审素材`)

- **Video (`演示视频`, 15–45s MP4, `<= 50 MB`)**: `demos/02-rokid-gcp-multimodal-agent/assets/review/demo.mp4`
- **Cover Image (`封面图`, 1080×1080 PNG)**: `demos/02-rokid-gcp-multimodal-agent/assets/review/cover.png`
- **Screenshots (`预览截图`, 480×352 PNG, `>= 1` image)**:
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot1.png` (`GEMINI` vision mode)
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot2.png` (`TRANSLATE` subtitle mode)
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot3.png` (`CLOUD` telemetry mode)

---

## Agent 3: GCP Live Translator (`02-rokid-gcp-multimodal-agent`, v1.0.10)

### 1. Basic Metadata (`基础信息`)

| Studio Form Field (`构建与提审字段`) | Value (Exact Match with `app.json`) | Notes / Constraints |
| :--- | :--- | :--- |
| **Studio Agent ID (`agentId`)** | `48c2e202270c469886dde77ef1ecc936` | Created via `saveAIUIAgent` (`--create`) |
| **Agent Name (`智能体名称` / `agentName`)** | `GCP Live Translator` | 19 chars (`<= 20` chars; no `test`/`beta`) |
| **Category (`分类` / `category`)** | `work` (`工作`) | Real-time speech-to-speech translation & vision |
| **Version (`版本号` / `nativeVersion`)** | `1.0.10` (`reviewNativeVersion`: `1.0.2`) | SemVer |
| **Engine Requirement (`引擎版本` / `engine`)** | `>=0.18.0` | Packaged with `@yodaos-pkg/aix-cli@0.10.1` |
| **Icon (`应用图标` / `agentLogo`)** | `demos/02-rokid-gcp-multimodal-agent/assets/icon.png` | 512×512 PNG bundled at `assets/icon.png` |
| **Packaged `.aix` (`安装包路径`)** | `demos/02-rokid-gcp-multimodal-agent/dist/rokid-gcp-multimodal-agent.aix` | Optimized `.aix` archive (`md5=cfa2c4c3d9bd6e85a929d48c60098230`) |

- **Description (`智能体简介` / `agentDesc`, 318 chars, `<= 500` chars, truthful, no absolute claims)**:
  > Real-time speech-to-speech translator into English for Rokid Glasses monochrome-green HUD. Powered by Gemini Live on Google Cloud, it auto-detects source languages, translates all nearby speech into spoken English with on-HUD bilingual transcripts, and includes Gemini 4 camera vision Q&A plus a cloud status console.

- **Opening Greeting (`开场白` / `agentPrompt`, 185 chars, `<= 300` chars, distinct from description)**:
  > Hello! I am GCP Live Translator. Start Live Translate to stream nearby speech for real-time spoken English and HUD transcripts, or tap the temple in Vision mode to analyze a scene.

### 2. Permissions & Purpose Strings (`权限声明与用途说明`)

| Permission (`权限名`) | Purpose String (`权限用途说明`) | Code Call Site |
| :--- | :--- | :--- |
| `RECORD_AUDIO` | Streams nearby speech to Google Cloud Gemini Live for real-time speech-to-speech translation into spoken English and on-HUD bilingual transcripts. | `pages/index/index.ink` (`startLiveTranslation`) |
| `CAMERA` | Captures a single scene photo (`wx.media.createCameraContext().takePhoto`) only when the user taps the temple in `VISION` mode for Gemini 4 visual Q&A. | `pages/index/index.ink` (`triggerCameraAndGemini`) |

---

## Pre-Submission Checklist (`提审前自检清单`)

- [x] **Naming & Copy Compliance**: Both `agentName` values are `<= 20` characters (`Vision Voice Copilot`, `GCP Multimodal Agent`), contain no `test`/`beta` markers, and have distinct `agentDesc` (`<= 500` chars, no `100%`/`best` claims) and `agentPrompt` (`<= 300` chars).
- [x] **Engine & Packaging**: Both `.aix` bundles are built with `@yodaos-pkg/aix-cli@0.10.1`, declare `"engine": ">=0.18.0"` and `"inkVersion": ">=0.18.0"`, and embed a 512×512 `assets/icon.png`.
- [x] **Least-Privilege Permissions**: Demo 1 declares `["CAMERA", "RECORD_AUDIO"]`; Demo 2 declares `["CAMERA"]` only. Every declared permission corresponds to an active code path.
- [x] **Launch, Interaction & Back/Exit Rule (Review Rule 3.4)**: Both agents launch cleanly into their 480×352 HUD, respond to temple tap (`Enter`/`GlobalHook`/`Space`) and swipe (`Arrow*`/`Page*`), and **never** call `event.preventDefault()` on `Backspace`, `Escape`, or `GoBack`, allowing the host runtime to exit/navigate back normally.
- [x] **TTS Non-Blocking Completion**: Both agents guard `speechSynthesis.speak` and `wx.speech.playTTS(text)` with a length-based timeout fallback (`clamp(1500 + 220ms * chars, 3000ms, 20000ms)`) so turns never hang when `utterance.onend` is unexposed on device.
- [x] **WXSS & 480×352 Monochrome-Green HUD**: No unsupported WXSS properties (`white-space`, `text-overflow`, `-webkit-line-clamp`, `word-break`, `visibility`, `font-variant`, `position: sticky`), no `2px` normal borders, `font-weight <= 500`, and no English text overflow at 480×352.
- [x] **No Shipped Placeholder Keys**: `gcp_config.js` ships zero API key placeholders (`YOUR_GCP_GEMINI_API_KEY` absent) and delegates GCP credentials to the Cloud Run relay proxy.
- [x] **Media Assets Attached in Studio (`构建与提审`)**: Uploaded the 15–45s MP4 demo video (`<= 50 MB`), `cover.png`, and `shot1..3.png` from `demos/<demo>/assets/review/` for both agents.

---

## Studio Submission Status (`线上提审状态`, 2026-10-21)

| Agent | Studio `agentId` | `reviewNativeVersion` | Submitted Date | `displayStatus` |
| :--- | :--- | :--- | :--- | :--- |
| **Demo 1 (`Vision Voice Copilot`)** | `059b26f3ffcd47ab8280a2d176b0f88a` | `1.0.9` | `2026-10-21` | `checking` |
| **Demo 2 (`GCP Multimodal Agent`)** | `68e11a45486e4b279704e1e3c43b4b4b` | `1.0.8` | `2026-10-21` | `checking` |
| **Demo 2 (`GCP Live Translator`, v1.0.10)** | `48c2e202270c469886dde77ef1ecc936` | `1.0.2` | `2026-10-21` | `checking` |

> **Note on `nativeVersion` Auto-Increment**: The Rokid AIUI Studio backend (`metis/agent/updateThirdAgent`) automatically increments `nativeVersion` by `+0.0.1` on every save call. Before uploading a new release, bump `version` in `app.json` above the current Studio version and invoke `updateThirdAgent` only once per release before calling `cozePublish`.
