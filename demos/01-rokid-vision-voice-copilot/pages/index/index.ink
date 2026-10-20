<script type="application/json" def>
{
  "navigationBarTitleText": "Vision Voice Copilot",
  "description": "Hands-free AI copilot for Rokid Glasses HUD with voice Q&A, camera scene analysis, and IMU telemetry"
}
</script>

<script setup>
import wx from 'wx';
import { LanguageModel } from 'language-model';

const STREAM_POLL_MS = 20;
const ASR_IDLE_TIMEOUT_MS = 6000;
const VISION_PROXY_URL = 'https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app';
const VISION_AUTH_TIMEOUT_MS = 10000;
const VISION_REQUEST_TIMEOUT_MS = 25000;
const LOCALE = 'en';

let visionSessionToken = null;

function requestProxyJson(url, { method = 'GET', headers = {}, body = null, timeoutMs = 10000 } = {}) {
  if (wx && typeof wx.request === 'function') {
    return new Promise((resolve, reject) => {
      let settled = false;
      const timer = setTimeout(() => {
        if (settled) return;
        settled = true;
        reject(new Error(`Request timeout after ${timeoutMs}ms`));
      }, timeoutMs + 500);

      try {
        wx.request({
          url,
          method,
          header: headers,
          data: body !== null ? body : undefined,
          timeout: timeoutMs,
          responseType: 'text',
          dataType: 'json',
          success(res) {
            if (settled) return;
            settled = true;
            clearTimeout(timer);
            const status = typeof res.statusCode === 'number' ? res.statusCode : 200;
            let data = res.data;
            if (typeof data === 'string') {
              try {
                data = JSON.parse(data);
              } catch (_) {}
            }
            resolve({ ok: status >= 200 && status < 300, status, data });
          },
          fail(err) {
            if (settled) return;
            settled = true;
            clearTimeout(timer);
            reject(new Error((err && err.errMsg) || `Request failed (${url})`));
          }
        });
      } catch (err) {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        reject(err);
      }
    });
  }

  let timer = null;
  const timeoutPromise = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`Request timeout after ${timeoutMs}ms`)), timeoutMs);
  });
  return Promise.race([
    fetch(url, {
      method,
      headers,
      body: body !== null ? (typeof body === 'string' ? body : JSON.stringify(body)) : undefined
    }).then(async (res) => ({
      ok: res.ok,
      status: res.status,
      data: await res.json().catch(() => ({}))
    })),
    timeoutPromise
  ]).finally(() => {
    if (timer) clearTimeout(timer);
  });
}

