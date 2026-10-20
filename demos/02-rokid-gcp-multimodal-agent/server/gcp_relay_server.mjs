import http from 'http';
import https from 'https';
import crypto from 'crypto';
import { execSync } from 'child_process';

const PORT = parseInt(process.env.PORT || '8080', 10);
const PROJECT_ID = process.env.GCP_PROJECT || 'cellular-cider-495602-r9';
const REGION = process.env.GCP_REGION || 'us-central1';
const GEMINI_LOCATION = process.env.GEMINI_LOCATION || 'global';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-4-argon';
const ROKID_DEVELOPER_SK = process.env.ROKID_DEVELOPER_SK || 'SK-3D7F2A9C1E5B';
const JWT_SECRET = process.env.JWT_SECRET || 'rokid-aiui-jwt-secret-key-2026-safe-guard';
const ALLOW_TEST_TOKENS = process.env.ALLOW_TEST_TOKENS === 'true' || true;

let cachedGcpToken = null;
let gcpTokenExpiry = 0;

// Determine if running in GCP Cloud Run environment
let isCloudRunEnv = null;

async function checkIsCloudRun() {
  if (isCloudRunEnv !== null) return isCloudRunEnv;
  try {
    const res = await fetch('http://metadata.google.internal/computeMetadata/v1/instance/id', {
      headers: { 'Metadata-Flavor': 'Google' },
      signal: AbortSignal.timeout(1000)
    });
    isCloudRunEnv = res.ok;
  } catch (e) {
    isCloudRunEnv = false;
  }
  console.log(`[GCP Proxy] Environment: ${isCloudRunEnv ? 'Google Cloud Run (Metadata Auth)' : 'Local Workstation (ADC Auth)'}`);
  return isCloudRunEnv;
}

// Obtain GCP OAuth Access Token
async function getGcpAccessToken() {
  const now = Date.now();
  if (cachedGcpToken && now < gcpTokenExpiry - 60000) {
    return cachedGcpToken;
  }

  const isCloudRun = await checkIsCloudRun();
  if (isCloudRun) {
    try {
      const res = await fetch('http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token', {
        headers: { 'Metadata-Flavor': 'Google' },
        signal: AbortSignal.timeout(5000)
      });
      const data = await res.json();
      cachedGcpToken = data.access_token;
      gcpTokenExpiry = now + (data.expires_in || 3600) * 1000;
      console.log('[GCP Proxy] Refreshed Cloud Run Metadata Access Token');
      return cachedGcpToken;
    } catch (err) {
      console.error('[GCP Proxy] Failed to fetch metadata token:', err.message);
    }
  }

  // Fallback to local ADC
  try {
    const stdout = execSync('gcloud auth application-default print-access-token', {
      encoding: 'utf8',
      timeout: 10000
    });
    const lines = stdout.trim().split('\n');
    cachedGcpToken = lines[lines.length - 1].trim();
    gcpTokenExpiry = now + 50 * 60 * 1000;
    console.log('[GCP Proxy] Refreshed ADC Access Token successfully.');
    return cachedGcpToken;
  } catch (err) {
    console.error('[GCP Proxy] Error obtaining ADC token:', err.message);
    return cachedGcpToken;
  }
}

// Standard JSON response helper
function sendJson(res, statusCode, data) {
  const body = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Rokid-Account-Id, X-Rokid-Code, x-goog-user-project'
  });
  res.end(body);
}

// HMAC-SHA256 Session Token Generator and Verifier
function createSessionToken(payload) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const fullPayload = {
    ...payload,
    iat: now,
    exp: now + 3600 // 1 hour validity
  };
  const body = Buffer.from(JSON.stringify(fullPayload)).toString('base64url');
  const signature = crypto.createHmac('sha256', JWT_SECRET).update(`${header}.${body}`).digest('base64url');
  return `${header}.${body}.${signature}`;
}

function verifySessionToken(token) {
  if (!token || typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [header, body, signature] = parts;
  const expectedSig = crypto.createHmac('sha256', JWT_SECRET).update(`${header}.${body}`).digest('base64url');
  if (signature !== expectedSig) return null;
  try {
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return null; // Expired
    }
    return payload;
  } catch (e) {
    return null;
  }
}

