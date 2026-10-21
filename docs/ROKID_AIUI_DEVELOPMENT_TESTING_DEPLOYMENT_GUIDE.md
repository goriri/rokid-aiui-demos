# Rokid AIUI 智能体开发、测试、打包与部署全流程工程指南

本文档总结了在 Rokid Glasses（RokidGlasses1 / RokidGlasses2）上进行 AIUI 智能体完整生命周期（开发、模拟器测试、云端代理整合、AIX/Cache 双重打包、国内/国际双平台部署及真机扫码调试）的最佳实践与踩坑经验。

> 💡 **AIUI 0.18 最新端到端运维手册（含 `aix-cli@0.10.1` ADB 真机直装、Vertex AI Global `gemini-4-argon` 多模态代理、真机音画内录与 Studio 自动提审）**: 请参阅 [.agent/skills/rokid-aiui-lifecycle/SKILL.md](../.agent/skills/rokid-aiui-lifecycle/SKILL.md) 与 [REVIEW_SUBMISSION.md](REVIEW_SUBMISSION.md)。

---

## 1. 硬件规范与核心架构

### 1.1 光学与显示规范
- **显示芯片**: 单绿色 MicroLED 光波导（Monochrome-Green Waveguide）。
- **物理分辨率**: **480 × 352** 像素。页面宽度严格限制为 `480px`，高度建议在 `120px ~ 352px` 之间，超出部分支持触控板纵向滚动。
- **色彩策略**:
  - **背景色**: 必须使用纯黑 `#000000`（在单绿波导镜片上表现为 100% 全透明，融入现实世界）。**严禁**大面积色块。
  - **高亮主色**: `#40ff5e`（高亮绿色），用于聚焦框、准星、高光文字。
  - **半透明色**: `rgba(64, 255, 94, 0.6)` 或 `rgba(64, 255, 94, 0.4)`，用于次级文本、卡片边框、辅助网格。
  - **卡片边框**: 统一使用 `1px solid rgba(64, 255, 94, 0.4)`（AIUI 0.18 规范要求常规边框为 `1px`），圆角建议为 `12px`。
- **禁止项**: 严禁在 HUD 界面上默认使用 Emoji 或全彩位图。

### 1.2 端侧运行时环境
- **JavaScript 引擎**: QuickJS 微运行时（AIUI `>=0.18.0` / `@yodaos-pkg/aix-cli@0.10.1`）。
- **组件规范**: SFC `.ink` 单文件组件，整合 `<config>`、`<script>`、`<template>`、`<style>`。
- **权限清单 (`app.json` 最小权限大写枚举，详见 [`rokid-aiui-lifecycle`](../.agent/skills/rokid-aiui-lifecycle/SKILL.md))**:
  - `CAMERA`: 拍照与视觉采样 (`wx.media.createCameraContext()`)。
  - `RECORD_AUDIO`: 端侧麦克风录音与 `SpeechRecognition` ASR。

---

## 2. 本地开发与端侧逻辑设计

### 2.1 SFC `.ink` 核心结构
每个页面为一个独立 `.ink` 文件：
```html
<config>
{
  "description": "HUD 主界面，负责语音交互与相机多模态分析",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "status": { "type": "string" }
      }
    }
  }
}
</config>

<script>
import wx from 'wx';

export default {
  data: {
    status: 'IDLE',
    recognizedText: ''
  },
  onLoad() {
    console.log('Page loaded');
    this.initSensors();
  },
  methods: {
    initSensors() {
      wx.device.onAccelerometerChange?.((res) => {
        // IMU 态势追踪
      });
    },
    async captureVision() {
      const camera = wx.media.createCameraContext();
      const photo = await camera.takePhoto({ quality: 'high' });
      // 调用识别中继
    }
  }
};
</script>

<template>
  <view class="hud-container">
    <view class="hud-header">
      <text class="hud-title">AI VISION</text>
      <text class="hud-status">{{status}}</text>
    </view>
    <view class="reticle-box">
      <view class="crosshair-h" />
      <view class="crosshair-v" />
    </view>
  </view>
</template>

<style>
.hud-container {
  width: 480px;
  height: 352px;
  background-color: #000000;
  box-sizing: border-box;
  padding: 16px;
}
.hud-title {
  color: #40ff5e;
  font-size: 16px;
  font-weight: bold;
}
</style>
```

