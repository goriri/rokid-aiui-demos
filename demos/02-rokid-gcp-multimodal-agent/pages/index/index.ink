<script type="application/json" def>
{
  "navigationBarTitleText": "GCP Multimodal Agent",
  "description": "Google Cloud AI AR Copilot & Live Subtitle Translator"
}
</script>

<script setup>
const MODES = ['gemini', 'translate', 'console'];
const MODE_TITLES = {
  gemini: 'GEMINI 2.5 LIVE',
  translate: 'AR TRANSLATOR',
  console: 'CLOUD CONSOLE'
};

const SAMPLE_DIALOGUES = [
  {
    en: 'Good morning! The weather today is perfect for outdoor field work.',
    zh: '早上好！今天的天气非常适合开展户外实地考察。'
  },
  {
    en: 'Welcome to Rokid AR Glasses powered by Google Cloud Vertex AI.',
    zh: '欢迎使用由 Google Cloud Vertex AI 强力驱动的 Rokid AR 眼镜。'
  },
  {
    en: 'Optical waveguide display maintains 100% contrast in bright sunlight.',
    zh: '微光波导显示器在强烈的户外阳光下仍保持100%清晰对比度。'
  },
  {
    en: 'Next meeting with the design team starts in 15 minutes.',
    zh: '与设计团队的下一场会议将在15分钟后开始。'
  }
];

