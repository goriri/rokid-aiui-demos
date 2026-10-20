<script type="application/json" def>
{
  "navigationBarTitleText": "GCP Multimodal Agent",
  "description": "Google Cloud AI AR Copilot & Live Subtitle Translator"
}
</script>

<script setup>
const LOCALE = 'en';

const STRINGS = {
  en: {
    ttsLang: 'en-US',
    translateTargetLang: 'en',
    brand: 'GCP',
    modeTitles: {
      gemini: 'GEMINI 4 LIVE',
      translate: 'AR TRANSLATOR',
      console: 'CLOUD CONSOLE'
    },
    tapDescs: {
      gemini: 'Vision Q&A',
      translate: 'Next Line',
      console: 'Ping Health'
    },
    reticleLabel: 'AI TARGET ACQUISITION',
    geminiBoxLabel: 'VERTEX AI // GEMINI-4',
    geminiInitial: 'Tap temple to capture a photo; Vertex AI will analyze the target inside the reticle.',
    geminiReset: 'System reset. Tap temple to capture a photo for Vertex AI spatial reasoning.',
    geminiCapturing: 'Capturing camera frame via Rokid Glasses...',
    geminiCameraEmpty: 'No camera frame',
    geminiCameraUnavailable: 'No hardware camera',
    geminiCameraFallbackPrefix: 'Camera unavailable',
    geminiAnalyzingLive: 'ANALYZING… Frame captured; querying Vertex AI via Cloud Run (up to 25s)...',
    geminiAnalyzingSimPrefix: 'ANALYZING… Querying Vertex AI via Cloud Run (up to 25s)...',
    geminiPrompt: 'From a Rokid AR monochrome-green HUD perspective, describe the hardware or scene in the reticle in concise English under 20 words.',
    geminiTagLive: 'Live Camera',
    geminiTagSim: 'No Camera',
    geminiResultPrefix: '[Vertex AI // Cloud Run',
    geminiFallbackTag: 'OFFLINE DEMO · Cloud unreachable — showing sample result: ',
    geminiFallbackText: 'Rokid AR monochrome-green waveguide module nominal.',
    translateFallbackPrefix: 'OFFLINE DEMO · Cloud unreachable — showing sample result: ',
    translateActive: '>> GCP LIVE TRANSLATING: ZH-CN -> EN',
    translateStandby: '>> TRANSLATOR STANDBY (TAP FOR NEXT)',
    translatePending: 'Cloud Run translating to English...',
    sourceLabel: 'SOURCE SPEECH [ZH-CN]',
    targetLabel: 'CLOUD TRANSLATE V2 [EN - PRIMARY]',
    dialogues: [
      {
        source: '早上好！今天的天气非常适合开展户外实地考察。',
        target: 'Good morning! The weather today is ideal for outdoor field work.'
      },
      {
        source: '欢迎使用由 Google Cloud Vertex AI 驱动的 Rokid AR 眼镜。',
        target: 'Welcome to Rokid AR Glasses powered by Google Cloud Vertex AI.'
      },
      {
        source: '微光波导显示器在户外阳光下依然保持清晰对比度。',
        target: 'The optical waveguide display keeps crisp contrast in bright sunlight.'
      },
      {
        source: '与设计团队的下一场会议将在15分钟后开始。',
        target: 'The next meeting with the design team starts in 15 minutes.'
      }
    ],
    metricProxyKey: 'GCP PROXY',
    metricProxyVal: 'CLOUDRUN OK',
    metricAuthKey: 'AGENT AUTH',
    metricAuthVal: 'ROKID METIS',
    metricProjectKey: 'PROJECT ID',
    metricModelKey: 'VERTEX AI',
    metricModelVal: 'gemini-4-argon',
    chipGemini: 'GEMINI',
    chipTranslate: 'TRANSLATE',
    chipTts: 'TTS',
    chipImu: 'IMU',
    btnTap: 'TAP',
    btnSwipe: 'SWIPE',
    btnSwipeDesc: 'Switch Mode',
    btnHold: 'HOLD',
    btnHoldDesc: 'Reset Idle'
  },
  zh: {
    ttsLang: 'zh-CN',
    translateTargetLang: 'zh-CN',
    brand: 'GCP',
    modeTitles: {
      gemini: 'GEMINI 4 LIVE',
      translate: 'AR TRANSLATOR',
      console: 'CLOUD CONSOLE'
    },
    tapDescs: {
      gemini: '拍照推理',
      translate: '下句同传',
      console: '刷新健康'
    },
    reticleLabel: 'AI TARGET ACQUISITION',
    geminiBoxLabel: 'VERTEX AI // GEMINI-4',
    geminiInitial: '点击轻拍触发拍摄，Vertex AI 将对准星内目标进行多模态空间推理。',
    geminiReset: '系统已复位。点击轻拍触发拍摄，Vertex AI 将对准星内目标进行多模态空间推理。',
    geminiCapturing: '正在调用眼镜相机抓取视野图像...',
    geminiCameraEmpty: '相机未返回有效图像',
    geminiCameraUnavailable: '当前环境无硬件相机',
    geminiCameraFallbackPrefix: '相机抓取降级',
    geminiAnalyzingLive: 'ANALYZING… 实拍完成，正在请求 Cloud Run Vertex AI (最长 25s)...',
    geminiAnalyzingSimPrefix: 'ANALYZING… 正在请求 Cloud Run Vertex AI (最长 25s)...',
    geminiPrompt: '以AR单绿色微显示HUD的视角，用35字以内简要描述准星内检测到的Rokid硬件与工作状态。',
    geminiTagLive: '实拍多模态',
    geminiTagSim: '无相机输入',
    geminiResultPrefix: '【Vertex AI // Cloud Run',
    geminiFallbackTag: 'OFFLINE DEMO · 云端不可达 — 展示示例结果：',
    geminiFallbackText: 'Rokid AR 单绿光波导光学模组运行正常。',
    translateFallbackPrefix: 'OFFLINE DEMO · 云端不可达 — 展示示例结果：',
    translateActive: '>> GCP 同传中: EN -> ZH-CN',
    translateStandby: '>> 同传待命中 (轻拍模拟下一句)',
    translatePending: 'Cloud Run 正在实时同传...',
    sourceLabel: 'SOURCE SPEECH [EN]',
    targetLabel: 'CLOUD TRANSLATE V2 [ZH-CN]',
    dialogues: [
      {
        source: 'Good morning! The weather today is perfect for outdoor field work.',
        target: '早上好！今天的天气非常适合开展户外实地考察。'
      },
      {
        source: 'Welcome to Rokid AR Glasses powered by Google Cloud Vertex AI.',
        target: '欢迎使用由 Google Cloud Vertex AI 强力驱动的 Rokid AR 眼镜。'
      },
      {
        source: 'Optical waveguide display maintains crisp contrast in bright sunlight.',
        target: '微光波导显示器在户外阳光下依然保持清晰对比度。'
      },
      {
        source: 'Next meeting with the design team starts in 15 minutes.',
        target: '与设计团队的下一场会议将在15分钟后开始。'
      }
    ],
    metricProxyKey: 'GCP 代理通道',
    metricProxyVal: 'CLOUDRUN OK',
    metricAuthKey: '智能体鉴权',
    metricAuthVal: 'ROKID METIS',
    metricProjectKey: 'PROJECT ID',
    metricModelKey: 'VERTEX AI',
    metricModelVal: 'gemini-4-argon',
    chipGemini: 'GEMINI',
    chipTranslate: 'TRANSLATE',
    chipTts: 'TTS',
    chipImu: 'IMU',
    btnTap: '轻拍',
    btnSwipe: '滑动',
    btnSwipeDesc: '切换模式',
    btnHold: '长按',
    btnHoldDesc: '复位待命'
  }
};