async function authenticateVisionProxy() {
  try {
    const res = await requestProxyJson(`${VISION_PROXY_URL}/api/auth/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: {
        accountId: 'rokid_glasses_user_01',
        code: 'test_valid_glasses_code'
      },
      timeoutMs: VISION_AUTH_TIMEOUT_MS
    });
    if (res.ok && res.data && res.data.success && res.data.sessionToken) {
      visionSessionToken = res.data.sessionToken;
      return true;
    }
  } catch (err) {
    console.warn('[AIUI] Vision proxy auth error:', err && err.message ? err.message : err);
  }
  return false;
}

async function analyzeImageWithCloudProxy(prompt, base64Img, mimeType = 'image/webp') {
  if (!visionSessionToken) {
    const ok = await authenticateVisionProxy();
    if (!ok) {
      throw new Error('Vision proxy auth unreachable');
    }
  }
  const headers = { 'Content-Type': 'application/json' };
  if (visionSessionToken) {
    headers['Authorization'] = `Bearer ${visionSessionToken}`;
  }
  const res = await requestProxyJson(`${VISION_PROXY_URL}/api/gemini`, {
    method: 'POST',
    headers,
    body: {
      prompt,
      imageBase64: base64Img,
      base64Image: base64Img,
      mimeType
    },
    timeoutMs: VISION_REQUEST_TIMEOUT_MS
  });
  if (res.ok && res.data && res.data.answer) {
    return String(res.data.answer)
      .replace(/\*\*/g, '')
      .replace(/^\[[^\]]+\]\s*/, '')
      .replace(/^【[^】]+】\s*/, '')
      .trim();
  }
  throw new Error(`Vision proxy HTTP ${res.status}`);
}

const STRINGS = {
  en: {
    speechLang: 'en-US',
    systemPrompt:
      'You are a Vision & Voice Copilot on Rokid Glasses AR monochrome-green HUD. ' +
      'Answer in natural, concise English within 25 words for quick HUD reading and voice playback.',
    visionPrompt:
      'Describe the real objects and lighting visible in this camera photo in plain English within 15 words. No markdown or tags.',
    brandTag: 'ROKID',
    waveListening: '>> Listening...',
    waveThinking: '>> Thinking...',
    waveSpeaking: '>> Speaking...',
    waveIdle: '>> Standby',
    userInputLabel: 'USER INPUT',
    waitingInput: 'Waiting for voice input...',
    listeningPrompt: 'Listening for your command...',
    aiAgentLabel: 'AI AGENT',
    initialAnswer: 'Hello! I am your Vision & Voice Copilot. Tap the temple or say "Hi Rokid" to ask a question.',
    thinkingText: 'Thinking...',
    doneFallback: 'Done.',
    errorPrefix: 'Request failed, please try again.',
    unknownError: 'unknown error',
    mockQueries: [
      '[OFFLINE SAMPLE] What should I wear today?',
      '[OFFLINE SAMPLE] Explain optical waveguide AR glasses in one sentence.',
      '[OFFLINE SAMPLE] Help me plan a focused morning work schedule.'
    ],
    offlineSampleAnswer:
      '[OFFLINE SAMPLE] Cloud ASR/LLM unreachable. Wear a breathable layered jacket and comfortable walking shoes.',
    offlineReplyPrefix: '[OFFLINE SAMPLE] Recorded "',
    offlineReplySuffix: '" — connect LLM for live reply.',
    reticleLabel: 'AI TARGET ACQUISITION',
    sceneLabel: 'SCENE RECOGNITION // GEMINI-4',
    initialVision: 'Aim at a target and tap the temple to analyze the scene ahead.',
    capturingVision: 'Capturing scene frame...',
    analyzingVision: 'ANALYZING… Querying Gemini 4 vision (up to 25s)...',
    mockVisionAnswer: '[OFFLINE SAMPLE] Camera/vision proxy unavailable; showing sample desk scene.',
    visionUnrecognized: 'No specific object identified.',
    visionErrorFallback: '[OFFLINE SAMPLE] Vision proxy unreachable; showing sample status.',
    visionErrorTts: 'Offline sample: vision service unavailable in current environment.',
    metricPitch: 'PITCH',
    metricRoll: 'ROLL',
    metricSteps: 'STEPS',
    metricFps: 'FPS',
    keyTap: 'TAP',
    hintVision: 'Capture',
    hintVoice: 'Voice Q&A',
    keySwipe: 'SWIPE',
    hintSwitch: 'Switch View',
    keyHold: 'HOLD',
    hintStandby: 'Stop / Idle'
  },
  zh: {
    speechLang: 'zh-CN',
    systemPrompt:
      '你是运行在 Rokid Glasses AR 智能眼镜上的随身眼脑助手。' +
      '用户佩戴单绿光波导透明眼镜，视野极为珍贵。' +
      '请以极度精炼、口语自然、重点前置的中文回答，字数严格控制在 50 字以内，适合瞬间扫读和语音播报。',
    visionPrompt: '简要描述你看到的物体或场景，限制30字以内。',
    brandTag: 'ROKID',
    waveListening: '>> 正在拾音...',
    waveThinking: '>> 思考推演中...',
    waveSpeaking: '>> 语音播报中...',
    waveIdle: '>> 待命状态',
    userInputLabel: 'USER INPUT',
    waitingInput: '等待输入中...',
    listeningPrompt: '正在聆听您的指令...',
    aiAgentLabel: 'AI AGENT',
    initialAnswer: '你好！我是随身眼脑助手。轻拍镜腿或说“Hi Rokid”即可向我提问。',
    thinkingText: '思考中...',
    doneFallback: '已处理完成。',
    errorPrefix: '处理异常，请稍后再试。',
    unknownError: '未知错误',
    mockQueries: [
      '[示例] 今天天气如何，适合户外徒步吗？',
      '[示例] 请用两句话介绍一下光波导 AR 眼镜的原理。',
      '[示例] 帮我安排一个高效的工作日程。',
      '[示例] 眼前这是一道名画，请问它的艺术风格是什么？'
    ],
    offlineReplyPrefix: '[离线示例] 已记录“',
    offlineReplySuffix: '”——连接大模型后获取实时回答。',
    reticleLabel: 'AI TARGET ACQUISITION',
    sceneLabel: 'SCENE RECOGNITION // GEMINI-4',
    initialVision: '对准目标轻拍镜腿，我将为您分析眼前的景象。',
    capturingVision: '正在抓取视野图像...',
    analyzingVision: '正在由 Gemini 4 解析视野画面...',
    mockVisionAnswer: '[离线示例] 相机或大模型未就绪，当前展示示例桌面场景。',
    visionUnrecognized: '未能识别具体物体。',
    visionErrorFallback: '[离线示例] 当前环境不支持实拍采样，展示离线示例结果。',
    visionErrorTts: '离线示例：当前环境不支持相机实拍。',
    metricPitch: 'PITCH 角',
    metricRoll: 'ROLL 角',
    metricSteps: '步数统计',
    metricFps: 'FPS 刷新',
    keyTap: '轻拍',
    hintVision: '拍照识图',
    hintVoice: '语音交互',
    keySwipe: '滑动',
    hintSwitch: '切换视图',
    keyHold: '长按',
    hintStandby: '打断/待命'
  }
};

const T = STRINGS[LOCALE] || STRINGS.en;
const SPEECH_LANG = T.speechLang;
const SYSTEM_PROMPT = T.systemPrompt;

function formatClock() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function normalizeText(v) {
  if (typeof v !== 'string') return '';
  return v.replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim();
}

function toArrayBuffer(data) {
  if (data instanceof ArrayBuffer) return data;
  if (ArrayBuffer.isView(data)) {
    return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
  }
  return null;
}

export default {
  data: {
    i18n: T,
    status: 'idle',           // idle | listening | thinking | speaking | capturing | error
    statusBadge: 'IDLE',
    mode: 'chat',             // chat | vision | dashboard
    clock: '--:--:--',
    liveTranscript: '',
    lastQuery: '',
    lastAnswer: T.initialAnswer,
    isBusy: false,
    errorMessage: '',

    // 硬件可用性标志
    llmAvailable: false,
    recognitionAvailable: false,
    ttsAvailable: false,
    cameraAvailable: false,

    // 仪表盘态势数据
    pitch: 0,
    roll: 0,
    steps: 1248,
    fps: 60,

    // 视觉检测提示
    visionResult: T.initialVision
  },

  async onLoad() {
    this.session = null;
    this.recognition = null;
    this.cameraContext = null;
    this.gyroscope = null;
    this.clockTimer = null;
    this.asrTimer = null;
    this.asrStopTimer = null;
    this.ttsTimer = null;
    this.ttsFinishResolver = null;
    this.currentTurnId = 0;

    // 启动 HUD 顶部时钟
    this.setData({ clock: formatClock() });
    this.clockTimer = setInterval(() => {
      this.setData({ clock: formatClock() });
    }, 1000);

    // 检测硬件环境
    await this.initEnvironment();

    // 预热云端视觉代理鉴权（非阻塞）
    authenticateVisionProxy();

    // 初始化姿态感知
    this.initSensors();
  },

  onUnload() {
    if (this.clockTimer) {
      clearInterval(this.clockTimer);
      this.clockTimer = null;
    }
    this.clearAsrTimer();
    this.clearAsrStopTimer();
    this.cancelRecognition();
    this.cancelSpeech();
    this.stopSensors();
    if (this.session) {
      try {
        this.session.destroy();
      } catch (_) {}
      this.session = null;
    }
  },

  /**
   * 原生语音唤醒词触发
   */
  onVoiceWakeup(event) {
    console.log('[AIUI] Voice Wakeup triggered:', event);
    this.startVoiceTurn();
  },

  onKeyDown(event) {
    const code = (event && (event.code || event.key)) || '';
    if (code === 'Backspace' || code === 'Escape' || code === 'GoBack') {
      return;
    }
  },

  /**
   * 镜腿物理按键 / 触控板事件捕获
   */
  onKeyUp(event) {
    const code = (event && (event.code || event.key)) || '';
    if (code === 'Backspace' || code === 'Escape' || code === 'GoBack') {
      return;
    }
    console.log('[AIUI] Key/Touch Event:', code);

    // 单击/轻拍: Enter 或 GlobalHook 或 Space
    if (code === 'Enter' || code === 'GlobalHook' || code === 'Space') {
      if (event && typeof event.preventDefault === 'function') {
        event.preventDefault();
      }
      this.handleTempleTap();
      return;
    }

    // 滑动切换页面模式 (ArrowRight / ArrowLeft / ArrowDown / ArrowUp / PageDown / PageUp)
    if (code === 'ArrowRight' || code === 'PageDown' || code === 'ArrowDown') {
      if (event && typeof event.preventDefault === 'function') {
        event.preventDefault();
      }
      this.cycleMode(1);
    } else if (code === 'ArrowLeft' || code === 'PageUp' || code === 'ArrowUp') {
      if (event && typeof event.preventDefault === 'function') {
        event.preventDefault();
      }
      this.cycleMode(-1);
    }
  },

  cycleModeNext() {
    this.cycleMode(1);
  },

  cycleModePrev() {
    this.cycleMode(-1);
  },

  resetIdle() {
    this.currentTurnId++;
    this.cancelRecognition();
    this.cancelSpeech();
    this.clearAsrTimer();
    this.clearAsrStopTimer();
    this.setStatus('idle', 'IDLE');
  },

  handleTempleTap() {
    // 若正在播报，轻拍打断 TTS
    if (this.data.status === 'speaking') {
      this.cancelSpeech();
      this.setStatus('idle', 'IDLE');
      return;
    }

    // 若正在聆听，轻拍立即停止并发送
    if (this.data.status === 'listening') {
      this.stopVoiceListening();
      return;
    }

    // 视觉模式下，轻拍触发拍照
    if (this.data.mode === 'vision') {
      this.captureAndAnalyze();
      return;
    }

    // 默认或对话模式下，轻拍启动语音输入
    this.startVoiceTurn();
  },

  cycleMode(delta) {
    if (this.data.status === 'speaking') {
      this.cancelSpeech();
      this.setStatus('idle', 'IDLE');
    }
    const modes = ['chat', 'vision', 'dashboard'];
    const idx = modes.indexOf(this.data.mode);
    const nextIdx = (idx + delta + modes.length) % modes.length;
    const nextMode = modes[nextIdx];
    console.log('[AIUI] Switching mode from', this.data.mode, 'to', nextMode);
    this.setData({ mode: nextMode });
  },

  switchMode(target) {
    this.setData({ mode: target });
  },

  async initEnvironment() {
    const recognitionAvailable = typeof SpeechRecognition !== 'undefined';
    const ttsAvailable = 
      (typeof speechSynthesis !== 'undefined' && typeof speechSynthesis.speak === 'function') ||
      !!(wx && wx.speech && typeof wx.speech.playTTS === 'function');

    this.cameraContext = null;
    if (wx && wx.media && typeof wx.media.createCameraContext === 'function') {
      try {
        this.cameraContext = wx.media.createCameraContext() || null;
      } catch (_) {
        this.cameraContext = null;
      }
    }
    const cameraAvailable = !!this.cameraContext;

    let llmAvailable = false;
    try {
      if (typeof LanguageModel !== 'undefined' && typeof LanguageModel.availability === 'function') {
        const state = await LanguageModel.availability();
        llmAvailable = state === 'available';
      }
    } catch (_) {}

    this.setData({
      recognitionAvailable,
      ttsAvailable,
      cameraAvailable,
      llmAvailable
    });
  },

  initSensors() {
    try {
      if (typeof Gyroscope !== 'undefined') {
        this.gyroscope = new Gyroscope({ frequency: 5 });
        this.gyroscope.addEventListener('reading', (e) => {
          const pitch = Math.round((e.x || 0) * 10) / 10;
          const roll = Math.round((e.y || 0) * 10) / 10;
          this.setData({ pitch, roll });
        });
        this.gyroscope.start();
      }
    } catch (_) {}
  },

  stopSensors() {
    if (this.gyroscope) {
      try {
        this.gyroscope.stop();
      } catch (_) {}
      this.gyroscope = null;
    }
  },

  async ensureLLMSession() {
    if (this.session) return this.session;
    try {
      this.session = await LanguageModel.create({
        initialPrompts: [{ role: 'system', content: SYSTEM_PROMPT }]
      });
      return this.session;
    } catch (err) {
      console.warn('[AIUI] Local LanguageModel fallback:', err);
      return null;
    }
  },

  setStatus(status, badge) {
    this.setData({
      status,
      statusBadge: badge,
      isBusy: status !== 'idle' && status !== 'error'
    });
  },

  clearAsrTimer() {
    if (this.asrTimer) {
      clearTimeout(this.asrTimer);
      this.asrTimer = null;
    }
  },

  clearAsrStopTimer() {
    if (this.asrStopTimer) {
      clearTimeout(this.asrStopTimer);
      this.asrStopTimer = null;
    }
  },

  startVoiceTurn() {
    if (this.data.isBusy && this.data.status !== 'listening') return;
    this.cancelSpeech();
    this.clearAsrTimer();
    this.clearAsrStopTimer();

    if (!this.data.recognitionAvailable) {
      // 仿真或无ASR环境降级：模拟提问触发 LLM 闭环
      this.simulateVoiceTurn();
      return;
    }

    try {
      this.disposeRecognition();
      const recognition = new SpeechRecognition();
      recognition.lang = SPEECH_LANG;
      recognition.continuous = false;
      recognition.interimResults = true;

      recognition.onstart = () => {
        if (this.recognition !== recognition) return;
        this.setStatus('listening', 'REC');
        this.setData({ liveTranscript: T.listeningPrompt });
        this.asrTimer = setTimeout(() => {
          this.stopVoiceListening();
        }, ASR_IDLE_TIMEOUT_MS);
      };

      recognition.onresult = (e) => {
        if (this.recognition !== recognition) return;
        const results = e && e.results ? e.results : [];
        let text = '';
        for (let i = 0; i < results.length; i++) {
          if (results[i][0] && results[i][0].transcript) {
            text += results[i][0].transcript;
          }
        }
        if (text) {
          this.setData({ liveTranscript: text });
        }
      };

      recognition.onerror = (e) => {
        if (this.recognition !== recognition) return;
        console.warn('[AIUI] ASR Error fallback to simulation:', e);
        this.clearAsrTimer();
        this.clearAsrStopTimer();
        this.disposeRecognition();
        this.simulateVoiceTurn();
      };

      recognition.onend = () => {
        if (this.recognition !== recognition) return;
        const query = normalizeText(this.data.liveTranscript);
        this.clearAsrTimer();
        this.clearAsrStopTimer();
        this.recognition = null;
        if (query && query !== T.listeningPrompt) {
          this.executeLLMQuery(query);
        } else {
          this.simulateVoiceTurn();
        }
      };

      this.recognition = recognition;
      recognition.start();
    } catch (err) {
      console.error('[AIUI] startRecognition failed:', err);
      this.disposeRecognition();
      this.simulateVoiceTurn();
    }
  },

  stopVoiceListening() {
    this.clearAsrTimer();
    this.clearAsrStopTimer();
    const activeRec = this.recognition;
    if (!activeRec) {
      if (this.data.status === 'listening') {
        const query = normalizeText(this.data.liveTranscript);
        if (query && query !== T.listeningPrompt) {
          this.executeLLMQuery(query);
        } else {
          this.simulateVoiceTurn();
        }
      }
      return;
    }

    let settled = false;
    const fallbackToIdle = () => {
      if (settled) return;
      settled = true;
      this.clearAsrStopTimer();
      if (this.recognition === activeRec) {
        this.disposeRecognition();
      }
      if (this.data.status === 'listening') {
        const query = normalizeText(this.data.liveTranscript);
        if (query && query !== T.listeningPrompt) {
          this.executeLLMQuery(query);
        } else {
          this.simulateVoiceTurn();
        }
      }
    };

    this.asrStopTimer = setTimeout(fallbackToIdle, 800);
    try {
      activeRec.stop();
    } catch (_) {
      fallbackToIdle();
    }
  },

  disposeRecognition() {
    this.clearAsrStopTimer();
    if (this.recognition) {
      const prev = this.recognition;
      this.recognition = null;
      prev.onstart = null;
      prev.onresult = null;
      prev.onerror = null;
      prev.onend = null;
      try {
        prev.abort();
      } catch (_) {}
    }
  },

  cancelRecognition() {
    this.clearAsrTimer();
    this.clearAsrStopTimer();
    this.disposeRecognition();
  },

  // 当无 ASR 返回或离线模拟时，提供显式标注 [OFFLINE SAMPLE] 的降级问答闭环
  simulateVoiceTurn() {
    const query = T.mockQueries[0];
    this.setData({
      liveTranscript: query,
      lastQuery: query
    });
    this.executeLLMQuery(query);
  },

  async executeLLMQuery(query) {
    const turnId = ++this.currentTurnId;
    this.setStatus('thinking', 'AI');
    this.setData({
      lastQuery: query,
      lastAnswer: T.thinkingText
    });

    let fullText = '';
    const isOfflineSample = String(query).indexOf('[OFFLINE SAMPLE]') === 0;

    try {
      if (!isOfflineSample) {
        const session = await this.ensureLLMSession();
        if (this.currentTurnId !== turnId) return;
        if (session && typeof session.promptStreaming === 'function') {
          const stream = session.promptStreaming(query);
          while (true) {
            if (this.currentTurnId !== turnId) {
              if (stream && typeof stream.cancel === 'function') {
                try {
                  stream.cancel();
                } catch (_) {}
              }
              return;
            }
            let readTimer = null;
            const { done, value } = await Promise.race([
              stream.read(),
              new Promise((_, reject) => {
                readTimer = setTimeout(() => reject(new Error('LLM stream timeout (8s)')), 8000);
              })
            ]).finally(() => {
              if (readTimer) clearTimeout(readTimer);
            });
            if (this.currentTurnId !== turnId) {
              if (stream && typeof stream.cancel === 'function') {
                try {
                  stream.cancel();
                } catch (_) {}
              }
              return;
            }
            if (done) break;
            if (typeof value === 'string' && value.length > 0) {
              fullText += value;
              this.setData({ lastAnswer: fullText });
            } else {
              await sleep(STREAM_POLL_MS);
            }
          }
        }
      }

      if (!fullText) {
        await sleep(600);
        if (this.currentTurnId !== turnId) return;
        fullText = T.offlineSampleAnswer || `${T.offlineReplyPrefix}${query}${T.offlineReplySuffix}`;
        this.setData({ lastAnswer: fullText });
      }

      if (this.currentTurnId !== turnId) return;
      const reply = fullText || T.doneFallback;
      this.setData({ lastAnswer: reply });
      await this.speak(reply);
    } catch (err) {
      if (this.currentTurnId !== turnId) return;
      console.warn('[AIUI] LLM Execution fallback:', err);
      const fallback = T.offlineSampleAnswer || `${T.offlineReplyPrefix}${query}${T.offlineReplySuffix}`;
      this.setData({ lastAnswer: fallback });
      await this.speak(fallback);
    }
  },

  async captureAndAnalyze() {
    if (this.data.isBusy) return;
    const turnId = ++this.currentTurnId;
    this.setStatus('capturing', 'CAM');
    this.setData({
      mode: 'vision',
      visionResult: T.capturingVision
    });

    try {
      let base64Img = '';
      let mimeType = 'image/webp';
      if (this.cameraContext && typeof this.cameraContext.takePhoto === 'function') {
        let photoTimer = null;
        try {
          const photo = await Promise.race([
            this.cameraContext.takePhoto({ quality: 'low' }),
            new Promise((_, reject) => {
              photoTimer = setTimeout(() => reject(new Error('Camera takePhoto timeout (4s)')), 4000);
            })
          ]);
          if (photo && photo.mimeType) {
            mimeType = photo.mimeType;
          }
          if (photo && photo.data) {
            const buf = toArrayBuffer(photo.data);
            if (buf && wx && typeof wx.arrayBufferToBase64 === 'function') {
              base64Img = wx.arrayBufferToBase64(buf);
            }
          }
        } catch (camErr) {
          console.warn('[AIUI] takePhoto fallback:', camErr);
        } finally {
          if (photoTimer) clearTimeout(photoTimer);
        }
      }
      if (this.currentTurnId !== turnId) return;

      this.setStatus('thinking', 'ANALYZING…');
      this.setData({ visionResult: T.analyzingVision });

      let answer = '';
      if (base64Img) {
        answer = await analyzeImageWithCloudProxy(T.visionPrompt, base64Img, mimeType);
      } else {
        await sleep(700);
        answer = T.mockVisionAnswer;
      }
      if (this.currentTurnId !== turnId) return;

      const finalDesc = normalizeText(answer) || T.visionUnrecognized;
      this.setData({
        visionResult: finalDesc,
        lastAnswer: finalDesc
      });

      await this.speak(finalDesc);
    } catch (err) {
      if (this.currentTurnId !== turnId) return;
      console.warn('[AIUI] Camera analyze error:', err);
      this.setData({
        visionResult: T.visionErrorFallback,
        lastAnswer: T.visionErrorFallback
      });
      await this.speak(T.visionErrorTts);
    } finally {
      if (this.currentTurnId === turnId && this.data.status !== 'speaking') {
        this.setStatus('idle', 'IDLE');
      }
    }
  },

  clearTtsTimer() {
    if (this.ttsTimer) {
      clearTimeout(this.ttsTimer);
      this.ttsTimer = null;
    }
  },

  async speakAnswer(text) {
    return this.speak(text);
  },

  async speak(text) {
    if (!text) {
      this.setStatus('idle', 'IDLE');
      return;
    }

    this.cancelSpeech();
    this.setStatus('speaking', 'TTS');
    const durationMs = Math.min(20000, Math.max(3000, 1500 + 220 * String(text).length));

    // 优先使用 Web SpeechSynthesis（附带基于字数的超时兜底）
    if (typeof speechSynthesis !== 'undefined' && typeof SpeechSynthesisUtterance !== 'undefined') {
      return new Promise((resolve) => {
        let finished = false;
        const finish = () => {
          if (finished) return;
          finished = true;
          this.clearTtsTimer();
          if (this.ttsFinishResolver === finish) {
            this.ttsFinishResolver = null;
          }
          if (this.data.status === 'speaking') {
            this.setStatus('idle', 'IDLE');
          }
          resolve();
        };
        this.ttsFinishResolver = finish;
        this.ttsTimer = setTimeout(finish, durationMs);
        try {
          const utterance = new SpeechSynthesisUtterance(String(text));
          utterance.lang = SPEECH_LANG;
          utterance.onend = finish;
          utterance.onerror = finish;
          speechSynthesis.speak(utterance, 'immediate');
        } catch (_) {
          finish();
        }
      });
    }

    // 次选 wx.speech.playTTS（传入纯字符串，附带基于字数的超时兜底）
    if (wx && wx.speech && typeof wx.speech.playTTS === 'function') {
      return new Promise((resolve) => {
        let finished = false;
        const finish = () => {
          if (finished) return;
          finished = true;
          this.clearTtsTimer();
          if (this.ttsFinishResolver === finish) {
            this.ttsFinishResolver = null;
          }
          if (this.data.status === 'speaking') {
            this.setStatus('idle', 'IDLE');
          }
          resolve();
        };
        this.ttsFinishResolver = finish;
        this.ttsTimer = setTimeout(finish, durationMs);
        try {
          wx.speech.playTTS(String(text));
        } catch (_) {
          finish();
        }
      });
    }

    // 无 TTS 能力时自动恢复 idle
    await sleep(1000);
    this.setStatus('idle', 'IDLE');
  },

  cancelSpeech() {
    this.clearTtsTimer();
    if (this.ttsFinishResolver) {
      const resolve = this.ttsFinishResolver;
      this.ttsFinishResolver = null;
      resolve();
    }
  }
};
</script>

<page>
  <view class="hud-canvas">
    <!-- 顶部 HUD 系统状态行 (严格适配 480px 宽度与单色视效) -->
    <view class="hud-header">
      <view class="header-left">
        <text class="brand-tag">{{i18n.brandTag}}</text>
        <text class="divider">|</text>
        <text class="mode-tag" bindtap="cycleModeNext">{{mode.toUpperCase()}}</text>
      </view>
      <view class="header-right">
        <text class="clock-display">{{clock}}</text>
        <view class="badge badge-{{statusBadge.toLowerCase()}}">
          <text class="badge-text">{{statusBadge}}</text>
        </view>
      </view>
    </view>

    <!-- 主视口卡片：对话 / 视觉 / 态势三模态 -->
    <view class="hud-body">
      <!-- 模式一：语音对话 HUD -->
      <view class="panel-box" ink:if="{{mode === 'chat'}}">
        <view class="wave-box">
          <view class="wave-bar {{status === 'listening' ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{status === 'listening' || status === 'speaking' ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{status === 'speaking' ? 'wave-active' : ''}}"></view>
          <view class="wave-bar {{status === 'listening' ? 'wave-active' : ''}}"></view>
          <text class="wave-status-text">
            {{status === 'listening' ? i18n.waveListening : (status === 'thinking' ? i18n.waveThinking : (status === 'speaking' ? i18n.waveSpeaking : i18n.waveIdle))}}
          </text>
        </view>

        <view class="transcript-section">
          <view class="line-label">{{i18n.userInputLabel}}</view>
          <text class="user-query-text">{{liveTranscript || lastQuery || i18n.waitingInput}}</text>
        </view>

        <view class="response-section">
          <view class="line-label">{{i18n.aiAgentLabel}}</view>
          <text class="ai-reply-text">{{lastAnswer}}</text>
        </view>
      </view>

      <!-- 模式二：相机识图 HUD -->
      <view class="panel-box vision-panel" ink:if="{{mode === 'vision'}}">
        <view class="reticle-container">
          <view class="crosshair-h"></view>
          <view class="crosshair-v"></view>
          <view class="reticle-bracket top-left"></view>
          <view class="reticle-bracket top-right"></view>
          <view class="reticle-bracket bottom-left"></view>
          <view class="reticle-bracket bottom-right"></view>
          <text class="reticle-label">{{i18n.reticleLabel}}</text>
        </view>
        <view class="vision-desc-box">
          <view class="line-label">{{i18n.sceneLabel}}</view>
          <text class="vision-desc-text">{{visionResult}}</text>
        </view>
      </view>

      <!-- 模式三：仪表盘态势感知 HUD -->
      <view class="panel-box dashboard-panel" ink:if="{{mode === 'dashboard'}}">
        <view class="metrics-grid">
          <view class="metric-cell">
            <text class="metric-key">{{i18n.metricPitch}}</text>
            <text class="metric-val">{{pitch}}°</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">{{i18n.metricRoll}}</text>
            <text class="metric-val">{{roll}}°</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">{{i18n.metricSteps}}</text>
            <text class="metric-val">{{steps}}</text>
          </view>
          <view class="metric-cell">
            <text class="metric-key">{{i18n.metricFps}}</text>
            <text class="metric-val">{{fps}}</text>
          </view>
        </view>
        <view class="caps-status-row">
          <text class="caps-item {{llmAvailable ? 'caps-on' : ''}}">LLM</text>
          <text class="caps-item {{recognitionAvailable ? 'caps-on' : ''}}">ASR</text>
          <text class="caps-item {{ttsAvailable ? 'caps-on' : ''}}">TTS</text>
          <text class="caps-item {{cameraAvailable ? 'caps-on' : ''}}">CAM</text>
        </view>
      </view>
    </view>

    <!-- 底部镜腿手势快捷操作导航 (固定安全区) -->
    <view class="hud-footer">
      <view class="hint-group" bindtap="handleTempleTap">
        <text class="key-tag">{{i18n.keyTap}}</text>
        <text class="hint-text">{{mode === 'vision' ? i18n.hintVision : i18n.hintVoice}}</text>
      </view>
      <view class="hint-group" bindtap="cycleModeNext">
        <text class="key-tag">{{i18n.keySwipe}}</text>
        <text class="hint-text">{{i18n.hintSwitch}}</text>
      </view>
      <view class="hint-group" bindtap="resetIdle">
        <text class="key-tag">{{i18n.keyHold}}</text>
        <text class="hint-text">{{i18n.hintStandby}}</text>
      </view>
    </view>
  </view>
</page>

<style>
  /* 
   * Rokid Glasses 480x352 单绿色科学界面设计系统规范 (vBeta)
   * 主色: #40ff5e (单绿色 MicroLED)
   * 纯黑(#000000)为全透明背景
   */
  .hud-canvas {
    width: 480px;
    height: 352px;
    box-sizing: border-box;
    padding: 12px 16px;
    background-color: #000000;
    color: rgba(64, 255, 94, 0.72);
    font-family: sans-serif;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    overflow: hidden;
  }

  /* 顶部状态栏 */
  .hud-header {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    height: 24px;
    border-bottom: 1px solid rgba(64, 255, 94, 0.24);
    padding-bottom: 4px;
  }

  .header-left, .header-right {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 8px;
  }

  .brand-tag {
    font-size: 11px;
    font-weight: 500;
    color: #40ff5e;
  }

  .divider {
    font-size: 10px;
    color: rgba(64, 255, 94, 0.24);
  }

  .mode-tag {
    font-size: 11px;
    font-weight: 500;
    color: rgba(64, 255, 94, 0.72);
  }

  .clock-display {
    font-size: 11px;
    font-weight: 400;
    font-family: monospace;
    color: rgba(64, 255, 94, 0.72);
  }

  .badge {
    padding: 2px 8px;
    border-radius: 4px;
    border: 1px solid rgba(64, 255, 94, 0.48);
  }

  .badge-idle {
    border-color: rgba(64, 255, 94, 0.24);
  }

  .badge-rec, .badge-ai, .badge-tts, .badge-cam {
    border-color: rgba(64, 255, 94, 0.72);
    background-color: rgba(64, 255, 94, 0.12);
  }

  .badge-text {
    font-size: 10px;
    font-weight: 500;
    font-family: monospace;
    color: #40ff5e;
  }

  /* 主显示区 */
  .hud-body {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    padding: 8px 0;
    overflow: hidden;
  }

  .panel-box {
    display: flex;
    flex-direction: column;
    gap: 8px;
    height: 100%;
    justify-content: space-around;
  }

  /* 模式一：语音与对话样式 */
  .wave-box {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 4px;
    height: 20px;
  }

  .wave-bar {
    width: 3px;
    height: 6px;
    background-color: rgba(64, 255, 94, 0.24);
    border-radius: 2px;
  }

  .wave-active {
    height: 14px;
    background-color: #40ff5e;
  }

  .wave-status-text {
    font-size: 11px;
    font-weight: 400;
    margin-left: 8px;
    color: rgba(64, 255, 94, 0.72);
  }

  .line-label {
    font-size: 11px;
    font-weight: 500;
    color: rgba(64, 255, 94, 0.48);
    margin-bottom: 2px;
  }

  .transcript-section {
    padding: 6px 12px;
    border-radius: 6px;
    border: 1px solid rgba(64, 255, 94, 0.24);
    background-color: rgba(64, 255, 94, 0.06);
    height: 46px;
    box-sizing: border-box;
    overflow: hidden;
  }

  .user-query-text {
    font-size: 12px;
    font-weight: 400;
    line-height: 18px;
    height: 18px;
    overflow: hidden;
    color: rgba(64, 255, 94, 0.72);
  }

  .response-section {
    padding: 8px 12px;
    border-radius: 6px;
    border: 1px solid rgba(64, 255, 94, 0.72);
    background-color: rgba(64, 255, 94, 0.12);
    height: 84px;
    box-sizing: border-box;
    overflow: hidden;
  }

  .ai-reply-text {
    font-size: 14px;
    font-weight: 400;
    line-height: 20px;
    height: 44px;
    overflow: hidden;
    color: #40ff5e;
  }

  /* 模式二：十字准星与视觉识别面板 */
  .vision-panel {
    align-items: center;
    justify-content: center;
  }

  .reticle-container {
    width: 140px;
    height: 100px;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px dashed rgba(64, 255, 94, 0.24);
    border-radius: 2px;
    margin-bottom: 4px;
  }

  .crosshair-h {
    width: 20px;
    height: 1px;
    background-color: #40ff5e;
    position: absolute;
  }

  .crosshair-v {
    width: 1px;
    height: 20px;
    background-color: #40ff5e;
    position: absolute;
  }

  .reticle-label {
    position: absolute;
    font-size: 10px;
    font-weight: 400;
    font-family: monospace;
    color: rgba(64, 255, 94, 0.48);
    margin-top: 72px;
  }

  .reticle-bracket {
    position: absolute;
    width: 8px;
    height: 8px;
    border-color: #40ff5e;
  }

  .top-left {
    margin-right: 120px;
    margin-bottom: 80px;
    border-width: 1px 0 0 1px;
    border-style: solid;
    border-color: #40ff5e;
  }

  .top-right {
    margin-left: 120px;
    margin-bottom: 80px;
    border-width: 1px 1px 0 0;
    border-style: solid;
    border-color: #40ff5e;
  }

  .bottom-left {
    margin-right: 120px;
    margin-top: 80px;
    border-width: 0 0 1px 1px;
    border-style: solid;
    border-color: #40ff5e;
  }

  .bottom-right {
    margin-left: 120px;
    margin-top: 80px;
    border-width: 0 1px 1px 0;
    border-style: solid;
    border-color: #40ff5e;
  }

  .vision-desc-box {
    width: 100%;
    height: 64px;
    box-sizing: border-box;
    padding: 8px 12px;
    border-radius: 6px;
    border: 1px solid rgba(64, 255, 94, 0.72);
    background-color: rgba(64, 255, 94, 0.06);
    overflow: hidden;
  }

  .vision-desc-text {
    font-size: 13px;
    font-weight: 400;
    line-height: 18px;
    height: 36px;
    overflow: hidden;
    color: #40ff5e;
  }

  /* 模式三：态势感知与网格 */
  .metrics-grid {
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;
    gap: 8px;
    justify-content: space-between;
  }

  .metric-cell {
    width: 48%;
    padding: 8px 12px;
    box-sizing: border-box;
    border: 1px solid rgba(64, 255, 94, 0.24);
    border-radius: 6px;
    background-color: rgba(64, 255, 94, 0.06);
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
  }

  .metric-key {
    font-size: 11px;
    font-weight: 400;
    color: rgba(64, 255, 94, 0.72);
  }

  .metric-val {
    font-size: 13px;
    font-weight: 500;
    font-family: monospace;
    color: #40ff5e;
  }

  .caps-status-row {
    display: flex;
    flex-direction: row;
    justify-content: space-around;
    padding: 8px 0;
    border-top: 1px solid rgba(64, 255, 94, 0.24);
  }

  .caps-item {
    font-size: 10px;
    font-weight: 400;
    font-family: monospace;
    padding: 2px 8px;
    border: 1px solid rgba(64, 255, 94, 0.24);
    border-radius: 4px;
    color: rgba(64, 255, 94, 0.24);
  }

  .caps-on {
    color: #40ff5e;
    border-color: rgba(64, 255, 94, 0.72);
    background-color: rgba(64, 255, 94, 0.12);
  }

  /* 底部按键提示栏 */
  .hud-footer {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
    height: 22px;
    border-top: 1px solid rgba(64, 255, 94, 0.24);
    padding-top: 4px;
  }

  .hint-group {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 4px;
  }

  .key-tag {
    font-size: 10px;
    font-weight: 500;
    padding: 1px 6px;
    border-radius: 4px;
    border: 1px solid rgba(64, 255, 94, 0.48);
    color: #40ff5e;
    background-color: rgba(64, 255, 94, 0.06);
  }

  .hint-text {
    font-size: 10px;
    font-weight: 400;
    color: rgba(64, 255, 94, 0.72);
  }
</style>
