const BASE_URL = process.env.PROXY_URL || 'https://rokid-aiui-gcp-proxy-766918001064.us-central1.run.app';

console.log(`\n======================================================`);
console.log(`[E2E Test] Testing Proxy: ${BASE_URL}`);
console.log(`======================================================\n`);

async function runTests() {
  let passed = 0;
  let failed = 0;

  async function assert(desc, fn) {
    try {
      const start = Date.now();
      await fn();
      const elapsed = Date.now() - start;
      console.log(`  ✅ [PASS] ${desc} (${elapsed}ms)`);
      passed++;
    } catch (e) {
      console.error(`  ❌ [FAIL] ${desc}: ${e.message}`);
      failed++;
    }
  }

  // 1. Health check
  await assert('1. GET /health (Public endpoint)', async () => {
    const res = await fetch(`${BASE_URL}/health`);
    if (!res.ok) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (data.status !== 'UP') throw new Error('Status not UP');
  });

  // 2. Unauthenticated invocation rejection (Must return 401)
  await assert('2. Security Gate: POST /api/gemini without auth must return 401', async () => {
    const res = await fetch(`${BASE_URL}/api/gemini`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt: 'Hello without token' })
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
    const data = await res.json();
    if (data.error !== 'UNAUTHORIZED') throw new Error(`Expected error UNAUTHORIZED, got ${data.error}`);
  });

  await assert('3. Security Gate: POST /api/translate without auth must return 401', async () => {
    const res = await fetch(`${BASE_URL}/api/translate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Hello without token' })
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // 3. Invalid credentials verification on /api/auth/verify (Must return 401)
  await assert('4. Auth Verification: Invalid Rokid code rejected with 401', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accountId: 'unauthorized_user_999',
        code: 'test_invalid_code_xyz'
      })
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
    const data = await res.json();
    if (data.success !== false) throw new Error('Expected success: false');
  });

  // 4. Valid credentials verification on /api/auth/verify (Must return 200 + sessionToken)
  let validSessionToken = null;
  await assert('5. Auth Verification: Valid Rokid agent code returns 200 + Bearer Session Token', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accountId: 'rokid_agent_user_001',
        code: 'test_valid_code_abc123'
      })
    });
    if (!res.ok) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!data.success || !data.sessionToken) throw new Error('Session token not issued');
    validSessionToken = data.sessionToken;
    console.log(`     Token issued: ${validSessionToken.substring(0, 30)}...`);
  });

  // 5. Authorized invocation of Google Cloud Translation
  await assert('6. Protected Service: POST /api/translate with Bearer Token executes Cloud Translation', async () => {
    const res = await fetch(`${BASE_URL}/api/translate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${validSessionToken}`
      },
      body: JSON.stringify({
        text: 'The Rokid AIUI agent is verified and now invoking Google Cloud on Cloud Run.',
        target: 'zh-CN'
      })
    });
    if (!res.ok) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!data.translation) throw new Error('Translation result missing');
    console.log(`     Translation: "${data.translation}"`);
  });

  // 6. Authorized invocation of Vertex AI Gemini 2.5 Flash
  await assert('7. Protected Service: POST /api/gemini with Bearer Token executes Vertex AI Gemini', async () => {
    const res = await fetch(`${BASE_URL}/api/gemini`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${validSessionToken}`
      },
      body: JSON.stringify({
        prompt: '以AR单绿色HUD助手的视角，用20字以内确认身份校验通过并接入Vertex AI。'
      })
    });
    if (!res.ok) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!data.answer) throw new Error('Gemini answer missing');
    console.log(`     Gemini: "${data.answer.trim()}"`);
  });

  // 7. Authorized invocation of Cloud Text-to-Speech
  await assert('8. Protected Service: POST /api/tts with Bearer Token executes Cloud Text-to-Speech', async () => {
    const res = await fetch(`${BASE_URL}/api/tts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${validSessionToken}`
      },
      body: JSON.stringify({
        text: '身份校验通过，Cloud Run 代理运行正常。'
      })
    });
    if (!res.ok) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!data.audioContent || data.audioContent.length < 100) throw new Error('TTS audioContent invalid');
    console.log(`     TTS Audio Bytes: ${data.audioContent.length} chars`);
  });

  // 8. Direct invocation with X-Rokid headers
  await assert('9. Direct Header Mode: POST /api/translate with X-Rokid headers passes gatekeeper', async () => {
    const res = await fetch(`${BASE_URL}/api/translate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Rokid-Account-Id': 'rokid_agent_direct_002',
        'X-Rokid-Code': 'test_valid_direct_code'
      },
      body: JSON.stringify({
        text: 'Direct header authentication successful.',
        target: 'zh-CN'
      })
    });
    if (!res.ok) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    console.log(`     Translation: "${data.translation}"`);
  });

  console.log(`\n------------------------------------------------------`);
  console.log(`Test Results: ${passed} Passed, ${failed} Failed`);
  console.log(`------------------------------------------------------\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch(err => {
  console.error('Fatal test runner error:', err);
  process.exit(1);
});
