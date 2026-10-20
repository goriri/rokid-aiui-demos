/**
 * Google Cloud AI Configuration & Service Bridge for Rokid Glasses
 * Connected to Cloud Run Proxy with Rokid AIUI Agent Identity Verification
 */

export const GCP_CONFIG = {
  projectId: 'cellular-cider-495602-r9',
  region: 'us-central1',
  geminiModel: 'gemini-2.5-flash',
  cloudRunUrl: 'https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app',
  localRelayUrl: 'http://localhost:8088',
  defaultTargetLang: 'en',
  tokenTtl: 3600,
  visionTimeoutMs: 25000,
  defaultTimeoutMs: 10000
};

// Current active session state
let sessionToken = null;
let sessionUser = null;
let wxRequestAdapter = null;

export function registerWxRequest(fn) {
  if (typeof fn === 'function') {
    wxRequestAdapter = fn;
  }
}

export function getSessionState() {
  return {
    isVerified: !!sessionToken,
    sessionToken,
    user: sessionUser
  };
}

/**
 * Unified HTTP JSON helper with explicit timeout support for both wx.request (on-device) and fetch
 */
async function requestJson(url, { method = 'GET', headers = {}, body = null, timeoutMs = 10000 } = {}) {
  if (typeof wxRequestAdapter === 'function') {
    return new Promise((resolve, reject) => {
      let settled = false;
      const timer = setTimeout(() => {
        if (settled) return;
        settled = true;
        reject(new Error(`Request timeout after ${timeoutMs}ms`));
      }, timeoutMs + 500);

      try {
        wxRequestAdapter({
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
            resolve({
              ok: status >= 200 && status < 300,
              status,
              data
            });
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

  try {
    const fetchOpts = {
      method,
      headers,
      timeout: timeoutMs
    };
    if (body !== null) {
      fetchOpts.body = typeof body === 'string' ? body : JSON.stringify(body);
    }
    if (typeof AbortSignal !== 'undefined' && typeof AbortSignal.timeout === 'function') {
      fetchOpts.signal = AbortSignal.timeout(timeoutMs);
    }
    const res = await Promise.race([fetch(url, fetchOpts), timeoutPromise]);
    clearTimeout(timer);
    const data = await res.json().catch(() => ({}));
    return {
      ok: res.ok,
      status: res.status,
      data
    };
  } catch (err) {
    clearTimeout(timer);
    throw err;
  }
}

/**
 * Perform Rokid AIUI Agent Identity Verification with Cloud Run Proxy (10s timeout)
 */
export async function authenticateWithProxy(accountId, code) {
  const targetUrl = GCP_CONFIG.cloudRunUrl || GCP_CONFIG.localRelayUrl;
  console.log(`[GCP Bridge] Verifying agent identity with: ${targetUrl}/api/auth/verify`);

  try {
    const res = await requestJson(`${targetUrl}/api/auth/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: {
        accountId: accountId || 'rokid_glasses_user_01',
        code: code || 'test_valid_glasses_code'
      },
      timeoutMs: GCP_CONFIG.defaultTimeoutMs
    });

    if (res.ok && res.data && res.data.success && res.data.sessionToken) {
      sessionToken = res.data.sessionToken;
      sessionUser = res.data.user;
      console.log('[GCP Bridge] Agent authenticated successfully. Bearer token acquired.');
      return { success: true, sessionToken, user: sessionUser };
    }
    console.warn('[GCP Bridge] Verification failed:', res.data);
    return { success: false, error: (res.data && res.data.message) || 'Verification rejected' };
  } catch (err) {
    console.warn('[GCP Bridge] Network error during auth verify:', err.message || err);
  }

  // Fallback to local session token in case of offline/simulated mode
  sessionToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.simulated_session_token';
  return { success: true, sessionToken, simulated: true };
}

/**
 * Call Vertex AI Gemini 2.5 Flash via Authenticated Cloud Run Proxy (25s timeout for vision)
 */
export async function queryGeminiVertexAI(prompt, imageBase64 = null, locale = 'en') {
  const targetUrl = GCP_CONFIG.cloudRunUrl || GCP_CONFIG.localRelayUrl;
  const cleanImageBase64 =
    typeof imageBase64 === 'string' && imageBase64.length > 0
      ? imageBase64.replace(/^data:[^;]+;base64,/, '')
      : null;

  try {
    if (!sessionToken) {
      await authenticateWithProxy('rokid_glasses_user_01', 'test_valid_glasses_code');
    }

    const headers = { 'Content-Type': 'application/json' };
    if (sessionToken) {
      headers['Authorization'] = `Bearer ${sessionToken}`;
    }

    const res = await requestJson(`${targetUrl}/api/gemini`, {
      method: 'POST',
      headers,
      body: {
        prompt,
        imageBase64: cleanImageBase64,
        base64Image: cleanImageBase64
      },
      timeoutMs: GCP_CONFIG.visionTimeoutMs
    });

    if (res.ok && res.data && res.data.answer) {
      return res.data.answer;
    }
    console.warn(`[GCP Client] Proxy returned HTTP ${res.status}`);
  } catch (err) {
    console.warn('[GCP Client] Proxy unreachable, falling back to local reasoning:', err);
  }

  if (locale === 'zh') {
    return 'OFFLINE DEMO · 云端不可达 — 展示示例结果：Rokid AR 单绿光波导光学模组运行正常。';
  }
  return 'OFFLINE DEMO · Cloud unreachable — showing sample result: Rokid AR monochrome-green waveguide module nominal.';
}

export async function callGeminiMultimodal(prompt, base64Image = null, locale = 'en') {
  return queryGeminiVertexAI(prompt, base64Image, locale);
}

/**
 * Call Google Cloud Translation API v2 via Authenticated Cloud Run Proxy (10s timeout)
 */
export async function queryGoogleTranslate(text, target = 'en') {
  const targetUrl = GCP_CONFIG.cloudRunUrl || GCP_CONFIG.localRelayUrl;

  try {
    if (!sessionToken) {
      await authenticateWithProxy('rokid_glasses_user_01', 'test_valid_glasses_code');
    }

    const headers = { 'Content-Type': 'application/json' };
    if (sessionToken) {
      headers['Authorization'] = `Bearer ${sessionToken}`;
    }

    const res = await requestJson(`${targetUrl}/api/translate`, {
      method: 'POST',
      headers,
      body: { text, target },
      timeoutMs: GCP_CONFIG.defaultTimeoutMs
    });

    if (res.ok && res.data && res.data.translation) {
      return {
        translated: res.data.translation,
        sourceLang: res.data.detectedSource || (target === 'en' ? 'zh-CN' : 'en'),
        offline: false
      };
    }
  } catch (err) {
    console.warn('[GCP Client] Proxy translate error:', err);
  }

  const dictionary = {
    '早上好！今天的天气非常适合开展户外实地考察。': 'Good morning! The weather today is ideal for outdoor field work.',
    '欢迎使用由 Google Cloud Vertex AI 驱动的 Rokid AR 眼镜。': 'Welcome to Rokid AR Glasses powered by Google Cloud Vertex AI.',
    '微光波导显示器在户外阳光下依然保持清晰对比度。': 'The optical waveguide display keeps crisp contrast in bright sunlight.',
    '与设计团队的下一场会议将在15分钟后开始。': 'The next meeting with the design team starts in 15 minutes.',
    'Good morning! The weather today is perfect for outdoor field work.': '早上好！今天的天气非常适合开展户外实地考察。',
    'Welcome to Rokid AR Glasses powered by Google Cloud.': '欢迎使用由 Google Cloud 强力驱动的 Rokid AR 眼镜。',
    'AI Target acquired: Analyzing spatial geometry and depth.': '目标已锁定：正在分析空间几何特征与纵深数据。',
    'Real-time bilingual subtitles activated.': '实时双语同传字幕已激活。'
  };

  const sample = dictionary[text] || text;
  const offlinePrefix =
    target === 'en'
      ? 'OFFLINE DEMO · Cloud unreachable — showing sample result: '
      : 'OFFLINE DEMO · 云端不可达 — 展示示例结果：';

  return {
    translated: `${offlinePrefix}${sample}`,
    sourceLang: target === 'en' ? 'zh-CN' : 'en',
    offline: true
  };
}

/**
 * Health check & GCP status (10s timeout)
 */
export async function checkGCPHealth() {
  const targetUrl = GCP_CONFIG.cloudRunUrl || GCP_CONFIG.localRelayUrl;
  try {
    const res = await requestJson(`${targetUrl}/health`, {
      method: 'GET',
      timeoutMs: GCP_CONFIG.defaultTimeoutMs
    });
    if (res.ok && res.data) {
      return res.data;
    }
  } catch (_) {}

  return {
    status: 'OFFLINE',
    project: GCP_CONFIG.projectId,
    region: GCP_CONFIG.region,
    model: GCP_CONFIG.geminiModel,
    authProtocol: 'Rokid Metis checkAccountCode + Cloud Run Proxy'
  };
}