---

## 3. 外部云服务与安全鉴权中继 (Cloud Run Relay)

### 3.1 架构设计背景
- Rokid Glasses 端侧采用微运行时，不支持复杂的 Google Cloud SDK、ADC 证书挂载或私钥签名计算；
- 根据 Rokid 官方服务接入规范，第三方服务（如 Google Cloud Vertex AI、Translation、Gemini 等）应通过 **中继代理（Relay Proxy）** 暴露；
- 只有通过 Rokid AIUI 智能体签名验证（`X-AIUI-Signature` / 智能体鉴权 Token）的请求，才能获得访问 Google Cloud 算力服务的授权。

### 3.2 鉴权与中继链路
```
[Rokid Glasses AIUI 端侧]
         │ (HTTP POST with X-AIUI-Signature / Agent Token)
         ▼
[Google Cloud Run 安全中继代理 (Node.js/Express)]
         │ 1. 验证 AIUI 平台签名 & 时间戳防重放
         │ 2. 校验 Agent ID 与调用权限
         │ 3. 本地/Workload Identity 读取 GCP ADC 凭据
         ▼
[Google Cloud 后端服务 (Vertex AI / Translation API / Storage)]
```

### 3.3 签名防重放校验实现要点
中继服务校验三要素：
1. `X-AIUI-Timestamp`: 时间戳偏差不超过 ±300 秒；
2. `X-AIUI-Agent-Id`: 与云端注册的合法 Agent ID 一致；
3. `X-AIUI-Signature`: `HMAC-SHA256(secretKey, `${agentId}\n${timestamp}\n${nonce}\n${bodyHash}`)`。

---

## 4. 打包体系：AIX 运行时包 vs Cache 源码暂存包

Rokid AIUI 平台架构中存在两套独立的压缩包格式，**职责完全不同，命名与结构规则必须严格区分**：

### 4.1 运行时安装包 (`.aix`)
- **用途**: 分发给 Rokid Glasses 真机安装、下载与模拟器执行。
- **文件格式**: ZIP 归档，包含 `app.json`、`app.js`、编译后的 `pages/`、资源文件与 `manifest.json`。
- **压缩要求**: 支持 gzip 二进制压缩传输。
- **命名规范**: `metis/${agentId}-${timestamp}.aix`。

### 4.2 源码暂存包 (`cache.zip`) —— 核心避坑点
- **用途**: Web IDE（AIUI Studio）用于在浏览器端解包、挂载至 OPFS 工作区并展示代码编辑器。
- **严格客户端校验正则**:
  AIUI Studio 前端 (`global_index.js`) 中的 `op` 函数执行以下硬编码正则校验：
  ```javascript
  const tut = "[a-z0-9]{10}";
  const d = new RegExp(`^${agentId}-cache-v(\\d+)-(\\d{8}T\\d{6}Z)-(${tut})\\.zip$`).exec(fileName);
  ```
- **关键规则（违反任一项都会导致侧边栏显示“Failed” / “同步失败”）**:
  1. **版本号**: 必须为纯整型数字 `v(\d+)`（例如 `v1`、`v2`），**严禁**使用 SemVer 格式（如 `v1.0.3` 必定校验失败）。
  2. **时间戳**: 必须为严格的 UTC ISO 格式 `(\d{8}T\d{6}Z)`（例如 `20260916T080823Z`），**严禁**使用 Unix 毫秒时间戳。
  3. **随机哈希**: 必须为严格 10 位小写字母或数字 `[a-z0-9]{10}`。
  4. **目录层级结构**:
     - 压缩包顶级必须且只能包含一个与智能体同名的顶级目录（如 `AR随身眼脑助手/`）；
     - 严禁在根目录直接放置散列文件；
     - 禁止包含非规范隐藏目录（如 `.git`、`node_modules` 等）。
  5. **MD5 校验**: 上传后在 Metis 登记的 `codeFileMd5` 必须与 zip 二进制哈希严格一致，Studio 校验失败会拒绝加载。

---