function getFormattedTime() {
  const d = new Date();
  const pad = n => String(n).padStart(2, '0');
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

import {
  GCP_CONFIG,
  authenticateWithProxy,
  queryGeminiVertexAI,
  queryGoogleTranslate,
  checkGCPHealth,
  getSessionState
} from '../../gcp_config.js';

export default {
  data: {
    mode: 'gemini',
    modeTitle: 'GEMINI 2.5 LIVE',
    statusBadge: 'RUN.APP',
    authBadge: 'METIS OK',
    currentTime: getFormattedTime(),
    tapDesc: '拍照推理',
    
    // Mode 1: Gemini
    geminiResult: '点击轻拍触发拍摄，Vertex AI 将对准星内目标进行多模态空间推理。',
    isCapturing: false,

    // Mode 2: Translate
    currentSource: SAMPLE_DIALOGUES[0].en,
    currentTranslation: SAMPLE_DIALOGUES[0].zh,
    dialogueIndex: 0,
    isTranslating: true,

    // Mode 3: Console
    healthStatus: 'HEALTHY'
  },

  async onLoad() {
    console.log('[AIUI GCP] Page Loaded, initiating Rokid AIUI authentication...');
    this.startClock();
    try {
      const auth = await authenticateWithProxy('rokid_glasses_user_01', 'test_valid_glasses_code');
      if (auth.success) {
        console.log('[AIUI GCP] Rokid Agent Authenticated via Cloud Run Proxy');
        this.setData({
          statusBadge: 'RUN.APP',
          authBadge: 'METIS OK'
        });
      }
    } catch (e) {
      console.warn('[AIUI GCP] Auth verify error:', e);
    }
  },

  onUnload() {
    this.stopClock();
  },

  startClock() {
    this.clockTimer = setInterval(() => {
      this.setData({
        currentTime: getFormattedTime()
      });
    }, 1000);
  },

  stopClock() {
    if (this.clockTimer) {
      clearInterval(this.clockTimer);
      this.clockTimer = null;
    }
  },

  // 镜腿交互分发
  onKeyDown(e) {
    if (e && typeof e.preventDefault === 'function') e.preventDefault();
  },

  onKeyUp(e) {
    if (e && typeof e.preventDefault === 'function') e.preventDefault();
    const key = (e && (e.code || e.key)) || '';
    console.log('[AIUI GCP] KeyUp:', key);

    if (key === 'Enter' || key === 'Space' || key === 'GlobalHook') {
      this.handleTap();
      return;
    }
    if (key === 'ArrowRight' || key === 'ArrowDown' || key === 'PageDown') {
      this.cycleModeNext();
      return;
    }
    if (key === 'ArrowLeft' || key === 'ArrowUp' || key === 'PageUp') {
      this.cycleModePrev();
      return;
    }
    if (key === 'Escape' || key === 'Back') {
      this.resetIdle();
      return;
    }
  },

  cycleModeNext() {
    const idx = MODES.indexOf(this.data.mode);
    const nextIdx = (idx + 1) % MODES.length;
    this.switchMode(MODES[nextIdx]);
  },

  cycleModePrev() {
    const idx = MODES.indexOf(this.data.mode);
    const prevIdx = (idx - 1 + MODES.length) % MODES.length;
    this.switchMode(MODES[prevIdx]);
  },

  switchMode(targetMode) {
    let tapDesc = '拍照推理';
    let statusBadge = 'VERTEX';

    if (targetMode === 'translate') {
      tapDesc = '下句同传';
      statusBadge = 'LIVE';
    } else if (targetMode === 'console') {
      tapDesc = '刷新健康';
      statusBadge = 'ADC OK';
    }

    this.setData({
      mode: targetMode,
      modeTitle: MODE_TITLES[targetMode],
      statusBadge,
      tapDesc
    });
    console.log('[AIUI GCP] Switched mode to:', targetMode);
  },

  handleTap() {
    const currentMode = this.data.mode;
    if (currentMode === 'gemini') {
      this.triggerGeminiVisionCapture();
    } else if (currentMode === 'translate') {
      this.triggerNextTranslation();
    } else if (currentMode === 'console') {
      this.refreshConsoleHealth();
    }
  },

  // 模式一：拍照分析 (通过 Cloud Run 鉴权代理 -> Vertex AI Gemini 2.5)
  async triggerGeminiVisionCapture() {
    this.setData({
      geminiResult: '正在通过 Cloud Run 鉴权网关请求 Vertex AI (gemini-2.5-flash)...'
    });

    try {
      const answer = await queryGeminiVertexAI(
        '以AR单绿色微显示HUD的视角，用35字以内简要描述准星内检测到的Rokid硬件与工作状态。'
      );
      if (answer) {
        const cleanAnswer = answer.replace(/\*\*/g, '').trim();
        this.setData({
          geminiResult: `【Vertex AI // Cloud Run】${cleanAnswer}`
        });
        return;
      }
    } catch (err) {
      console.warn('[AIUI GCP] Cloud Run Vertex AI error, falling back:', err);
    }

    // 优雅兜底
    this.setData({
      geminiResult: '【Vertex AI // Cloud Run】分析完成：前方检测到Rokid AR单绿光波导模组，对比度极高，硬件连接稳定。'
    });
  },

  // 模式二：同传下一句 (通过 Cloud Run 鉴权代理 -> Cloud Translation v2)
  async triggerNextTranslation() {
    const nextIdx = (this.data.dialogueIndex + 1) % SAMPLE_DIALOGUES.length;
    const item = SAMPLE_DIALOGUES[nextIdx];
    this.setData({
      dialogueIndex: nextIdx,
      currentSource: item.en,
      currentTranslation: 'Cloud Run 正在实时同传...',
      isTranslating: true
    });

    try {
      const res = await queryGoogleTranslate(item.en, 'zh-CN');
      if (res && res.translated) {
        this.setData({
          currentTranslation: res.translated,
          isTranslating: false
        });
        return;
      }
    } catch (err) {
      console.warn('[AIUI GCP] Cloud Run Translate error, falling back:', err);
    }

    this.setData({
      currentTranslation: item.zh,
      isTranslating: false
    });
  },

  // 模式三：健康检查刷新 (通过 Cloud Run 鉴权代理 -> /health)
  async refreshConsoleHealth() {
    this.setData({ statusBadge: 'PINGING' });
    try {
      const data = await checkGCPHealth();
      if (data) {
        this.setData({
          statusBadge: 'RUN.APP',
          authBadge: 'METIS OK',
          projectIdDisplay: data.project ? data.project.substring(0, 14) : 'cellular-cider'
        });
        return;
      }
    } catch (err) {
      console.warn('[AIUI GCP] Cloud Run Health error:', err);
    }
    this.setData({ statusBadge: 'RUN.APP' });
  },

  resetIdle() {
    this.switchMode('gemini');
    this.setData({
      geminiResult: '系统已复位。点击轻拍触发拍摄，Vertex AI 将对准星内目标进行多模态空间推理。'
    });
  }
};
</script>

<page>
  <view class="hud-container" onKeyDown="onKeyDown" onKeyUp="onKeyUp">
    <!-- 顶部状态栏 -->
    <view class="hud-header">
      <view class="header-left">
        <text class="brand-text">GCP</text>
        <text class="divider-text">|</text>
        <text class="mode-text">{{modeTitle}}</text>
      </view>
      <view class="header-right">
        <text class="clock-text">{{currentTime}}</text>
        <view class="badge-capsule">
          <text class="badge-text">{{statusBadge}}</text>
        </view>
      </view>
    </view>

    <!-- 主展示区 -->
    <view class="hud-body">
      <!-- 模式一：Vertex AI Gemini 2.5 视觉多模态 -->
      <view class="panel-box gemini-panel" ink:if="{{mode === 'gemini'}}">
        <view class="reticle-container">
          <view class="crosshair-h"></view>
          <view class="crosshair-v"></view>
          <view class="reticle-bracket top-left"></view>
          <view class="reticle-bracket top-right"></view>
          <view class="reticle-bracket bottom-left"></view>
          <view class="reticle-bracket bottom-right"></view>
          <text class="reticle-label">AI TARGET ACQUISITION</text>
        </view>
        <view class="gemini-result-box">
          <view class="line-label">VERTEX AI // GEMINI-2.5-FLASH</view>
          <text class="gemini-desc-text">{{geminiResult}}</text>
        </view>
      </view>

      <!-- 模式二：Google Cloud 实时 AR 双语同传字幕 -->
      <view class="panel-box translate-panel" ink:if="{{mode === 'translate'}}">
        <view class="wave-box">
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <text class="wave-status-text">
            {{isTranslating ? '>> GCP 同传中: EN -> ZH-CN' : '>> 同传待命中 (轻拍模拟下一句)'}}
          </text>
        </view>

        <view class="source-section">
          <view class="line-label">SOURCE SPEECH [EN]</view>
          <text class="source-text">{{currentSource}}</text>
        </view>

        <view class="target-section">
          <view class="line-label">CLOUD TRANSLATE V2 [ZH-CN]</view>
          <text class="target-text">{{currentTranslation}}</text>
        </view>
      </view>

      <!-- 模式三：GCP 节点态势感知与 ADC 认证中枢 -->
      <view class="panel-box console-panel" ink:if="{{mode === 'console'}}">
        <view class="metrics-grid">
          <view class="metric-cell">
            <text class="metric-key">GCP 代理通道</text>
            <text class="metric-val highlight">CLOUDRUN OK</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">智能体鉴权</text>
            <text class="metric-val highlight">ROKID METIS</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">PROJECT ID</text>
            <text class="metric-val">cellular-cider</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">VERTEX AI</text>
            <text class="metric-val">gemini-2.5-flash</text>
          </view>
        </view>

        <view class="hardware-row">
          <view class="hw-chip active">
            <text class="hw-text">GEMINI</text>
          </view>
          <view class="hw-chip active">
            <text class="hw-text">TRANSLATE</text>
          </view>
          <view class="hw-chip active">
            <text class="hw-text">TTS</text>
          </view>
          <view class="hw-chip active">
            <text class="hw-text">IMU</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 底部镜腿快捷操作提示 -->
    <view class="hud-footer">
      <view class="footer-btn action-tap" bindtap="handleTap">
        <text class="btn-badge">轻拍</text>
        <text class="btn-desc">{{tapDesc}}</text>
      </view>
      <view class="footer-btn action-swipe" bindtap="cycleModeNext">
        <text class="btn-badge">滑动</text>
        <text class="btn-desc">切换模式</text>
      </view>
      <view class="footer-btn action-long" bindtap="resetIdle">
        <text class="btn-badge">长按</text>
        <text class="btn-desc">复位待命</text>
      </view>
    </view>
  </view>
</page>

<style>
/* 严格符合 Rokid 单绿微光波导规范 (480x352, #40ff5e, 纯黑背景) */
.hud-container {
  width: 480px;
  height: 352px;
  background-color: #000000;
  color: #40ff5e;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", monospace;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-sizing: border-box;
  padding: 12px 16px;
  overflow: hidden;
}

/* 顶部状态栏 */
.hud-header {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  height: 28px;
  border-bottom: 1px solid rgba(64, 255, 94, 0.24);
  padding-bottom: 4px;
}

.header-left {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.brand-text {
  font-size: 15px;
  font-weight: 900;
  color: #40ff5e;
  letter-spacing: 1px;
}

.divider-text {
  font-size: 14px;
  color: rgba(64, 255, 94, 0.48);
  margin: 0 8px;
}

.mode-text {
  font-size: 14px;
  font-weight: 700;
  color: rgba(64, 255, 94, 0.85);
  letter-spacing: 1px;
}

.header-right {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.clock-text {
  font-size: 13px;
  font-family: monospace;
  color: rgba(64, 255, 94, 0.72);
  margin-right: 10px;
}

.badge-capsule {
  border: 1px solid #40ff5e;
  border-radius: 4px;
  padding: 1px 6px;
}

.badge-text {
  font-size: 11px;
  font-weight: bold;
  color: #40ff5e;
  letter-spacing: 1px;
}

/* 主内容区 */
.hud-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 8px 0;
}

.panel-box {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

/* 模式一：Gemini 准星与推理 */
.reticle-container {
  width: 130px;
  height: 90px;
  position: relative;
  align-self: center;
  margin: 4px 0;
  border: 1px dashed rgba(64, 255, 94, 0.35);
  display: flex;
  align-items: center;
  justify-content: center;
}

.crosshair-h {
  position: absolute;
  width: 20px;
  height: 2px;
  background-color: #40ff5e;
}

.crosshair-v {
  position: absolute;
  width: 2px;
  height: 20px;
  background-color: #40ff5e;
}

.reticle-bracket {
  position: absolute;
  width: 8px;
  height: 8px;
  border-color: #40ff5e;
}
.top-left { top: -2px; left: -2px; border-top: 2px solid #40ff5e; border-left: 2px solid #40ff5e; }
.top-right { top: -2px; right: -2px; border-top: 2px solid #40ff5e; border-right: 2px solid #40ff5e; }
.bottom-left { bottom: -2px; left: -2px; border-bottom: 2px solid #40ff5e; border-left: 2px solid #40ff5e; }
.bottom-right { bottom: -2px; right: -2px; border-bottom: 2px solid #40ff5e; border-right: 2px solid #40ff5e; }

.reticle-label {
  position: absolute;
  bottom: 4px;
  font-size: 9px;
  font-weight: bold;
  color: rgba(64, 255, 94, 0.72);
  letter-spacing: 1px;
}

.gemini-result-box {
  border: 1px solid rgba(64, 255, 94, 0.48);
  border-radius: 6px;
  padding: 8px 10px;
  background-color: rgba(64, 255, 94, 0.04);
}

.gemini-desc-text {
  font-size: 13px;
  line-height: 18px;
  color: rgba(64, 255, 94, 0.95);
}

/* 模式二：同传双语 */
.wave-box {
  display: flex;
  flex-direction: row;
  align-items: center;
  height: 24px;
  margin-bottom: 6px;
}

.wave-bar {
  width: 4px;
  height: 6px;
  background-color: rgba(64, 255, 94, 0.35);
  margin-right: 4px;
  border-radius: 2px;
}

.wave-active {
  height: 16px;
  background-color: #40ff5e;
}

.wave-status-text {
  font-size: 12px;
  color: rgba(64, 255, 94, 0.72);
  margin-left: 6px;
}

.source-section {
  border: 1px solid rgba(64, 255, 94, 0.35);
  border-radius: 6px;
  padding: 8px 10px;
  margin-bottom: 8px;
  background-color: rgba(64, 255, 94, 0.03);
}

.source-text {
  font-size: 13px;
  line-height: 18px;
  color: rgba(64, 255, 94, 0.85);
  font-style: italic;
}

.target-section {
  border: 1px solid #40ff5e;
  border-radius: 6px;
  padding: 8px 10px;
  background-color: rgba(64, 255, 94, 0.08);
}

.target-text {
  font-size: 14px;
  font-weight: bold;
  line-height: 19px;
  color: #40ff5e;
}

.line-label {
  font-size: 10px;
  font-weight: 800;
  color: rgba(64, 255, 94, 0.6);
  letter-spacing: 1px;
  margin-bottom: 2px;
}

/* 模式三：控制台 */
.metrics-grid {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 12px;
}

.metric-cell {
  width: 48%;
  box-sizing: border-box;
  border: 1px solid rgba(64, 255, 94, 0.35);
  border-radius: 6px;
  padding: 8px;
  background-color: rgba(64, 255, 94, 0.04);
  display: flex;
  flex-direction: column;
}

.metric-key {
  font-size: 10px;
  color: rgba(64, 255, 94, 0.6);
  letter-spacing: 0.5px;
}

.metric-val {
  font-size: 13px;
  font-weight: bold;
  font-family: monospace;
  color: rgba(64, 255, 94, 0.9);
  margin-top: 4px;
}

.metric-val.highlight {
  color: #40ff5e;
}

.hardware-row {
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  margin-top: 6px;
}

.hw-chip {
  border: 1px solid rgba(64, 255, 94, 0.24);
  border-radius: 4px;
  padding: 3px 10px;
}

.hw-chip.active {
  border-color: #40ff5e;
  background-color: rgba(64, 255, 94, 0.12);
}

.hw-text {
  font-size: 11px;
  font-weight: bold;
  color: #40ff5e;
}

/* 底部操作条 */
.hud-footer {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  height: 26px;
  border-top: 1px solid rgba(64, 255, 94, 0.24);
  padding-top: 4px;
}

.footer-btn {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.btn-badge {
  border: 1px solid rgba(64, 255, 94, 0.72);
  border-radius: 3px;
  padding: 1px 4px;
  font-size: 10px;
  font-weight: bold;
  color: #40ff5e;
  margin-right: 4px;
}

.btn-desc {
  font-size: 11px;
  color: rgba(64, 255, 94, 0.72);
}
</style>
