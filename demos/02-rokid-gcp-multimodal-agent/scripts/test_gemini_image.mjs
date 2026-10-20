import { execSync } from 'node:child_process';
import dns from 'node:dns';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { GCP_CONFIG } from '../gcp_config.js';

dns.setDefaultResultOrder('ipv4first');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const iconPath = path.resolve(__dirname, '../assets/icon.png');
const tmpJpgPath = '/tmp/demo02_test_256.jpg';

execSync(`sips -s format jpeg -s formatOptions 70 -Z 256 "${iconPath}" --out "${tmpJpgPath}"`, {
  stdio: 'ignore'
});

const jpgBytes = fs.readFileSync(tmpJpgPath);
const base64Image = jpgBytes.toString('base64');
const baseUrl = GCP_CONFIG.cloudRunUrl;

async function main() {
  console.log(`[Test] Target Cloud Run URL: ${baseUrl}`);
  console.log(`[Test] JPEG size: ${jpgBytes.length} bytes (${(base64Image.length / 1024).toFixed(2)} KB base64)`);

  const tAuth0 = Date.now();
  const authRes = await fetch(`${baseUrl}/api/auth/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      accountId: 'rokid_glasses_user_01',
      code: 'test_valid_glasses_code'
    }),
    signal: AbortSignal.timeout(10000)
  });
  const authLatency = Date.now() - tAuth0;
  const authData = await authRes.json().catch(() => ({}));
  console.log(`[Auth] HTTP ${authRes.status} (${authLatency} ms) -> success=${Boolean(authData.success)}`);

  const headers = { 'Content-Type': 'application/json' };
  if (authData.sessionToken) {
    headers['Authorization'] = `Bearer ${authData.sessionToken}`;
  }

  const prompt = 'Describe the colors, shapes, and text or icon visible in this image in one concise English sentence.';
  const tGem0 = Date.now();
  const gemRes = await fetch(`${baseUrl}/api/gemini`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      prompt,
      imageBase64: base64Image,
      base64Image
    }),
    signal: AbortSignal.timeout(25000)
  });
  const gemLatency = Date.now() - tGem0;
  const rawText = await gemRes.text();
  let parsed = null;
  try {
    parsed = JSON.parse(rawText);
  } catch (_) {}

  console.log(`[Gemini w/ Image] HTTP ${gemRes.status} (${gemLatency} ms)`);
  console.log(`[Gemini Response]: ${parsed ? JSON.stringify(parsed) : rawText}`);
}

main()
  .catch((err) => {
    console.error('[Test Error]:', err);
    process.exitCode = 1;
  })
  .finally(() => {
    try {
      fs.unlinkSync(tmpJpgPath);
    } catch (_) {}
  });