## 5. 云端发布与双平台部署流程

### 5.1 部署平台对比
| 特性 | 国内站 (China Mainland) | 国际站 (Global) |
| :--- | :--- | :--- |
| **控制台地址** | `https://aiui.rokid.com/` | `https://aiui-global.rokid.com/` |
| **API 服务端** | `https://rcs-internal.rokid.com` | `https://rcs-internal.rokid.com` |
| **OSS 存储区域** | 华东1（杭州）`oss-cn-hangzhou` | 亚太东南1（新加坡）`oss-ap-southeast-1` |
| **CDN 加速域名** | `https://arapp.rokidcdn.com/` | `https://arapp.rokidcdn.com/` |
| **默认界面语言** | 简体中文 (`zh-CN`) | 英文 (`en`) / 支持切换多语言 |

### 5.2 自动化部署标准时序
1. **身份认证**:
   通过 Rokid 统一通行证接口（`POST https://account.rokid.com/user/login`）获取包含 `accountId` 与 `access_token` 的 JWT。
2. **云端创建/获取智能体**:
   调用 `POST /metis/agent/getAIUIAgentList` 检查已存智能体或调用 `saveAIUIAgent` 初始化。
3. **上传产物至 OSS**:
   - 上传 `.aix` 安装包至 `metis/${agentId}-${timestamp}.aix`；
   - 上传规范命名的 `cache.zip` 至 `metis/cache/${fileName}`。
4. **元数据关联与固化**:
   调用 `POST /metis/agent/saveAIUIAgent`，更新参数：
   ```json
   {
     "agentId": "059b26f3ffcd47ab8280a2d176b0f88a",
     "agentName": "AR随身眼脑助手",
     "agentVersion": "1.0.0",
     "filePath": "https://arapp.rokidcdn.com/metis/...aix",
     "fileMd5": "2d293d6af2a806f5af9ed29c75748a8b",
     "codeFilePath": "https://rokid-arapp.oss-accelerate.aliyuncs.com/metis/cache/...zip",
     "codeFileMd5": "7f89e4f6caa27ad0c95dfde71cc97933",
     "permissions": "camera,microphone,audio,network"
   }
   ```
5. **OPFS 工作区同步**:
   在 Web 浏览器刷新并点击该项目，Studio 将状态从 `Update`（有更新）自动跃迁为 `Synced`（已同步）。

---

## 6. 真机调试与扫码运行 (On-Device Verification)

> 💡 **AIUI 0.18 ADB 直装命令**: 推荐使用 `@yodaos-pkg/aix-cli@0.10.1` 执行 `npx aix device -s $S set-dev`、`npx aix install -s $S dist/<name>.aix` 与 `npx aix launch-page -s $S dist/<name>.aix pages/index/index`（完整流程见 [`rokid-aiui-lifecycle`](../.agent/skills/rokid-aiui-lifecycle/SKILL.md)）。

### 6.1 扫码直达机制
Rokid 伴侣 App 支持通过官方标准 DeepLink / 协议码加载调试包：
- **二维码内容格式**:
  ```
  https://aiui-global.rokid.com/debug?agentId=${agentId}&token=${debugToken}
  ```
  或包含 CDN 直链的 AIUI 安装包指令。
- **真机流转过程**:
  1. 手机打开“Rokid”伴侣 App；
  2. 切换至“设备” -> “扫一扫”；
  3. 扫描控制台生成的调试二维码；
  4. App 提示 `正在下载智能体资源包...`；
  5. 下载完成后提示 `智能体资源包下载成功，已推送至眼镜`。

### 6.2 眼镜端交互手势与快捷口令
- **语音唤醒**:
  - 在眼镜待命界面说出 `打开随身眼脑助手` 或 `打开GCP多模态助手`；
  - 启动后支持全双工持续对话与自然打断。
- **镜腿触控板 (Temple Touchpad)**:
  - **单击 (Tap / Enter)**: 确认操作、拍照触发或发送当前选中的指令；
  - **双击 (Double-tap)**: 退出当前界面 / 模式切换；
  - **前后滑动 (Swipe Forward / Backward)**: 菜单选项切换、卡片翻页、长文本滚动。