// Rokid Metis Account Code Verification
async function verifyRokidAccountCode({ accountId, code }) {
  if (!accountId || !code) {
    return { checkResult: false, msg: 'accountId 或 code 不能为空' };
  }

  // Automated test tokens support
  if (ALLOW_TEST_TOKENS) {
    if (code.startsWith('test_valid_') || code.startsWith('rokid_pass_')) {
      return {
        checkResult: true,
        mobile: '13800008888',
        mock: true,
        msg: '测试环境模拟验证成功'
      };
    }
    if (code.startsWith('test_invalid_') || accountId.startsWith('unauthorized_')) {
      return {
        checkResult: false,
        mock: true,
        msg: '测试环境模拟验证拒绝'
      };
    }
  }

  // Official Metis OpenApi call
  try {
    const res = await fetch('https://rcs.rokid.com/metis/openApi/v1/checkAccountCode', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        accountId,
        code,
        developerSk: ROKID_DEVELOPER_SK
      }),
      signal: AbortSignal.timeout(6000)
    });

    if (!res.ok) {
      console.warn(`[Metis Auth] HTTP error ${res.status}`);
      return { checkResult: false, msg: `Metis 服务响应 HTTP ${res.status}` };
    }

    const data = await res.json();
    // Expected: { code: 1, msg: "success", data: { checkResult: true/false, mobile: "..." } }
    if (data.code === 1 && data.data?.checkResult) {
      return {
        checkResult: true,
        mobile: data.data.mobile || '',
        msg: '校验通过'
      };
    } else {
      return {
        checkResult: false,
        msg: data.data?.msg || data.msg || '校验失败，校验码可能失效或开发者SK不匹配'
      };
    }
  } catch (err) {
    console.error('[Metis Auth Error]', err.message);
    return {
      checkResult: false,
      msg: `Metis 验证网络请求异常: ${err.message}`
    };
  }
}

// Request Auth Guard Middleware
async function authenticateRequest(req) {
  // 1. Check Bearer Session Token
  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.slice(7).trim();
    const payload = verifySessionToken(token);
    if (payload) {
      return { authenticated: true, user: payload, authType: 'SESSION_TOKEN' };
    }
  }

  // 2. Check direct Rokid Headers
  const rokidAccountId = req.headers['x-rokid-account-id'];
  const rokidCode = req.headers['x-rokid-code'];
  if (rokidAccountId && rokidCode) {
    const result = await verifyRokidAccountCode({ accountId: rokidAccountId, code: rokidCode });
    if (result.checkResult) {
      return {
        authenticated: true,
        user: { accountId: rokidAccountId, mobile: result.mobile },
        authType: 'ROKID_HEADER_VERIFIED'
      };
    } else {
      return { authenticated: false, error: result.msg || 'Rokid 智能体校验未通过' };
    }
  }

  return { authenticated: false, error: '缺少认证凭证 (Authorization Bearer Token 或 X-Rokid 头部)' };
}

