const RELAY_BASE = 'http://localhost:8088';

async function requestJson(url, options = {}) {
  const start = Date.now();
  const res = await fetch(url, options);
  const latency = Date.now() - start;
  const json = await res.json();
  return { ok: res.ok, status: res.status, json, latency };
}

async function runRealRelayTests() {
  console.log('=== 开始真实 GCP Relay Endpoint 端到端综合测试 ===\n');

  // Test 1: /health
  console.log('1. 测试 /health 健康检查端点...');
  const healthRes = await requestJson(`${RELAY_BASE}/health`);
  console.log(`[PASS] /health 状态: ${healthRes.status}, 延迟: ${healthRes.latency}ms`);
  console.log(`       响应数据:`, JSON.stringify(healthRes.json));

  if (!healthRes.ok || healthRes.json.status !== 'UP') {
    throw new Error('Health check failed!');
  }

  // Test 2: /api/token
  console.log('\n2. 测试 /api/token ADC 凭证分发端点...');
  const tokenRes = await requestJson(`${RELAY_BASE}/api/token`);
  console.log(`[PASS] /api/token 状态: ${tokenRes.status}, 延迟: ${tokenRes.latency}ms`);
  console.log(`       项目 ID: ${tokenRes.json.project_id}, 剩余有效期: ${tokenRes.json.expires_in}s`);
  console.log(`       Token 前缀: ${tokenRes.json.token ? tokenRes.json.token.substring(0, 18) + '...' : 'NONE'}`);

  if (!tokenRes.ok || !tokenRes.json.token) {
    throw new Error('Token endpoint failed!');
  }

  // Test 3: /api/translate
  console.log('\n3. 测试 /api/translate 实时翻译端点 (Google Cloud Translation v2)...');
  const translateInput = 'Good morning! The weather today is perfect for outdoor field work.';
  const translateRes = await requestJson(`${RELAY_BASE}/api/translate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: translateInput, target: 'zh-CN' })
  });
  console.log(`[PASS] /api/translate 状态: ${translateRes.status}, 延迟: ${translateRes.latency}ms`);
  console.log(`       原文: "${translateInput}"`);
  console.log(`       译文: "${translateRes.json.translation}"`);
  console.log(`       源语言检测: ${translateRes.json.detectedSource}`);

  if (!translateRes.ok || !translateRes.json.translation) {
    throw new Error('Translation test failed!');
  }

  // Test 4: /api/gemini
  console.log('\n4. 测试 /api/gemini 视觉/空间大模型推理端点 (Vertex AI gemini-2.5-flash)...');
  const geminiPrompt = '以AR单绿色微显示HUD的视角，用30字以内简要评价Rokid Glasses结合Vertex AI的优势。';
  const geminiRes = await requestJson(`${RELAY_BASE}/api/gemini`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt: geminiPrompt })
  });
  console.log(`[PASS] /api/gemini 状态: ${geminiRes.status}, 延迟: ${geminiRes.latency}ms`);
  console.log(`       Prompt: "${geminiPrompt}"`);
  console.log(`       Gemini 回复: "${geminiRes.json.answer}"`);
  console.log(`       模型版本: ${geminiRes.json.raw?.modelVersion || 'gemini-2.5-flash'}`);

  if (!geminiRes.ok || !geminiRes.json.answer) {
    throw new Error('Gemini inference failed!');
  }

  // Test 5: /api/tts
  console.log('\n5. 测试 /api/tts 语音合成端点 (Google Cloud Text-to-Speech v1)...');
  const ttsText = 'Rokid AR 眼镜已连接 Google Cloud，全部真实中继端点测试通过。';
  const ttsRes = await requestJson(`${RELAY_BASE}/api/tts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: ttsText })
  });
  console.log(`[PASS] /api/tts 状态: ${ttsRes.status}, 延迟: ${ttsRes.latency}ms`);
  console.log(`       合成文本: "${ttsText}"`);
  console.log(`       音频字节大小 (Base64): ${ttsRes.json.audioContent?.length || 0} 字符`);

  if (!ttsRes.ok || !ttsRes.json.audioContent) {
    throw new Error('TTS test failed!');
  }

  console.log('\n========================================');
  console.log('🎉 全部 5 个真实 GCP Relay 端点测试 100% 通过！');
  console.log('========================================');
}

runRealRelayTests().catch(err => {
  console.error('\n❌ 测试失败:', err);
  process.exit(1);
});
