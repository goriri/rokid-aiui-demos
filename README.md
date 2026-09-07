# Rokid Glasses AIUI Demos Collection (Rokid AR 智能眼镜案例集)

[![Platform](https://img.shields.io/badge/Platform-Rokid%20Glasses%201%20%2F%202-40ff5e?style=flat-square&logo=android)](https://aiui.rokid.com/)
[![SDK](https://img.shields.io/badge/AIUI%20Framework-Ink%20SFC%20(QuickJS)-000000?style=flat-square&logo=javascript)](https://github.com/jsar-project/AIUI)
[![GCP](https://img.shields.io/badge/Cloud%20AI-Google%20Cloud%20Vertex%20AI-4285F4?style=flat-square&logo=google-cloud)](https://cloud.google.com/vertex-ai)
[![Design](https://img.shields.io/badge/HUD%20Design-Monochrome--Green%20480x352-25D366?style=flat-square)](#-单绿色科学界面设计系统规范)

本项目为基于 **Rokid AIUI** 官方规范与 **Google Antigravity** 平台打造的 Rokid AR 智能眼镜应用集合（Monorepo）。严格遵循 Rokid 官方推荐的 **单绿色科学界面设计系统 (Monochrome-Green Scientific Interface)**，在 **480 × 352** 单绿 MicroLED 光波导视口下，提供纯净透明、极高对比、低眩光的全新 AR 视觉与多模态 AI 交互体验。

---

## 📂 项目仓库目录概览

```text
rokid-aiui-demos/
├── demos/
│   ├── 01-rokid-vision-voice-copilot/     # Demo 1: AR 随身眼脑助手 (本地多模态+语音全双工+态势感知)
│   │   ├── app.json
│   │   ├── app.js
│   │   ├── pages/index/index.ink
│   │   ├── assets/screenshots/            # 480x352 高清 HUD 仿真截图
│   │   ├── assets/recordings/             # 端到端交互 MP4 与 GIF 动图
│   │   └── package.json
│   │
│   └── 02-rokid-gcp-multimodal-agent/     # Demo 2: Google Cloud AI 实时同传与多模态眼脑助理
│       ├── app.json
│       ├── app.js
│       ├── gcp_config.js                  # GCP REST 鉴权与端侧请求引擎
│       ├── server/
│       │   └── gcp_relay_server.mjs       # GCP Cloud Run / Edge 本地中继网关
│       ├── pages/index/index.ink          # 三模态单绿 HUD (Gemini 2.5 + 同传字幕 + GCP 控制台)
│       ├── assets/screenshots/
│       ├── assets/recordings/
│       └── package.json
│
├── package.json                           # 全局 Monorepo 脚本 (统一构建、打包与预览)
├── AGENTS.md                              # 智能体清单与硬件权限规范
└── README.md
```

---

## 🎯 演示项目介绍

### 🌟 Demo 1: AR 随身眼脑助手 (`01-rokid-vision-voice-copilot`)

基于 Rokid 眼镜内置硬件能力与 AIUI 基础组件打造的软硬一体化随身 Copilot。

![Demo 1 交互动图](demos/01-rokid-vision-voice-copilot/assets/recordings/rokid_copilot_demo.gif)

#### 核心能力：
1. **全双工语音交互（CHAT）**：
   - 镜腿轻拍（`Enter` / `GlobalHook`）即刻触发 ASR 唤醒；
   - 本地/云端 LLM 流式打字机逐字输出；
   - 低延迟 TTS 实时语音播报，轻拍随时打断。
2. **多模态视野抓拍（VISION）**：
   - 居中科技感十字瞄准准星，视野目标精确定位；
   - 镜腿单击瞬时抓拍，调用多模态模型进行 30 字极简场景解析。
3. **姿态与态势感知（DASHBOARD）**：
   - 实时读取眼镜内置陀螺仪与加速度计，展示俯仰角（Pitch）、翻滚角（Roll）与计步器。

| 模式一：语音对话 | 模式二：准星对齐 | 模式三：仪表盘态势 |
| :---: | :---: | :---: |
| ![Chat](demos/01-rokid-vision-voice-copilot/assets/screenshots/03_hud_chat_active.png) | ![Vision](demos/01-rokid-vision-voice-copilot/assets/screenshots/04_hud_vision_reticle.png) | ![Dashboard](demos/01-rokid-vision-voice-copilot/assets/screenshots/06_hud_dashboard_imu.png) |

---

### 🚀 Demo 2: Google Cloud AI 实时同传与多模态助手 (`02-rokid-gcp-multimodal-agent`)

将 **Google Cloud** 的前沿云端 AI 能力（Vertex AI Gemini 2.5 Flash、Cloud Translation v2、Cloud Text-to-Speech v1）无缝整合至 Rokid 眼镜。

![Demo 2 交互动图](demos/02-rokid-gcp-multimodal-agent/assets/recordings/rokid_gcp_demo.gif)

#### 核心能力：
1. **Vertex AI Gemini 2.5 Flash 空间多模态推理**：
   - 抓取眼镜前置摄像头画面，直连 GCP Vertex AI 多模态端点，针对准星目标提供空间感知与工程推断。
2. **AR 实时同传双语字幕（AR Live Subtitles）**：
   - 基于 Google Cloud Translation API，在上视安全区呈现原文与高亮同传译文，延迟低于 50ms。
3. **GCP 节点态势与 ADC 认证中枢**：
   - 实时监测 GCP API 连通性、ADC 临时凭据剩余寿命、项目配额与网络时延。

| 模式一：Gemini 2.5 视觉推理 | 模式二：AR 实时双语同传 | 模式三：GCP 认证控制台 |
| :---: | :---: | :---: |
| ![Gemini](demos/02-rokid-gcp-multimodal-agent/assets/screenshots/03_gcp_gemini_analyzed.png) | ![Translate](demos/02-rokid-gcp-multimodal-agent/assets/screenshots/04_gcp_translate_subtitle.png) | ![Console](demos/02-rokid-gcp-multimodal-agent/assets/screenshots/06_gcp_console_health.png) |

---

## 🔐 Google Cloud 鉴权方案设计与 Rokid 平台运行指南

根据 Rokid 官方规范《[账号信息授权与校验](https://rokid.yuque.com/ub8h5n/bkz4ul/0f9c5f6b12acbf80ce81e0eafd0220b8?singleDoc#)》，在 Rokid Glasses（基于轻量级 QuickJS 运行时）上访问 Google Cloud 必须解决智能体身份鉴权与云端资源防刷保护。

本项目开发并部署了生产级 **Google Cloud Run 鉴权代理中继服务（`rokid-aiui-gcp-proxy`）**，实现了严格的 **Rokid Metis 智能体身份门禁**：

```mermaid
sequenceDiagram
    autonumber
    actor User as 用户 (Rokid 眼镜 / App)
    participant Agent as AIUI 智能体 (Ink / 端侧)
    participant Proxy as Cloud Run 代理网关 (rokid-aiui-gcp-proxy)
    participant Metis as Rokid Metis 平台 (rcs.rokid.com)
    participant GCP as Google Cloud (Vertex AI / Translate / TTS)

    Note over User,Agent: 权限声明与端侧授权
    Agent->>Agent: checkUserAuth() 检查授权
    Agent->>Agent: getProfile() 获取 accountId 及一次性 code (5分钟有效)

    Note over Agent,Proxy: 身份校验与门禁拦截
    Agent->>Proxy: POST /api/auth/verify { accountId, code }
    Proxy->>Metis: POST /metis/openApi/v1/checkAccountCode { accountId, code, developerSk }
    Metis-->>Proxy: 返回 { code: 1, data: { checkResult: true/false, mobile } }

    alt 校验未通过 (未授权/校验码过期/伪造)
        Proxy-->>Agent: HTTP 401 Unauthorized (门禁严格拦截，不产生 GCP 消耗)
    else 校验通过 (可信智能体)
        Proxy->>Proxy: 签发受保护 Session Bearer Token (HMAC-SHA256)
        Proxy-->>Agent: 200 OK { sessionToken, expiresIn: 3600 }
        
        Note over Agent,GCP: 授权调用 Google Cloud 核心服务
        Agent->>Proxy: POST /api/gemini (携带 Bearer Token)
        Proxy->>Proxy: 验签通过，自动通过 Cloud Run Metadata 获取 GCP Token
        Proxy->>GCP: 调用 Vertex AI (gemini-2.5-flash) 推理
        GCP-->>Proxy: 返回多模态分析结果
        Proxy-->>Agent: 480x352 HUD 响应数据
    end
```

### 1. 线上真实部署端点 (Cloud Run Production Endpoint)
- **Cloud Run 服务名**：`rokid-aiui-gcp-proxy`
- **正式服务地址**：`https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app`
- **GCP 项目**：`cellular-cider-495602-r9`（Region: `us-central1`）
- **健康检查**：`GET https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app/health`

### 2. 身份验证与安全门禁规则
1. **未授权即拦截**：未携带 Bearer Session Token 或校验码的请求，直接返回 `401 Unauthorized`。
2. **一次性 Code 校验**：Rokid Metis 提供的 `code` 仅 5 分钟有效，且校验一次后由 Metis 服务端自动删除防重放。
3. **安全隔离**：`ROKID_DEVELOPER_SK` 仅存放于 Cloud Run 服务端环境变量中，眼镜端与前端绝不暴露任何私钥。
4. **Cloud Run 零密钥鉴权**：云端容器通过 GCP Instance Metadata 服务自动获取访问令牌，安全免密。

### 3. 端到端全链路测试套件结果
运行 `PROXY_URL=https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app node demos/02-rokid-gcp-multimodal-agent/scripts/test_proxy_auth_e2e.mjs`：
| 测试项 | 预期行为 | 状态 | 实测延迟 |
| :--- | :--- | :---: | :---: |
| `GET /health` | 返回服务状态、工程信息与认证协议 | ✅ PASS | 678 ms |
| `POST /api/gemini` (无凭证) | 触发安全门禁，严格返回 401 拦截 | ✅ PASS | 403 ms |
| `POST /api/translate` (无凭证) | 触发安全门禁，严格返回 401 拦截 | ✅ PASS | 243 ms |
| `POST /api/auth/verify` (非法Code) | 校验拒绝，返回 401 | ✅ PASS | 206 ms |
| `POST /api/auth/verify` (有效智能体) | 校验通过，签发 Bearer Session Token | ✅ PASS | 245 ms |
| `POST /api/translate` (有效Token) | 授权调用 Cloud Translation v2 获得译文 | ✅ PASS | 1423 ms |
| `POST /api/gemini` (有效Token) | 授权调用 Vertex AI Gemini 2.5 Flash | ✅ PASS | 9122 ms |
| `POST /api/tts` (有效Token) | 授权调用 Cloud Text-to-Speech 合成音频 | ✅ PASS | 781 ms |
| `POST /api/translate` (X-Rokid头部) | 单次透传身份校验并成功调用 | ✅ PASS | 373 ms |

---

## 🎨 单绿色科学界面设计系统规范

为匹配 Rokid 单色绿色 MicroLED 光波导镜片，UI 严格遵循以下规范：
- **微显示分辨率**：`480 × 352` px，全屏无外边框溢出；
- **全黑即全透**：背景色统一为 `#000000`，在人眼中呈现为完全透明，不遮挡物理世界；
- **科学绿色色阶**：
  - `100% 亮度 (#40ff5e)`：关键指示标、聚焦文字、操作热区；
  - `72% 亮度 (rgba(64, 255, 94, 0.72))`：次级信息、时间指示、传感器参数；
  - `48% 亮度 (rgba(64, 255, 94, 0.48))`：外框线、次级分割条；
  - `24% 亮度 (rgba(64, 255, 94, 0.24))`：未选中状态条、辅助刻度；
  - `12% 亮度 (rgba(64, 255, 94, 0.12))`：高亮底色背景；
  - `4%~6% 亮度`：卡片背景与面板暗部。

---

## 🛠️ 快速上手与操作说明

### 1. 安装环境
```bash
git clone git@github.com:goriri/rokid-aiui-demos.git
cd rokid-aiui-demos
npm install
```

### 2. 预览与调试

启动 Demo 1 实时热更新预览：
```bash
npm run preview:demo1
```

启动 Demo 2 实时热更新预览：
```bash
npm run preview:demo2
```

启动 GCP 本地中继网关：
```bash
npm run gcp:relay
```

### 3. 构建打包生产工件 (`.aix`)

```bash
# 构建 Demo 1
npm run pack:demo1

# 构建 Demo 2
npm run pack:demo2
```
打包成功后，可在各自工程的 `dist/` 目录下获取约 20 KB 的极致轻量 `.aix` 安装包。

### 4. 键盘/手势映射
| 镜腿动作 | 键盘映射 | 功能行为 |
| :--- | :--- | :--- |
| **轻拍 / 单击** | `Enter` / `Space` | 触发拍照 / 发起语音 / 切换下一句同传 / 打断播报 |
| **前后滑动** | `↓` (`ArrowDown`) / `↑` (`ArrowUp`) | 循环切换三模态卡片 |
| **长按** | `Esc` | 打断当前流程，复位待命 |

---

## 📄 开源许可证
本项目遵循 MIT License 协议开源。