const T = STRINGS[LOCALE] || STRINGS.en;
const MODES = ['gemini', 'translate', 'console'];
const MODE_TITLES = T.modeTitles;
const SAMPLE_DIALOGUES = T.dialogues;

function getFormattedTime() {
  const d = new Date();
  const pad = n => String(n).padStart(2, '0');
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

function toArrayBuffer(data) {
  if (data instanceof ArrayBuffer) return data;
  if (ArrayBuffer.isView(data)) {
    return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
  }
  return null;
}

import wx from 'wx';
import {
  GCP_CONFIG,
  registerWxRequest,
  authenticateWithProxy,
  callGeminiMultimodal,
  queryGeminiVertexAI,
  queryGoogleTranslate,
  checkGCPHealth,
  getSessionState
} from '../../gcp_config.js';

export default {
  data: {
    locale: LOCALE,
    ui: T,
    mode: 'gemini',
    modeTitle: MODE_TITLES.gemini,
    statusBadge: 'RUN.APP',
    authBadge: 'METIS OK',
    currentTime: getFormattedTime(),
    tapDesc: T.tapDescs.gemini,
    
    // Mode 1: Gemini
    geminiResult: T.geminiInitial,
    isCapturing: false,
    isBusy: false,
    cameraAvailable: false,

    // Mode 2: Translate
    currentSource: SAMPLE_DIALOGUES[0].source,
    currentTranslation: SAMPLE_DIALOGUES[0].target,
    dialogueIndex: 0,
    isTranslating: false,

    // Mode 3: Console
    healthStatus: 'HEALTHY',
    projectIdDisplay: 'cellular-cider'
  },

  async onLoad() {
    console.log('[AIUI GCP] Page Loaded, initiating Rokid AIUI authentication...');
    this.turnId = 0;
    this.currentUtterance = null;
    this.cameraContext = null;
    if (wx && typeof wx.request === 'function') {
      registerWxRequest(wx.request.bind(wx));
    }
    this.initCamera();
    this.startClock();
    try {
      const auth = await Promise.race([
        authenticateWithProxy('rokid_glasses_user_01', 'test_valid_glasses_code'),
        new Promise((_, reject) => setTimeout(() => reject(new Error('auth_timeout')), 10000))
      ]);
      if (auth && auth.success) {
        console.log('[AIUI GCP] Rokid Agent Authenticated via Cloud Run Proxy');
        this.setData({
          statusBadge: auth.simulated ? 'OFFLINE' : 'RUN.APP',
          authBadge: 'METIS OK'
        });
      }
    } catch (e) {
      console.warn('[AIUI GCP] Auth verify error:', e);
    }
  },

  initCamera() {
    const cameraAvailable = !!(wx && wx.media && typeof wx.media.createCameraContext === 'function');
    if (cameraAvailable) {
      try {
        this.cameraContext = wx.media.createCameraContext();
      } catch (_) {
        this.cameraContext = null;
      }
    }
    this.setData({ cameraAvailable: !!this.cameraContext });
  },

  onUnload() {
    ++this.turnId;
    this.stopClock();
    this.stopTtsTimer();
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

  stopTtsTimer() {
    if (this.ttsTimer) {
      clearTimeout(this.ttsTimer);
      this.ttsTimer = null;
    }
    if (this.currentUtterance) {
      this.currentUtterance.onend = null;
      this.currentUtterance.onerror = null;
      this.currentUtterance = null;
    }
  },

  finishTurn(turnId) {
    if (turnId !== undefined && turnId !== this.turnId) {
      return;
    }
    this.stopTtsTimer();
    this.setData({
      isCapturing: false,
      isTranslating: false,
      isBusy: false
    });
  },

  speakResponse(text, turnId = this.turnId) {
    const myTurnId = turnId;
    if (myTurnId !== this.turnId) {
      return;
    }
    const cleanText = String(text || '').trim();
    if (!cleanText) {
      this.finishTurn(myTurnId);
      return;
    }

    this.stopTtsTimer();
    let doneCalled = false;
    const done = () => {
      if (doneCalled) return;
      doneCalled = true;
      this.finishTurn(myTurnId);
    };

    const timeoutMs = Math.min(20000, Math.max(3000, 1500 + 220 * cleanText.length));
    this.ttsTimer = setTimeout(done, timeoutMs);

    try {
      if (typeof speechSynthesis !== 'undefined' && typeof SpeechSynthesisUtterance !== 'undefined') {
        const utterance = new SpeechSynthesisUtterance(cleanText);
        utterance.lang = T.ttsLang;
        utterance.onend = done;
        utterance.onerror = done;
        this.currentUtterance = utterance;
        speechSynthesis.speak(utterance, 'immediate');
        return;
      }
      if (typeof wx !== 'undefined' && wx && wx.speech && typeof wx.speech.playTTS === 'function') {
        wx.speech.playTTS(cleanText);
      }
    } catch (err) {
      console.warn('[AIUI GCP] TTS playback fallback error:', err);
      done();
    }
  },

  // Temple interaction dispatch (page-level callbacks; never intercept Backspace/Escape)
  onKeyDown(e) {
    const key = (e && (e.code || e.key)) || '';
    if (key === 'Backspace' || key === 'Escape' || key === 'Back' || key === 'GoBack') {
      return;
    }
  },

  onKeyUp(e) {
    const key = (e && (e.code || e.key)) || '';
    console.log('[AIUI GCP] KeyUp:', key);

    if (key === 'Backspace' || key === 'Escape' || key === 'Back' || key === 'GoBack') {
      return;
    }
    if (key === 'Enter' || key === 'Space' || key === 'GlobalHook') {
      if (e && typeof e.preventDefault === 'function') e.preventDefault();
      this.handleTap();
      return;
    }
    if (key === 'ArrowRight' || key === 'ArrowDown' || key === 'PageDown') {
      if (e && typeof e.preventDefault === 'function') e.preventDefault();
      this.cycleModeNext();
      return;
    }
    if (key === 'ArrowLeft' || key === 'ArrowUp' || key === 'PageUp') {
      if (e && typeof e.preventDefault === 'function') e.preventDefault();
      this.cycleModePrev();
      return;
    }
  },

  onVoiceWakeup(e) {
    console.log('[AIUI GCP] Voice wakeup:', e && e.keyword);
    this.handleTap();
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
    let tapDesc = T.tapDescs.gemini;
    let statusBadge = 'VERTEX';

    if (targetMode === 'translate') {
      tapDesc = T.tapDescs.translate;
      statusBadge = 'LIVE';
    } else if (targetMode === 'console') {
      tapDesc = T.tapDescs.console;
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

  // Mode 1: Camera capture -> JPEG base64 -> Cloud Run Proxy -> Vertex AI Gemini 4
  async triggerGeminiVisionCapture() {
    if (this.data.isCapturing || this.data.isTranslating || this.data.isBusy) return;

    const myTurnId = ++this.turnId;
    this.stopTtsTimer();
    this.setData({
      isCapturing: true,
      isBusy: true,
      statusBadge: 'CAM',
      geminiResult: T.geminiCapturing
    });

    let base64Image = null;
    let cameraFallbackNotice = '';

    try {
      if (!this.cameraContext && wx && wx.media && typeof wx.media.createCameraContext === 'function') {
        this.cameraContext = wx.media.createCameraContext();
      }
      if (this.cameraContext && typeof this.cameraContext.takePhoto === 'function') {
        const photo = await Promise.race([
          this.cameraContext.takePhoto({ quality: 'normal' }),
          new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 4000))
        ]);
        const buf = toArrayBuffer(photo && photo.data);
        if (buf && wx && typeof wx.arrayBufferToBase64 === 'function') {
          base64Image = wx.arrayBufferToBase64(buf);
        } else {
          cameraFallbackNotice = T.geminiCameraEmpty;
        }
      } else {
        cameraFallbackNotice = T.geminiCameraUnavailable;
      }
    } catch (camErr) {
      console.warn('[AIUI GCP] Camera takePhoto failed, falling back to simulation:', camErr);
      cameraFallbackNotice = T.geminiCameraFallbackPrefix;
    }

    if (this.turnId !== myTurnId) return;

    this.setData({
      statusBadge: 'ANALYZING…',
      geminiResult: base64Image
        ? T.geminiAnalyzingLive
        : `[${cameraFallbackNotice}] ${T.geminiAnalyzingSimPrefix}`
    });

    try {
      const answer = await Promise.race([
        callGeminiMultimodal(T.geminiPrompt, base64Image, LOCALE),
        new Promise((_, reject) => setTimeout(() => reject(new Error('gemini_timeout')), 25000))
      ]);
      if (this.turnId !== myTurnId) return;
      if (answer) {
        const cleanAnswer = answer.replace(/\*\*/g, '').trim();
        const isOfflineFallback = cleanAnswer.startsWith('OFFLINE DEMO');
        const modeTag = base64Image ? T.geminiTagLive : T.geminiTagSim;
        const alreadyTagged =
          isOfflineFallback ||
          cleanAnswer.startsWith('[Vertex AI') ||
          cleanAnswer.startsWith('【Vertex AI');
        const formattedResult = isOfflineFallback
          ? cleanAnswer
          : alreadyTagged
            ? (base64Image ? cleanAnswer : `${cleanAnswer} [${modeTag}]`)
            : `${T.geminiResultPrefix} (${modeTag})] ${cleanAnswer}`;
        this.setData({
          isCapturing: false,
          isTranslating: false,
          isBusy: false,
          statusBadge: isOfflineFallback ? 'OFFLINE' : 'RUN.APP',
          geminiResult: formattedResult
        });
        this.speakResponse(cleanAnswer, myTurnId);
        return;
      }
    } catch (err) {
      console.warn('[AIUI GCP] Cloud Run Vertex AI error, falling back:', err);
    }

    if (this.turnId !== myTurnId) return;

    const fallbackText = T.geminiFallbackText;
    this.setData({
      isCapturing: false,
      isTranslating: false,
      isBusy: false,
      statusBadge: 'OFFLINE',
      geminiResult: `${T.geminiFallbackTag}${fallbackText}`
    });
    this.speakResponse(`${T.geminiFallbackTag}${fallbackText}`, myTurnId);
  },

  async captureAndAnalyze() {
    return this.triggerGeminiVisionCapture();
  },

  // Mode 2: Live subtitle translation via Cloud Run Proxy -> Cloud Translation v2
  async triggerNextTranslation() {
    if (this.data.isTranslating || this.data.isCapturing || this.data.isBusy) return;

    const myTurnId = ++this.turnId;
    this.stopTtsTimer();
    const nextIdx = (this.data.dialogueIndex + 1) % SAMPLE_DIALOGUES.length;
    const item = SAMPLE_DIALOGUES[nextIdx];
    this.setData({
      dialogueIndex: nextIdx,
      currentSource: item.source,
      currentTranslation: T.translatePending,
      isTranslating: true,
      isBusy: true
    });

    try {
      const res = await Promise.race([
        queryGoogleTranslate(item.source, T.translateTargetLang),
        new Promise((_, reject) => setTimeout(() => reject(new Error('translate_timeout')), 10000))
      ]);
      if (this.turnId !== myTurnId) return;
      if (res && res.translated) {
        this.setData({
          currentTranslation: res.translated,
          statusBadge: res.offline ? 'OFFLINE' : 'LIVE',
          isCapturing: false,
          isTranslating: false,
          isBusy: false
        });
        this.speakResponse(res.translated, myTurnId);
        return;
      }
    } catch (err) {
      console.warn('[AIUI GCP] Cloud Run Translate error, falling back:', err);
    }

    if (this.turnId !== myTurnId) return;

    const offlineTranslation = `${T.translateFallbackPrefix}${item.target}`;
    this.setData({
      currentTranslation: offlineTranslation,
      statusBadge: 'OFFLINE',
      isCapturing: false,
      isTranslating: false,
      isBusy: false
    });
    this.speakResponse(offlineTranslation, myTurnId);
  },

  // Mode 3: Cloud Run health check
  async refreshConsoleHealth() {
    const myTurnId = ++this.turnId;
    this.setData({ statusBadge: 'PINGING' });
    try {
      const data = await Promise.race([
        checkGCPHealth(),
        new Promise((_, reject) => setTimeout(() => reject(new Error('health_timeout')), 10000))
      ]);
      if (this.turnId !== myTurnId) return;
      if (data) {
        this.setData({
          statusBadge: data.status === 'OFFLINE' ? 'OFFLINE' : 'RUN.APP',
          authBadge: 'METIS OK',
          projectIdDisplay: data.project ? data.project.substring(0, 14) : 'cellular-cider'
        });
        return;
      }
    } catch (err) {
      console.warn('[AIUI GCP] Cloud Run Health error:', err);
    }
    if (this.turnId !== myTurnId) return;
    this.setData({ statusBadge: 'OFFLINE' });
  },

  resetIdle() {
    ++this.turnId;
    this.stopTtsTimer();
    this.switchMode('gemini');
    this.setData({
      isCapturing: false,
      isTranslating: false,
      isBusy: false,
      geminiResult: T.geminiReset
    });
  }
};
</script>

<page>
  <view class="hud-container">
    <!-- Top HUD Status Bar -->
    <view class="hud-header">
      <view class="header-left">
        <text class="brand-text">{{ui.brand}}</text>
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

    <!-- Main Viewport -->
    <view class="hud-body">
      <!-- Mode 1: Vertex AI Gemini 4 Multimodal Vision -->
      <view class="panel-box gemini-panel" ink:if="{{mode === 'gemini'}}">
        <view class="reticle-container">
          <view class="crosshair-h"></view>
          <view class="crosshair-v"></view>
          <view class="reticle-bracket top-left"></view>
          <view class="reticle-bracket top-right"></view>
          <view class="reticle-bracket bottom-left"></view>
          <view class="reticle-bracket bottom-right"></view>
          <text class="reticle-label">{{ui.reticleLabel}}</text>
        </view>
        <view class="gemini-result-box">
          <view class="line-label">{{ui.geminiBoxLabel}}</view>
          <text class="gemini-desc-text">{{geminiResult}}</text>
        </view>
      </view>

      <!-- Mode 2: Google Cloud Live AR Bilingual Subtitle Translator -->
      <view class="panel-box translate-panel" ink:if="{{mode === 'translate'}}">
        <view class="wave-box">
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
          <text class="wave-status-text">
            {{isTranslating ? ui.translateActive : ui.translateStandby}}
          </text>
        </view>

        <view class="source-section">
          <view class="line-label">{{ui.sourceLabel}}</view>
          <text class="source-text">{{currentSource}}</text>
        </view>

        <view class="target-section">
          <view class="line-label">{{ui.targetLabel}}</view>
          <text class="target-text">{{currentTranslation}}</text>
        </view>
      </view>

      <!-- Mode 3: GCP Node Status & ADC Auth Console -->
      <view class="panel-box console-panel" ink:if="{{mode === 'console'}}">
        <view class="metrics-grid">
          <view class="metric-cell">
            <text class="metric-key">{{ui.metricProxyKey}}</text>
            <text class="metric-val highlight">{{ui.metricProxyVal}}</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">{{ui.metricAuthKey}}</text>
            <text class="metric-val highlight">{{ui.metricAuthVal}}</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">{{ui.metricProjectKey}}</text>
            <text class="metric-val">{{projectIdDisplay}}</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">{{ui.metricModelKey}}</text>
            <text class="metric-val">{{ui.metricModelVal}}</text>
          </view>
        </view>

        <view class="hardware-row">
          <view class="hw-chip active">
            <text class="hw-text">{{ui.chipGemini}}</text>
          </view>
          <view class="hw-chip active">
            <text class="hw-text">{{ui.chipTranslate}}</text>
          </view>
          <view class="hw-chip active">
            <text class="hw-text">{{ui.chipTts}}</text>
          </view>
          <view class="hw-chip active">
            <text class="hw-text">{{ui.chipImu}}</text>
          </view>
        </view>
      </view>
    </view>

    <!-- Bottom Temple Touchpad Hints -->
    <view class="hud-footer">
      <view class="footer-btn action-tap" bindtap="handleTap">
        <text class="btn-badge">{{ui.btnTap}}</text>
        <text class="btn-desc">{{tapDesc}}</text>
      </view>
      <view class="footer-btn action-swipe" bindtap="cycleModeNext">
        <text class="btn-badge">{{ui.btnSwipe}}</text>
        <text class="btn-desc">{{ui.btnSwipeDesc}}</text>
      </view>
      <view class="footer-btn action-long" bindtap="resetIdle">
        <text class="btn-badge">{{ui.btnHold}}</text>
        <text class="btn-desc">{{ui.btnHoldDesc}}</text>
      </view>
    </view>
  </view>
</page>

<style>
/* 严格符合 Rokid AIUI vBeta 单绿微光波导规范 (480x352, #40ff5e, 纯黑背景, 1px 线条, 2/4/6px 圆角, 字重 <=500) */
.hud-container {
  width: 480px;
  height: 352px;
  background-color: #000000;
  color: #40ff5e;
  font-family: sans-serif;
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
  font-size: 16px;
  font-weight: 500;
  color: #40ff5e;
}

.divider-text {
  font-size: 14px;
  color: rgba(64, 255, 94, 0.48);
  margin: 0 8px;
}

.mode-text {
  font-size: 14px;
  font-weight: 500;
  color: rgba(64, 255, 94, 0.72);
}

.header-right {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.clock-text {
  font-size: 13px;
  font-family: monospace;
  font-weight: 400;
  color: rgba(64, 255, 94, 0.72);
  margin-right: 10px;
}

.badge-capsule {
  border: 1px solid rgba(64, 255, 94, 0.72);
  border-radius: 4px;
  padding: 2px 6px;
}

.badge-text {
  font-size: 11px;
  font-weight: 500;
  color: #40ff5e;
}

/* 主内容区 */
.hud-body {
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 8px 0;
  overflow: hidden;
}

.panel-box {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  overflow: hidden;
}

/* 模式一：Gemini 准星与推理 */
.reticle-container {
  width: 130px;
  height: 90px;
  position: relative;
  align-self: center;
  margin: 4px 0;
  border: 1px dashed rgba(64, 255, 94, 0.24);
  border-radius: 2px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.crosshair-h {
  position: absolute;
  width: 20px;
  height: 1px;
  background-color: #40ff5e;
}

.crosshair-v {
  position: absolute;
  width: 1px;
  height: 20px;
  background-color: #40ff5e;
}

.reticle-bracket {
  position: absolute;
  width: 8px;
  height: 8px;
  border-color: #40ff5e;
}

.top-left {
  margin-right: 122px;
  margin-bottom: 82px;
  border-width: 1px 0 0 1px;
  border-style: solid;
  border-color: #40ff5e;
}

.top-right {
  margin-left: 122px;
  margin-bottom: 82px;
  border-width: 1px 1px 0 0;
  border-style: solid;
  border-color: #40ff5e;
}

.bottom-left {
  margin-right: 122px;
  margin-top: 82px;
  border-width: 0 0 1px 1px;
  border-style: solid;
  border-color: #40ff5e;
}

.bottom-right {
  margin-left: 122px;
  margin-top: 82px;
  border-width: 0 1px 1px 0;
  border-style: solid;
  border-color: #40ff5e;
}

.reticle-label {
  position: absolute;
  margin-top: 66px;
  font-size: 10px;
  font-weight: 400;
  color: rgba(64, 255, 94, 0.72);
}

.gemini-result-box {
  height: 126px;
  max-height: 126px;
  box-sizing: border-box;
  border: 1px solid rgba(64, 255, 94, 0.48);
  border-radius: 6px;
  padding: 8px 12px;
  background-color: rgba(64, 255, 94, 0.06);
  overflow: hidden;
}

.gemini-desc-text {
  font-size: 13px;
  font-weight: 400;
  line-height: 18px;
  color: rgba(64, 255, 94, 0.72);
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
  background-color: rgba(64, 255, 94, 0.24);
  margin-right: 4px;
  border-radius: 2px;
}

.wave-active {
  height: 16px;
  background-color: #40ff5e;
}

.wave-status-text {
  font-size: 12px;
  font-weight: 400;
  color: rgba(64, 255, 94, 0.72);
  margin-left: 6px;
}

.source-section {
  height: 92px;
  max-height: 92px;
  box-sizing: border-box;
  border: 1px solid rgba(64, 255, 94, 0.24);
  border-radius: 6px;
  padding: 8px 12px;
  margin-bottom: 8px;
  background-color: rgba(64, 255, 94, 0.06);
  overflow: hidden;
}

.source-text {
  font-size: 13px;
  font-weight: 400;
  line-height: 18px;
  color: rgba(64, 255, 94, 0.72);
  font-style: italic;
}

.target-section {
  height: 92px;
  max-height: 92px;
  box-sizing: border-box;
  border: 1px solid rgba(64, 255, 94, 0.72);
  border-radius: 6px;
  padding: 8px 12px;
  background-color: rgba(64, 255, 94, 0.12);
  overflow: hidden;
}

.target-text {
  font-size: 14px;
  font-weight: 500;
  line-height: 19px;
  color: #40ff5e;
}

.line-label {
  font-size: 10px;
  font-weight: 500;
  color: rgba(64, 255, 94, 0.48);
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
  border: 1px solid rgba(64, 255, 94, 0.24);
  border-radius: 6px;
  padding: 8px;
  background-color: rgba(64, 255, 94, 0.06);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.metric-key {
  font-size: 10px;
  font-weight: 400;
  color: rgba(64, 255, 94, 0.48);
}

.metric-val {
  font-size: 13px;
  font-weight: 500;
  font-family: monospace;
  color: rgba(64, 255, 94, 0.72);
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
  border-color: rgba(64, 255, 94, 0.72);
  background-color: rgba(64, 255, 94, 0.12);
}

.hw-text {
  font-size: 11px;
  font-weight: 500;
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
  border: 1px solid rgba(64, 255, 94, 0.48);
  border-radius: 4px;
  padding: 1px 4px;
  font-size: 10px;
  font-weight: 500;
  color: rgba(64, 255, 94, 0.72);
  margin-right: 4px;
}

.btn-desc {
  font-size: 11px;
  font-weight: 400;
  color: rgba(64, 255, 94, 0.72);
}
</style>
