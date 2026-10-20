# Rokid AIUI Studio Review & Submission Kit (`构建与提审`)

This document provides the exact metadata, permission purpose strings, network/data disclosures, package paths, and pre-submission verification checklist required to submit both AIUI 0.18 agents in Rokid AIUI Studio (`构建与提审`). All field values match the packaged `app.json` definitions.

---

## Agent 1: Vision Voice Copilot (`01-rokid-vision-voice-copilot`)

### 1. Basic Metadata (`基础信息`)

| Studio Form Field (`构建与提审字段`) | Value (Exact Match with `app.json`) | Notes / Constraints |
| :--- | :--- | :--- |
| **Agent Name (`智能体名称` / `agentName`)** | `Vision Voice Copilot` | 20 chars (`<= 20` chars; no `test`/`beta`) |
| **Category Suggestion (`分类建议`)** | `Efficiency & Tools` (`效率工具` / `AI 助手`) | Hands-free voice & vision assistant |
| **Version (`版本号` / `nativeVersion`)** | `1.0.0` | SemVer |
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
  - **Scene Analysis (`VISION` mode)**: Google Cloud Run authenticated relay proxy at `https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app` (`/api/auth/verify` and `/api/gemini`, backed by Vertex AI Gemini).
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
| **Category Suggestion (`分类建议`)** | `Efficiency & Tools` / `Translation` (`效率工具` / `翻译与视觉`) | Cloud vision Q&A & bilingual subtitle assistant |
| **Version (`版本号` / `nativeVersion`)** | `1.0.0` | SemVer |
| **Engine Requirement (`引擎版本` / `engine`)** | `>=0.18.0` | Packaged with `@yodaos-pkg/aix-cli@0.10.1` |
| **Icon (`应用图标` / `agentLogo`)** | `demos/02-rokid-gcp-multimodal-agent/assets/icon.png` | 512×512 PNG bundled at `assets/icon.png` |
| **Packaged `.aix` (`安装包路径`)** | `demos/02-rokid-gcp-multimodal-agent/dist/rokid-gcp-multimodal-agent.aix` | Optimized `.aix` archive |

- **Description (`智能体简介` / `agentDesc`, 199 chars, `<= 500` chars, truthful, no absolute claims)**:
  > Google Cloud Vertex AI and Cloud Translation assistant for Rokid Glasses monochrome-green HUD, featuring camera vision Q&A, live bilingual subtitle translation, and a cloud node status board.

- **Opening Greeting (`开场白` / `agentPrompt`, 144 chars, `<= 300` chars, distinct from description)**:
  > Hello, I am the GCP Multimodal Agent. Tap the temple to capture a photo for Vertex AI vision analysis or switch to live bilingual subtitles.

### 2. Permissions & Purpose Strings (`权限声明与用途说明`)

| Permission (`权限名`) | Purpose String (`权限用途说明`) | Code Call Site |
| :--- | :--- | :--- |
| `CAMERA` | Used when the user taps the temple in `GEMINI` vision mode to capture a scene photo (`wx.media.createCameraContext().takePhoto`) for Vertex AI Gemini multimodal scene analysis. | `pages/index/index.ink` (`triggerCameraAndGemini`) |

*(Note: Only `CAMERA` is declared because Demo 2 does not invoke microphone recording APIs.)*

### 3. Network & Data Disclosure (`网络与数据说明`)

- **Endpoint**: Google Cloud Run authenticated relay proxy at `https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app` (`GCP_CONFIG.cloudRunUrl` in `gcp_config.js`).
- **Data Sent**:
  - **Authentication (`POST /api/auth/verify`)**: Rokid account identifier and verification code to obtain a short-lived Bearer session token.
  - **Vision Analysis (`POST /api/gemini`)**: Base64-encoded JPEG camera frame (`imageBase64`) + text prompt (`prompt`) forwarded to Vertex AI (`gemini-2.5-flash`).
  - **Subtitle Translation (`POST /api/translate`)**: Source utterance string (`text`) + target language code (`target: 'en' | 'zh-CN'`) forwarded to Google Cloud Translation API v2.
  - **Health Check (`GET /health`)**: Read-only status probe for the `CLOUD` node telemetry tab.