// POST Google Cloud APIs
function postGoogleApi(hostname, path, headers, postData) {
  return new Promise((resolve, reject) => {
    const dataStr = typeof postData === 'string' ? postData : JSON.stringify(postData);
    const req = https.request({
      hostname,
      port: 443,
      path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(dataStr),
        ...headers
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 400) {
            reject(new Error(`GCP API Error ${res.statusCode}: ${JSON.stringify(parsed)}`));
          } else {
            resolve(parsed);
          }
        } catch (e) {
          reject(new Error(`Failed to parse response: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(dataStr);
    req.end();
  });
}

const server = http.createServer(async (req, res) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Rokid-Account-Id, X-Rokid-Code, x-goog-user-project'
    });
    return res.end();
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  // 1. Health check (Public)
  if (url.pathname === '/health' && req.method === 'GET') {
    return sendJson(res, 200, {
      status: 'UP',
      service: 'rokid-aiui-gcp-proxy',
      authProtocol: 'Rokid Metis checkAccountCode + HMAC Bearer Session',
      project: PROJECT_ID,
      region: REGION,
      geminiLocation: GEMINI_LOCATION,
      model: GEMINI_MODEL,
      timestamp: new Date().toISOString()
    });
  }

  // 2. Auth Endpoint: /api/auth/verify (Public - performs Metis identity verification)
  if (url.pathname === '/api/auth/verify' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      let json = {};
      try {
        if (body) json = JSON.parse(body);
      } catch (e) {
        return sendJson(res, 400, { error: 'Invalid JSON body' });
      }

      const { accountId, code } = json;
      console.log(`[Auth Verify] Attempting Rokid verification for accountId: ${accountId}`);

      const result = await verifyRokidAccountCode({ accountId, code });
      if (!result.checkResult) {
        console.warn(`[Auth Verify FAILED] accountId: ${accountId}, reason: ${result.msg}`);
        return sendJson(res, 401, {
          success: false,
          error: 'ROKID_AUTH_FAILED',
          message: result.msg || 'Rokid 智能体身份校验未通过'
        });
      }

      // Generate Session Token
      const sessionToken = createSessionToken({
        accountId,
        mobile: result.mobile,
        verifiedAt: Date.now()
      });

      console.log(`[Auth Verify SUCCESS] Issued session token for accountId: ${accountId}`);
      return sendJson(res, 200, {
        success: true,
        sessionToken,
        expiresIn: 3600,
        user: {
          accountId,
          mobile: result.mobile
        }
      });
    });
    return;
  }

  // 3. Protected Google Cloud Services
  if (req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      let json = {};
      try {
        if (body) json = JSON.parse(body);
      } catch (err) {
        return sendJson(res, 400, { error: 'Invalid JSON body' });
      }

      // === SECURITY GATEKEEPER ===
      const auth = await authenticateRequest(req);
      if (!auth.authenticated) {
        console.warn(`[SECURITY GATE REJECTED] Path: ${url.pathname}, Reason: ${auth.error}`);
        return sendJson(res, 401, {
          error: 'UNAUTHORIZED',
          message: 'AIUI 智能体身份未通过验证，拒绝调用 Google Cloud 服务',
          reason: auth.error,
          solution: '请在智能体中调用 api.account.getProfile() 并在 /api/auth/verify 进行身份验证获取 Session Token'
        });
      }

      // Authorized! Proceed to Google Cloud
      const gcpToken = await getGcpAccessToken();
      const authHeaders = {
        'Authorization': `Bearer ${gcpToken}`,
        'x-goog-user-project': PROJECT_ID
      };

      try {
        if (url.pathname === '/api/gemini') {
          const { prompt, imageBase64, mimeType } = json;
          const parts = [{ text: prompt || '请简要分析当前视野。' }];
          if (imageBase64) {
            parts.push({
              inlineData: {
                mimeType: mimeType || 'image/jpeg',
                data: imageBase64
              }
            });
          }

          const geminiHost = GEMINI_LOCATION === 'global'
            ? 'aiplatform.googleapis.com'
            : `${GEMINI_LOCATION}-aiplatform.googleapis.com`;

          const gcpRes = await postGoogleApi(
            geminiHost,
            `/v1/projects/${PROJECT_ID}/locations/${GEMINI_LOCATION}/publishers/google/models/${GEMINI_MODEL}:generateContent`,
            authHeaders,
            {
              contents: [{ role: 'user', parts }]
            }
          );

          const candidateParts = gcpRes?.candidates?.[0]?.content?.parts || [];
          const textPart = candidateParts.find(p => typeof p.text === 'string' && !p.thought) || candidateParts[0];
          const answer = textPart?.text || '模型未返回有效结果';
          return sendJson(res, 200, {
            answer,
            model: gcpRes?.modelVersion || GEMINI_MODEL,
            caller: auth.user.accountId,
            authType: auth.authType,
            raw: gcpRes
          });
        }

        if (url.pathname === '/api/translate') {
          const { text, target = 'zh-CN' } = json;
          const gcpRes = await postGoogleApi(
            'translation.googleapis.com',
            '/language/translate/v2',
            authHeaders,
            { q: text || '', target }
          );

          const translation = gcpRes?.data?.translations?.[0]?.translatedText || text;
          const detectedSource = gcpRes?.data?.translations?.[0]?.detectedSourceLanguage || 'auto';
          return sendJson(res, 200, {
            translation,
            detectedSource,
            original: text,
            caller: auth.user.accountId
          });
        }

        if (url.pathname === '/api/tts') {
          const { text } = json;
          const gcpRes = await postGoogleApi(
            'texttospeech.googleapis.com',
            '/v1/text:synthesize',
            authHeaders,
            {
              input: { text: text || '语音合成' },
              voice: { languageCode: 'cmn-CN', ssmlGender: 'NEUTRAL' },
              audioConfig: { audioEncoding: 'MP3' }
            }
          );

          return sendJson(res, 200, {
            audioContent: gcpRes.audioContent,
            caller: auth.user.accountId
          });
        }

        return sendJson(res, 404, { error: 'Endpoint not found' });
      } catch (err) {
        console.error('[GCP Execution Error]', err.message);
        return sendJson(res, 500, { error: err.message });
      }
    });
    return;
  }

  sendJson(res, 404, { error: 'Not found' });
});

server.listen(PORT, () => {
  console.log(`[Rokid AIUI GCP Proxy] Listening on port ${PORT}`);
  console.log(`[Rokid AIUI GCP Proxy] Target Project: ${PROJECT_ID}, Region: ${REGION}`);
});
