import http from 'http';
import https from 'https';
import { execSync } from 'child_process';

const PORT = process.env.PORT || 8088;
const PROJECT_ID = process.env.GCP_PROJECT || 'cellular-cider-495602-r9';
const REGION = process.env.GCP_REGION || 'us-central1';
const GEMINI_MODEL = 'gemini-2.5-flash';

let cachedToken = null;
let tokenExpiry = 0;

function getAccessToken() {
  const now = Date.now();
  if (cachedToken && now < tokenExpiry - 60000) {
    return cachedToken;
  }
  try {
    const stdout = execSync('gcloud auth application-default print-access-token', {
      encoding: 'utf8',
      timeout: 10000
    });
    const lines = stdout.trim().split('\n');
    cachedToken = lines[lines.length - 1].trim();
    tokenExpiry = now + 50 * 60 * 1000; // 50 mins
    console.log('[GCP Relay] Refreshed ADC Access Token successfully.');
    return cachedToken;
  } catch (err) {
    console.error('[GCP Relay] Error obtaining ADC token:', err.message);
    return cachedToken;
  }
}

function sendJson(res, statusCode, data) {
  const body = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-goog-user-project'
  });
  res.end(body);
}

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
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-goog-user-project'
    });
    return res.end();
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === '/health' && req.method === 'GET') {
    return sendJson(res, 200, {
      status: 'UP',
      project: PROJECT_ID,
      region: REGION,
      model: GEMINI_MODEL,
      auth: 'ADC',
      timestamp: new Date().toISOString()
    });
  }

  if (url.pathname === '/api/token' && req.method === 'GET') {
    const token = getAccessToken();
    return sendJson(res, 200, {
      token,
      project_id: PROJECT_ID,
      expires_in: Math.max(0, Math.floor((tokenExpiry - Date.now()) / 1000))
    });
  }

  // Parse JSON body for POST endpoints
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

      const token = getAccessToken();
      const authHeaders = {
        'Authorization': `Bearer ${token}`,
        'x-goog-user-project': PROJECT_ID
      };

      try {
        if (url.pathname === '/api/gemini') {
          const { prompt, imageBase64 } = json;
          const parts = [{ text: prompt || '请简要分析当前视野。' }];
          if (imageBase64) {
            parts.push({
              inlineData: {
                mimeType: 'image/jpeg',
                data: imageBase64
              }
            });
          }

          const gcpRes = await postGoogleApi(
            `${REGION}-aiplatform.googleapis.com`,
            `/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${GEMINI_MODEL}:generateContent`,
            authHeaders,
            { contents: [{ role: 'user', parts }] }
          );

          const answer = gcpRes?.candidates?.[0]?.content?.parts?.[0]?.text || '模型未返回有效结果';
          return sendJson(res, 200, { answer, raw: gcpRes });
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
          return sendJson(res, 200, { translation, detectedSource, original: text });
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

          return sendJson(res, 200, { audioContent: gcpRes.audioContent });
        }

        return sendJson(res, 404, { error: 'Endpoint not found' });
      } catch (err) {
        console.error('[GCP Relay Error]', err.message);
        return sendJson(res, 500, { error: err.message });
      }
    });
    return;
  }

  sendJson(res, 404, { error: 'Not found' });
});

server.listen(PORT, () => {
  console.log(`[GCP Relay Server] Listening on http://localhost:${PORT}`);
  console.log(`[GCP Relay Server] Target Project: ${PROJECT_ID}, Region: ${REGION}`);
});