- **API Key / Secret Audit (`gcp_config.js`)**:
  - Verified `demos/02-rokid-gcp-multimodal-agent/gcp_config.js` contains **no** `'YOUR_GCP_GEMINI_API_KEY'` placeholder and **no** client-side GCP API keys.
  - Even if a client-side placeholder existed in legacy revisions, it is unused because all Vertex AI and Cloud Translation calls are routed through the Cloud Run proxy (`https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app`), which authenticates to Google Cloud using server-side Application Default Credentials (ADC).

### 4. Preview & Review Assets (`预览与提审素材`)

- **Video (`演示视频`, 15–45s MP4, `<= 50 MB`)**: `demos/02-rokid-gcp-multimodal-agent/assets/review/demo.mp4` *(being produced)*
- **Cover Image (`封面图`)**: `demos/02-rokid-gcp-multimodal-agent/assets/review/cover.png` *(being produced)*
- **Screenshots (`预览截图`, `>= 1` image)**:
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot1.png` (`GEMINI` vision mode) *(being produced)*
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot2.png` (`TRANSLATE` subtitle mode) *(being produced)*
  - `demos/02-rokid-gcp-multimodal-agent/assets/review/shot3.png` (`CLOUD` telemetry mode) *(being produced)*

---

## Pre-Submission Checklist (`提审前自检清单`)

- [x] **Naming & Copy Compliance**: Both `agentName` values are `<= 20` characters (`Vision Voice Copilot`, `GCP Multimodal Agent`), contain no `test`/`beta` markers, and have distinct `agentDesc` (`<= 500` chars, no `100%`/`best` claims) and `agentPrompt` (`<= 300` chars).
- [x] **Engine & Packaging**: Both `.aix` bundles are built with `@yodaos-pkg/aix-cli@0.10.1`, declare `"engine": ">=0.18.0"` and `"inkVersion": ">=0.18.0"`, and embed a 512×512 `assets/icon.png`.
- [x] **Least-Privilege Permissions**: Demo 1 declares `["CAMERA", "RECORD_AUDIO"]`; Demo 2 declares `["CAMERA"]` only. Every declared permission corresponds to an active code path.
- [x] **Launch, Interaction & Back/Exit Rule (Review Rule 3.4)**: Both agents launch cleanly into their 480×352 HUD, respond to temple tap (`Enter`/`GlobalHook`/`Space`) and swipe (`Arrow*`/`Page*`), and **never** call `event.preventDefault()` on `Backspace`, `Escape`, or `GoBack`, allowing the host runtime to exit/navigate back normally.
- [x] **TTS Non-Blocking Completion**: Both agents guard `speechSynthesis.speak` and `wx.speech.playTTS(text)` with a length-based timeout fallback (`clamp(1500 + 220ms * chars, 3000ms, 20000ms)`) so turns never hang when `utterance.onend` is unexposed on device.
- [x] **WXSS & 480×352 Monochrome-Green HUD**: No unsupported WXSS properties (`white-space`, `text-overflow`, `-webkit-line-clamp`, `word-break`, `visibility`, `font-variant`, `position: sticky`), no `2px` normal borders, `font-weight <= 500`, and no English text overflow at 480×352.
- [x] **No Shipped Placeholder Keys**: `gcp_config.js` ships zero API key placeholders (`YOUR_GCP_GEMINI_API_KEY` absent) and delegates GCP credentials to the Cloud Run relay proxy.
- [ ] **Media Assets Attached in Studio (`构建与提审`)**: Upload the 15–45s MP4 demo video (`<= 50 MB`), `cover.png`, and `shot1..3.png` from `demos/<demo>/assets/review/` once media generation finishes.
