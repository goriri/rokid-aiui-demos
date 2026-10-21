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
      translate: 'LIVE TRANSLATE',
      console: 'CLOUD CONSOLE'
    },
    tapDescs: {
      gemini: 'Vision Q&A',
      translate: 'Start Live',
      translateStop: 'Stop Live',
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
    translateStandby: '>> GEMINI LIVE STANDBY (TAP TO START)',
    translateConnecting: '>> CONNECTING GEMINI LIVE...',
    translateActive: '>> LISTENING · GEMINI-3.5-LIVE-TRANSLATE',
    translateSpeaking: '>> SPEAKING TRANSLATION...',
    translateFinishing: '>> FINISHING TURN...',
    translateErrorStatus: '>> LIVE TRANSLATION ERROR',
    translateInitialSource: 'Tap temple to start omnidirectional mic capture (16 kHz PCM).',
    translateInitialTarget: 'Gemini Live (gemini-3.5-live-translate) streams English speech & subtitles.',
    translateConnectingSource: 'Opening authenticated WebSocket to Cloud Run Gemini Live...',
    translateListeningSource: 'Listening for speech...',
    translateListeningTarget: 'Waiting for translated English stream...',
    sourceLabelPrefix: 'SOURCE SPEECH',
    targetLabel: 'GEMINI-3.5-LIVE-TRANSLATE [EN]',
    liveTranslateModel: 'gemini-3.5-live-translate',
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
      translate: 'LIVE TRANSLATE',
      console: 'CLOUD CONSOLE'
    },
    tapDescs: {
      gemini: '拍照推理',
      translate: '开始同传',
      translateStop: '停止同传',
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
    translateStandby: '>> GEMINI 同传待命 (轻拍开始)',
    translateConnecting: '>> 正在连接 GEMINI LIVE...',
    translateActive: '>> 实时拾音中 · GEMINI-3.5-LIVE-TRANSLATE',
    translateSpeaking: '>> 正在播报同传语音...',
    translateFinishing: '>> 正在完成本轮同传...',
    translateErrorStatus: '>> 实时同传连接异常',
    translateInitialSource: '轻拍镜腿启动全向麦克风实时拾音 (16 kHz PCM)。',
    translateInitialTarget: 'Gemini Live (gemini-3.5-live-translate) 实时流式输出英文语音与字幕。',
    translateConnectingSource: '正在建立 Cloud Run Gemini Live 鉴权连接...',
    translateListeningSource: '正在聆听周围语音...',
    translateListeningTarget: '等待实时英文同传输出...',
    sourceLabelPrefix: 'SOURCE SPEECH',
    targetLabel: 'GEMINI-3.5-LIVE-TRANSLATE [EN]',
    liveTranslateModel: 'gemini-3.5-live-translate',
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
const MAX_LIVE_SESSION_SECONDS = 290; // 4:50 auto-stop (under 5:00 server cap)

function getFormattedTime() {
  const d = new Date();
  const pad = n => String(n).padStart(2, '0');
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

function formatDuration(sec) {
  const s = Math.max(0, Math.floor(sec || 0));
  const mm = String(Math.floor(s / 60)).padStart(2, '0');
  const ss = String(s % 60).padStart(2, '0');
  return `${mm}:${ss}`;
}

function keepLatestSentence(rawText, maxChars = 110) {
  const clean = String(rawText || '').replace(/\s+/g, ' ').trim();
  if (!clean) return '';
  let candidate = clean;
  if (clean.length > 65) {
    const parts = clean
      .split(/(?<=[。！？.!?])\s*/)
      .map(s => s.trim())
      .filter(Boolean);
    if (parts.length > 1) {
      const last = parts[parts.length - 1];
      candidate =
        last.length < 16 && parts.length >= 2
          ? `${parts[parts.length - 2]} ${last}`.trim()
          : last;
    }
  }
  if (candidate.length > maxChars) {
    return candidate.slice(candidate.length - maxChars).trim();
  }
  return candidate;
}

function toArrayBuffer(data) {
  if (data instanceof ArrayBuffer) return data;
  if (ArrayBuffer.isView(data)) {
    return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
  }
  return null;
}

function processMicWavChunk(ab, mute = false, gain = 0.7) {
  if (!ab || ab.byteLength <= 44) return null;
  const u8 = new Uint8Array(ab, 0, 4);
  const isRiff = u8[0] === 0x52 && u8[1] === 0x49 && u8[2] === 0x46 && u8[3] === 0x46;
  const offset = isRiff ? 44 : 0;
  const usableBytes = (ab.byteLength - offset) & ~1;
  if (usableBytes <= 0) return null;
  if (mute) {
    return { buffer: new ArrayBuffer(usableBytes), peak: 0 };
  }
  const srcView = new DataView(ab, offset, usableBytes);
  const outBuf = new ArrayBuffer(usableBytes);
  const dstView = new DataView(outBuf);
  const samples = usableBytes >> 1;
  let peak = 0;
  for (let i = 0; i < samples; i++) {
    const bytePos = i * 2;
    const raw = srcView.getInt16(bytePos, true);
    let scaled = Math.round(raw * gain);
    if (scaled > 32767) scaled = 32767;
    else if (scaled < -32768) scaled = -32768;
    const abs = scaled < 0 ? -scaled : scaled;
    if (abs > peak) peak = abs;
    dstView.setInt16(bytePos, scaled, true);
  }
  return { buffer: outBuf, peak };
}

import wx from 'wx';
import {
  GCP_CONFIG,
  registerWxRequest,
  authenticateWithProxy,
  callGeminiMultimodal,
  queryGeminiVertexAI,
  buildLiveTranslateWsUrl,
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

    // Mode 2: Live Translate (Gemini Live speech-to-speech)
    currentSource: T.translateInitialSource,
    currentTranslation: T.translateInitialTarget,
    detectedSourceLang: 'AUTO',
    translateStatusText: T.translateStandby,
    sessionTimerText: '00:00',
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
    this.liveActive = false;
    this.liveStopping = false;
    this.ws = null;
    this.micStream = null;
    this.mediaRecorder = null;
    this.audioCtx = null;
    this.connectTimer = null;
    this.sessionTimer = null;
    this.stopWaitTimer = null;
    this.speakingBadgeTimer = null;
    this.nextPlayTime = 0;
    this.echoMuteUntilMs = 0;
    this.pendingPlayChunks = [];
    this.liveInputBuffer = '';
    this.liveOutputBuffer = '';
    this.turnCompletedSinceLastInput = false;
    this.turnCompletedSinceLastOutput = false;
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

  onHide() {
    if (this.liveActive) {
      this.teardownLiveSession('onHide');
    }
  },

  onUnload() {
    ++this.turnId;
    this.teardownLiveSession('onUnload');
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
      if (this.liveActive) {
        this.teardownLiveSession('back_key');
      }
      return;
    }
  },

  onKeyUp(e) {
    const key = (e && (e.code || e.key)) || '';
    console.log('[AIUI GCP] KeyUp:', key);

    if (key === 'Backspace' || key === 'Escape' || key === 'Back' || key === 'GoBack') {
      if (this.liveActive) {
        this.teardownLiveSession('back_key');
      }
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
    if (this.liveActive) {
      this.teardownLiveSession('mode_switch');
    }
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
      this.toggleLiveTranslation();
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
          // Camera capture can take >4s on device (e.g. while the HUD is being recorded); allow 12s.
          new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 12000))
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

    // Never ask the model to "describe the scene" without a real photo (it would fabricate one).
    if (!base64Image) {
      const notice = `${cameraFallbackNotice || T.geminiCameraUnavailable} · tap to retry`;
      this.setData({
        isCapturing: false,
        isTranslating: false,
        isBusy: false,
        statusBadge: 'NO CAM',
        geminiResult: notice
      });
      return;
    }

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

  // Mode 2: Real-time Speech-to-Speech Translation via Cloud Run WS -> Vertex AI Gemini Live
  toggleLiveTranslation() {
    if (this.data.isCapturing) return;
    if (this.liveActive) {
      this.stopLiveTranslation('user_tap_stop');
      return;
    }
    this.startLiveTranslation();
  },

  clearLiveTimers() {
    if (this.connectTimer) {
      clearTimeout(this.connectTimer);
      this.connectTimer = null;
    }
    if (this.sessionTimer) {
      clearInterval(this.sessionTimer);
      this.sessionTimer = null;
    }
    if (this.stopWaitTimer) {
      clearTimeout(this.stopWaitTimer);
      this.stopWaitTimer = null;
    }
    if (this.speakingBadgeTimer) {
      clearTimeout(this.speakingBadgeTimer);
      this.speakingBadgeTimer = null;
    }
    if (this.playDrainTimer) {
      clearTimeout(this.playDrainTimer);
      this.playDrainTimer = null;
    }
  },

  releaseMicOnly() {
    let released = false;
    if (this.mediaRecorder) {
      try {
        if (this.mediaRecorder.state && this.mediaRecorder.state !== 'inactive') {
          this.mediaRecorder.stop();
        }
      } catch (_) {}
      this.mediaRecorder = null;
      released = true;
    }
    if (this.micStream) {
      try {
        const tracks = this.micStream.getTracks ? this.micStream.getTracks() : [];
        for (const t of tracks) {
          t.stop();
        }
      } catch (_) {}
      this.micStream = null;
      released = true;
    }
    if (released) {
      console.log('[LiveTranslate] MIC_RELEASED');
    }
  },

  teardownLiveSession(reason = 'teardown', preserveErrorState = false) {
    const wasActive = this.liveActive;
    ++this.turnId;
    this.liveActive = false;
    this.liveStopping = false;
    this.clearLiveTimers();
    this.releaseMicOnly();

    if (this.ws) {
      const sock = this.ws;
      this.ws = null;
      try {
        sock.close(1000, reason);
      } catch (_) {}
    }

    if (this.audioCtx) {
      const ctx = this.audioCtx;
      this.audioCtx = null;
      try {
        ctx.close();
      } catch (_) {}
    }
    this.nextPlayTime = 0;
    this.echoMuteUntilMs = 0;
    this.pendingPlayChunks = [];

    if (wasActive) {
      console.log(
        `[LiveTranslate] SESSION_CLOSED reason=${reason} txChunks=${this.txChunks || 0} txBytes=${this.txBytes || 0} rxAudioChunks=${this.rxAudioChunks || 0} rxAudioBytes=${this.rxAudioBytes || 0}`
      );
    }

    if (preserveErrorState) {
      return;
    }

    if (this.data.mode === 'translate') {
      this.setData({
        isTranslating: false,
        isBusy: false,
        statusBadge: 'LIVE',
        tapDesc: T.tapDescs.translate,
        translateStatusText: T.translateStandby
      });
    } else {
      this.setData({
        isTranslating: false,
        isBusy: false
      });
    }
  },

  failLiveSession(turnId, rawReason) {
    if (turnId !== undefined && turnId !== this.turnId) return;
    const reason = String(rawReason || 'Connection failed')
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, 64);
    console.warn(`[LiveTranslate] SESSION_ERROR reason=${reason}`);
    this.teardownLiveSession('error', true);
    this.setData({
      isTranslating: false,
      isBusy: false,
      statusBadge: 'ERROR',
      tapDesc: T.tapDescs.translate,
      translateStatusText: T.translateErrorStatus,
      currentTranslation: `LIVE TRANSLATION UNAVAILABLE · ${reason}`
    });
  },

  stopLiveTranslation(reason = 'user_stop') {
    if (!this.liveActive) return;
    const myTurnId = this.turnId;

    if (this.liveStopping) {
      this.teardownLiveSession(`${reason}_immediate`);
      return;
    }

    this.liveStopping = true;
    this.releaseMicOnly();

    if (this.ws && this.ws.readyState === 1) {
      try {
        this.ws.send(JSON.stringify({ type: 'audio_stream_end' }));
        console.log(`[LiveTranslate] TX_AUDIO_STREAM_END reason=${reason} waiting for turn_complete (max 3000ms)`);
      } catch (_) {}
      this.setData({
        translateStatusText: T.translateFinishing
      });
      if (this.stopWaitTimer) clearTimeout(this.stopWaitTimer);
      this.stopWaitTimer = setTimeout(() => {
        this.stopWaitTimer = null;
        if (this.turnId === myTurnId && this.liveActive) {
          this.teardownLiveSession('stop_timeout_3s');
        }
      }, 3000);
    } else {
      this.teardownLiveSession(reason);
    }
  },

  playTranslatedPcmChunk(rawData, myTurnId) {
    if (this.turnId !== myTurnId || !this.liveActive) return;
    const ab = toArrayBuffer(rawData);
    if (!ab || ab.byteLength < 2) return;
    if (!this.pendingPlayChunks) {
      this.pendingPlayChunks = [];
    }
    if (!this.turnFirstAudioRxAt) {
      this.turnFirstAudioRxAt = Date.now();
    }
    this.pendingPlayChunks.push(ab);
    this.drainPendingPlayChunks(myTurnId);
  },

  drainPendingPlayChunks(myTurnId) {
    if (this.turnId !== myTurnId || !this.liveActive) return;
    if (!this.pendingPlayChunks || this.pendingPlayChunks.length === 0) return;

    try {
      if (!this.audioCtx) {
        this.audioCtx = new AudioContext();
      }
      if (this.audioCtx.state === 'suspended' && typeof this.audioCtx.resume === 'function') {
        this.audioCtx.resume().catch(() => {});
      }

      while (this.pendingPlayChunks.length > 0) {
        const ab = this.pendingPlayChunks.shift();
        const usableBytes = ab.byteLength & ~1;
        const sampleCount = usableBytes >> 1;
        if (sampleCount <= 0) continue;

        const view = new DataView(ab, 0, usableBytes);
        const f32 = new Float32Array(sampleCount);
        for (let i = 0; i < sampleCount; i++) {
          f32[i] = view.getInt16(i * 2, true) / 32768.0;
        }

        const srcRate = 24000;
        let audioBuffer;
        try {
          audioBuffer = this.audioCtx.createBuffer(1, sampleCount, srcRate);
          audioBuffer.copyToChannel(f32, 0);
        } catch (_) {
          const dstRate = this.audioCtx.sampleRate || 44100;
          const outLen = Math.round((sampleCount * dstRate) / srcRate);
          const resampled = new Float32Array(outLen);
          const ratio = srcRate / dstRate;
          for (let i = 0; i < outLen; i++) {
            const pos = i * ratio;
            const idx = Math.floor(pos);
            const frac = pos - idx;
            const s0 = f32[idx] || 0;
            const s1 = f32[Math.min(idx + 1, sampleCount - 1)] || 0;
            resampled[i] = s0 + (s1 - s0) * frac;
          }
          audioBuffer = this.audioCtx.createBuffer(1, outLen, dstRate);
          audioBuffer.copyToChannel(resampled, 0);
        }

        const curCtx = this.audioCtx.currentTime || 0;
        const startAt = Math.max(curCtx + 0.015, this.nextPlayTime || 0);
        const source = this.audioCtx.createBufferSource();
        source.buffer = audioBuffer;
        source.connect(this.audioCtx.destination);
        source.start(startAt);

        this.nextPlayTime = startAt + audioBuffer.duration;
        const remainingMs = Math.max(0, Math.ceil((this.nextPlayTime - curCtx) * 1000));
        this.echoMuteUntilMs = Date.now() + remainingMs + 300;
        this.rxAudioChunks = (this.rxAudioChunks || 0) + 1;
        this.rxAudioBytes = (this.rxAudioBytes || 0) + usableBytes;

        if (!this.turnFirstAudioLogged) {
          this.turnFirstAudioLogged = true;
          const refStart = this.turnVoiceStartAt || this.liveOpenedAt || Date.now();
          const firstAudioRxMs = (this.turnFirstAudioRxAt || Date.now()) - refStart;
          const firstAudioPlayMs = Date.now() - refStart;
          console.log(
            `[LiveTranslate] FIRST_AUDIO_PLAY turn=${this.liveTurnIndex || 1} chunk=${this.rxAudioChunks} bytes=${usableBytes} dur=${audioBuffer.duration.toFixed(2)}s firstAudioRxMs=${firstAudioRxMs} firstAudioLatencyMs=${firstAudioPlayMs}`
          );
        } else if (this.rxAudioChunks % 5 === 0) {
          console.log(
            `[LiveTranslate] AUDIO_PLAY chunk=${this.rxAudioChunks} totalBytes=${this.rxAudioBytes} nextPlayTime=${this.nextPlayTime.toFixed(2)}`
          );
        }
      }

      const finalNowCtx = this.audioCtx.currentTime || 0;
      const totalRemMs = Math.max(0, Math.ceil((this.nextPlayTime - finalNowCtx) * 1000));

      if (!this.liveStopping) {
        this.setData({
          statusBadge: 'SPEAKING',
          translateStatusText: T.translateSpeaking
        });
      }
      if (this.speakingBadgeTimer) {
        clearTimeout(this.speakingBadgeTimer);
      }
      this.speakingBadgeTimer = setTimeout(() => {
        this.speakingBadgeTimer = null;
        if (this.turnId !== myTurnId || !this.liveActive || this.liveStopping) return;
        this.setData({
          statusBadge: 'LIVE',
          translateStatusText: T.translateActive
        });
      }, totalRemMs + 300);
    } catch (err) {
      console.warn('[LiveTranslate] AudioContext playback error:', err && err.message ? err.message : err);
    }
  },

  async startLiveTranslation() {
    if (this.liveActive || this.data.isCapturing || this.data.isBusy) return;

    const myTurnId = ++this.turnId;
    this.stopTtsTimer();
    this.clearLiveTimers();
    this.liveActive = true;
    this.liveStopping = false;
    this.txChunks = 0;
    this.txBytes = 0;
    this.rxAudioChunks = 0;
    this.rxAudioBytes = 0;
    this.liveTurnIndex = 1;
    this.turnFirstAudioLogged = false;
    this.turnFirstAudioRxAt = 0;
    this.turnVoiceStartAt = 0;
    this.lastSpeechPeakAt = 0;
    this.lastInputTranscriptAt = 0;
    this.lastOutputTranscriptAt = 0;
    this.pendingPlayChunks = [];
    this.liveOpenedAt = 0;
    this.nextPlayTime = 0;
    this.echoMuteUntilMs = 0;
    this.pendingPlayChunks = [];
    this.lastLoggedMute = false;
    this.liveInputBuffer = '';
    this.liveOutputBuffer = '';
    this.turnCompletedSinceLastInput = false;
    this.turnCompletedSinceLastOutput = false;

    this.setData({
      isTranslating: true,
      isBusy: true,
      statusBadge: 'CONNECTING',
      tapDesc: T.tapDescs.translateStop,
      translateStatusText: T.translateConnecting,
      sessionTimerText: '00:00',
      detectedSourceLang: 'AUTO',
      currentSource: T.translateConnectingSource,
      currentTranslation: T.translateListeningTarget
    });

    let stream = null;
    try {
      if (!navigator || !navigator.mediaDevices || typeof navigator.mediaDevices.getUserMedia !== 'function') {
        throw new Error('Microphone API unavailable');
      }
      stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: 16000,
          channelCount: 1,
          microphoneMode: 'omnidirectional',
          echoCancellation: false
        }
      });
    } catch (micErr) {
      if (this.turnId !== myTurnId) return;
      this.failLiveSession(myTurnId, (micErr && micErr.message) || 'Mic permission or hardware error');
      return;
    }

    if (this.turnId !== myTurnId || !this.liveActive) {
      try {
        for (const t of stream.getTracks()) t.stop();
      } catch (_) {}
      return;
    }
    this.micStream = stream;

    let wsUrl = '';
    try {
      wsUrl = await Promise.race([
        buildLiveTranslateWsUrl(T.translateTargetLang),
        new Promise((_, reject) => setTimeout(() => reject(new Error('Auth timeout')), 10000))
      ]);
    } catch (authErr) {
      if (this.turnId !== myTurnId) return;
      this.failLiveSession(myTurnId, (authErr && authErr.message) || 'Auth failed');
      return;
    }

    if (this.turnId !== myTurnId || !this.liveActive) {
      this.releaseMicOnly();
      return;
    }

    try {
      this.audioCtx = new AudioContext();
      if (this.audioCtx.state === 'suspended' && typeof this.audioCtx.resume === 'function') {
        this.audioCtx.resume().catch(() => {});
      }
    } catch (ctxErr) {
      console.warn('[LiveTranslate] AudioContext init warning:', ctxErr);
    }

    let ws;
    try {
      ws = new WebSocket(wsUrl);
      ws.binaryType = 'arraybuffer';
    } catch (wsErr) {
      this.failLiveSession(myTurnId, (wsErr && wsErr.message) || 'WebSocket init error');
      return;
    }
    this.ws = ws;

    const redactedUrl = wsUrl.replace(/token=[^&]+/, 'token=REDACTED');
    console.log(`[LiveTranslate] WS_CONNECTING url=${redactedUrl}`);

    this.connectTimer = setTimeout(() => {
      this.connectTimer = null;
      if (this.turnId === myTurnId && this.liveActive && (!this.ws || this.ws.readyState !== 1)) {
        this.failLiveSession(myTurnId, 'Connection timeout');
      }
    }, 12000);

    ws.addEventListener('open', () => {
      if (this.turnId !== myTurnId || !this.liveActive) return;
      if (this.connectTimer) {
        clearTimeout(this.connectTimer);
        this.connectTimer = null;
      }
      this.liveOpenedAt = Date.now();
      console.log(`[LiveTranslate] WS_OPEN url=${redactedUrl}`);

      try {
        const mr = new MediaRecorder(this.micStream, { mimeType: 'audio/wav' });
        this.mediaRecorder = mr;
        mr.addEventListener('dataavailable', async ev => {
          if (this.turnId !== myTurnId || !this.liveActive || this.liveStopping) return;
          if (!ev || !ev.data || typeof ev.data.arrayBuffer !== 'function') return;
          try {
            const ab = await ev.data.arrayBuffer();
            if (this.turnId !== myTurnId || !this.liveActive || this.liveStopping) return;
            if (!this.ws || this.ws.readyState !== 1) return;

            const isEchoMuted =
              (this.audioCtx && this.nextPlayTime && this.audioCtx.currentTime < this.nextPlayTime + 0.3) ||
              Date.now() < (this.echoMuteUntilMs || 0);
            const processed = processMicWavChunk(ab, isEchoMuted, 0.7);
            if (!processed) return;

            this.ws.send(processed.buffer);
            this.txChunks = (this.txChunks || 0) + 1;
            this.txBytes = (this.txBytes || 0) + processed.buffer.byteLength;

            if (!isEchoMuted && processed.peak > 9500) {
              this.lastSpeechPeakAt = Date.now();
              if (!this.turnVoiceStartAt) {
                this.turnVoiceStartAt = Date.now();
                console.log(`[LiveTranslate] VOICE_START turn=${this.liveTurnIndex} chunk=${this.txChunks} peak=${processed.peak}`);
              }
            }

            if (this.txChunks === 1 || this.txChunks % 10 === 0 || isEchoMuted !== this.lastLoggedMute) {
              this.lastLoggedMute = isEchoMuted;
              console.log(
                `[LiveTranslate] TX_PCM chunk=${this.txChunks} bytes=${processed.buffer.byteLength} totalBytes=${this.txBytes} peak=${processed.peak} echoMuted=${isEchoMuted}`
              );
            }
          } catch (chunkErr) {
            console.warn('[LiveTranslate] Mic chunk error:', chunkErr && chunkErr.message ? chunkErr.message : chunkErr);
          }
        });
        mr.start(100);
        console.log('[LiveTranslate] MIC_STARTED mode=omnidirectional sr=16000 sliceMs=100 gain=0.7');
      } catch (mrErr) {
        this.failLiveSession(myTurnId, (mrErr && mrErr.message) || 'MediaRecorder error');
        return;
      }

      this.sessionTimer = setInterval(() => {
        if (this.turnId !== myTurnId || !this.liveActive) return;
        const elapsedSec = Math.floor((Date.now() - this.liveOpenedAt) / 1000);
        this.setData({
          sessionTimerText: formatDuration(elapsedSec)
        });
        if (elapsedSec >= MAX_LIVE_SESSION_SECONDS) {
          console.log('[LiveTranslate] AUTO_STOP at 04:50 session limit');
          this.stopLiveTranslation('max_session_4m50s');
        }
      }, 1000);

      this.setData({
        statusBadge: 'LIVE',
        translateStatusText: T.translateActive,
        currentSource: T.translateListeningSource,
        currentTranslation: T.translateListeningTarget
      });
    });

    ws.addEventListener('message', ev => {
      if (this.turnId !== myTurnId || !this.liveActive) return;
      const data = ev && ev.data;
      if (!data) return;

      if (data instanceof ArrayBuffer || ArrayBuffer.isView(data)) {
        this.playTranslatedPcmChunk(data, myTurnId);
        return;
      }

      if (typeof data === 'string') {
        let evt;
        try {
          evt = JSON.parse(data);
        } catch (_) {
          return;
        }

        if (evt.type === 'input_transcript' && typeof evt.text === 'string') {
          const nowIn = Date.now();
          if (this.turnCompletedSinceLastInput || (this.lastInputTranscriptAt && nowIn - this.lastInputTranscriptAt > 2500)) {
            if (!this.turnCompletedSinceLastInput && this.liveInputBuffer) {
              this.liveTurnIndex = (this.liveTurnIndex || 1) + 1;
              this.turnFirstAudioLogged = false;
              this.turnFirstAudioRxAt = 0;
              this.turnCompletedSinceLastOutput = true;
            }
            this.liveInputBuffer = '';
            this.turnCompletedSinceLastInput = false;
          }
          this.lastInputTranscriptAt = nowIn;
          this.liveInputBuffer += evt.text;
          const langCode = evt.languageCode
            ? String(evt.languageCode).toUpperCase()
            : this.data.detectedSourceLang || 'AUTO';
          const displaySource = keepLatestSentence(this.liveInputBuffer, 110);
          console.log(
            `[LiveTranslate] RX_INPUT_TRANSCRIPT lang=${langCode} chunk=${JSON.stringify(evt.text)} full=${JSON.stringify(this.liveInputBuffer)}`
          );
          this.setData({
            detectedSourceLang: langCode,
            currentSource: displaySource || this.liveInputBuffer
          });
          return;
        }

        if (evt.type === 'output_transcript' && typeof evt.text === 'string') {
          const nowOut = Date.now();
          if (this.turnCompletedSinceLastOutput || (this.lastOutputTranscriptAt && nowOut - this.lastOutputTranscriptAt > 2500)) {
            this.liveOutputBuffer = '';
            this.turnCompletedSinceLastOutput = false;
          }
          this.lastOutputTranscriptAt = nowOut;
          this.liveOutputBuffer += evt.text;
          const displayTarget = keepLatestSentence(this.liveOutputBuffer, 110);
          console.log(
            `[LiveTranslate] RX_OUTPUT_TRANSCRIPT lang=${evt.languageCode || 'en'} chunk=${JSON.stringify(evt.text)} full=${JSON.stringify(this.liveOutputBuffer)}`
          );
          this.setData({
            currentTranslation: displayTarget || this.liveOutputBuffer
          });
          return;
        }

        if (evt.type === 'turn_complete') {
          const completedTurn = this.liveTurnIndex || 1;
          this.liveTurnIndex = completedTurn + 1;
          this.turnCompletedSinceLastInput = true;
          this.turnCompletedSinceLastOutput = true;
          this.turnFirstAudioLogged = false;
          this.turnFirstAudioRxAt = 0;
          this.turnVoiceStartAt = 0;
          this.silentFlushCount = 0;
          console.log(
            `[LiveTranslate] RX_TURN_COMPLETE turn=${completedTurn} stopping=${!!this.liveStopping} in=${JSON.stringify(this.liveInputBuffer)} out=${JSON.stringify(this.liveOutputBuffer)}`
          );
          if (this.liveStopping) {
            if (this.stopWaitTimer) {
              clearTimeout(this.stopWaitTimer);
              this.stopWaitTimer = null;
            }
            const nowCtx = (this.audioCtx && this.audioCtx.currentTime) || 0;
            const remAudioMs =
              this.nextPlayTime > nowCtx
                ? Math.min(2000, Math.ceil((this.nextPlayTime - nowCtx) * 1000) + 120)
                : 0;
            if (remAudioMs > 50) {
              this.stopWaitTimer = setTimeout(() => {
                this.stopWaitTimer = null;
                if (this.turnId === myTurnId && this.liveActive) {
                  this.teardownLiveSession('turn_complete_after_stop');
                }
              }, remAudioMs);
            } else {
              this.teardownLiveSession('turn_complete_after_stop');
            }
          }
          return;
        }

        if (evt.type === 'error') {
          this.failLiveSession(myTurnId, evt.message || evt.code || 'Live translation error');
        }
      }
    });

    ws.addEventListener('error', ev => {
      if (this.turnId !== myTurnId || !this.liveActive) return;
      const msg = (ev && ev.message) || 'WebSocket connection failed';
      console.warn(`[LiveTranslate] WS_ERROR msg=${msg}`);
      this.failLiveSession(myTurnId, msg);
    });

    ws.addEventListener('close', ev => {
      if (this.turnId !== myTurnId || !this.liveActive) return;
      const code = (ev && ev.code) || 0;
      const reason = (ev && ev.reason) || '';
      console.log(`[LiveTranslate] WS_CLOSE code=${code} reason=${reason} stopping=${!!this.liveStopping}`);
      if (this.liveStopping) {
        this.teardownLiveSession(`ws_closed_${code}`);
      } else {
        this.failLiveSession(myTurnId, reason || `Connection closed (${code || 'network'})`);
      }
    });
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
    this.teardownLiveSession('reset_idle');
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

      <!-- Mode 2: Google Cloud Gemini Live Speech-to-Speech Translator -->
      <view class="panel-box translate-panel" ink:if="{{mode === 'translate'}}">
        <view class="wave-box">
          <view class="wave-left">
            <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
            <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
            <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
            <view class="wave-bar {{isTranslating ? 'wave-active' : ''}}"></view>
            <text class="wave-status-text">{{translateStatusText}}</text>
          </view>
          <text class="session-timer-text">{{sessionTimerText}}</text>
        </view>

        <view class="source-section">
          <view class="line-label">{{ui.sourceLabelPrefix}} [{{detectedSourceLang}}]</view>
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
  justify-content: space-between;
  align-items: center;
  height: 24px;
  margin-bottom: 6px;
}

.wave-left {
  display: flex;
  flex-direction: row;
  align-items: center;
  overflow: hidden;
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

.session-timer-text {
  font-size: 11px;
  font-family: monospace;
  font-weight: 400;
  color: rgba(64, 255, 94, 0.72);
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
