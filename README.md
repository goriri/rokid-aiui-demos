# Rokid Glasses AR 随身眼脑助手 (AIUI Demo Agent)

本项目是基于 **Rokid AIUI** 官方规范与 **Antigravity** 平台打造的 AR 智能眼镜 Demo 智能体。遵循官方推荐的 **单绿色科学界面设计系统 (Monochrome-Green Scientific Interface)**，在 **480 × 352** 视口下实现了“全双工语音多轮交互 + 镜腿轻拍拍照识图 + 头部姿态态势感知”的软硬件一体化体验。

---

## 🌟 核心特性与硬件适配

1. **单绿色 MicroLED 视效系统**：
   - 纯黑（`#000000`）在光波导镜片上为完全透光，保障视线无遮挡与行走安全；
   - 严格遵循 `#40ff5e` 绿色亮度阶梯（100% 关键焦点 / 72% 正文文本 / 48% 边框 / 24% 刻度线 / 12% 选中高亮底色 / 6% 分组轮廓）；
   - 1px 发丝边框与仪表盘布局风格，消除光晕（blooming）眩目感。
2. **三模态沉浸交互**：
   - **CHAT（语音对话）**：ASR 实时语音拾音 -> LLM 流式逐字生成 -> TTS 语音低延迟播报；
   - **VISION（相机识图）**：十字准星瞄准 -> 镜腿轻拍拍照 -> 多模态视觉理解（`image_url`）-> 语音讲解；
   - **DASHBOARD（态势感知）**：实时读取眼镜内置陀螺仪/加速度计，展示俯仰角（Pitch）、翻滚角（Roll）、运动步数与硬件就绪状态。
3. **镜腿物理按键与手势联动**：
   - **单击 / 轻拍**（`Enter` / `GlobalHook`）：打断播报 / 触发拍照 / 开启录音；
   - **滑动**（`ArrowRight` / `ArrowLeft`）：在 CHAT / VISION / DASHBOARD 三种模式间平滑切换；
   - **长按**：退出当前会话并恢复待命状态。

---

## 📁 项目工程结构

```text
├── .agent/
│   └── skills/
│       └── aiui-dev/          # AIUI 官方 Agent Skill（API 白名单、设计规范与组件契约）
├── .aixignore                 # AIX 打包忽略配置
├── AGENTS.md                  # 智能体清单（声明 camera、microphone、gyroscope 权限）
├── app.json                   # 全局页面路由与窗口配置
├── app.js                     # 全局生命周期与设备信息
├── package.json               # 工程配置与 aix-cli 脚本
├── pages/
│   └── index/
│       └── index.ink          # 核心单文件组件（SFC：<script def> + <script setup> + <page> + <style>）
└── dist/
    ├── rokid-glasses-copilot.aix  # 编译打包好的 AIX 分发工件（仅约 28 KB）
    └── preview.html           # 离线预览生成的 HTML 测试文件
```

---

## 🚀 快速上手与本地预览

### 1. 安装依赖
```bash
npm install
```

### 2. 启动本地 480×352 实时热更新预览
基于原生 Ink 浏览器运行时启动本地开发服务，并在浏览器自动打开仿真窗口：
```bash
npm run dev
# 或手动执行：
npx aix preview . --dev --launch
```
- **键盘操作测试**：
  - 按 `Enter` 键：模拟轻拍镜腿（触发拍照识图或发起语音）；
  - 按 `→` (右方向键)：向右滑动切换卡片（CHAT -> VISION -> DASHBOARD）；
  - 按 `←` (左方向键)：向左滑动切换卡片。

### 3. 构建打包 AIX 生产工件
```bash
npm run pack
```
打包成功后，可在 `dist/rokid-glasses-copilot.aix` 查看产物，大小仅约 28 KB。

---

## 👓 AIUI Studio 云端集成与眼镜真机验证

### 第一步：AIUI Studio 导入工程
1. 访问 [Rokid AIUI Studio（中国站）](https://aiui.rokid.com/)；
2. 登录账号后，新建智能体项目，选择“本地导入”或将代码推送到 GitHub 后一键同步关联；
3. 在云端 Studio 中可直观查看 `.ink` 源码渲染、配置第三方 LLM 密钥与语音合成音色。

### 第二步：眼镜真机无线同步
1. 确保手机已安装 **Hi Rokid App**，并与 Rokid Glasses 完成蓝牙/Wi-Fi 配对；
2. 在 Hi Rokid App 中进入：**我的 -> 设置 -> 开发者选项 -> 更新眼镜资源包**；
3. 将云端构建的 `.aix` 安装至眼镜。

### 第三步：语音与手势体验
- 唤醒词说出：`"Hi Rokid，打开随身眼脑助手"`；
- 对话交互：直接向眼镜提出问题，观察单绿 HUD 逐字流式打字效果与语音播报；
- 拍照识图：手指轻拍右侧镜腿，眼镜摄像头捕获前方物体，并在 1 秒内给出多模态识别结果；
- 手指在镜腿前后轻扫，切换至仪表盘模式查看头部实时俯仰姿态。

---

## 🛠️ Antigravity 技能配置说明

官方 `aiui-dev` 技能库已同步植入 Antigravity 全局技能库（`~/.gemini/antigravity/skills/aiui-dev`）与项目本地（`.agent/skills/aiui-dev`）。
Antigravity 会自动读取此技能规范，严格遵循：
- 仅使用官方白名单 API（`LanguageModel`, `SpeechRecognition`, `wx.media.createCameraContext`, `Gyroscope` 等）；
- 单文件组件必须遵循 `<script type="application/json" def>`、`<script setup>`、`<page>`、`<style>` 的规范排版；
- 强制遵循 480×352 视口与单绿色亮度阶梯。
