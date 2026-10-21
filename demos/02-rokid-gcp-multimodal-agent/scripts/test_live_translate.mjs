import fs from 'fs';
import { execSync } from 'child_process';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const WebSocket = require('../server/node_modules/ws');

const PROJECT_ID = process.env.GCP_PROJECT || 'cellular-cider-495602-r9';
const LIVE_MODEL = process.env.LIVE_TRANSLATE_MODEL || 'gemini-3.5-live-translate-preview';
const ZH_TEXT = '今天的会议改到下午三点，请大家准时参加。';
const AIFF_PATH = '/tmp/zh.aiff';
const PCM16K_PATH = '/tmp/zh_16k.pcm';

const DEFAULT_TAGGED_PROXY_URL =
  process.env.PROXY_URL || 'https://live---rokid-aiui-gcp-proxy-r2vgs5vdkq-uc.a.run.app';

function getGcloudAccessToken() {
  const out = execSync(
    '/Users/jush/Downloads/google-cloud-sdk/bin/gcloud auth application-default print-access-token',
    { encoding: 'utf8', timeout: 10000 }
  );
  const lines = out.trim().split('\n');
  return lines[lines.length - 1].trim();
}

function hasAudiblePcmSample(pcmBuffer, threshold = 8) {
  for (let i = 0; i + 1 < pcmBuffer.length; i += 2) {
    if (Math.abs(pcmBuffer.readInt16LE(i)) > threshold) {
      return true;
    }
  }
  return false;
}

function buildWavBuffer(pcmBuffer, sampleRate = 24000, channels = 1, bitsPerSample = 16) {
  const byteRate = (sampleRate * channels * bitsPerSample) / 8;
  const blockAlign = (channels * bitsPerSample) / 8;
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + pcmBuffer.length, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20); // PCM
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);
  header.write('data', 36);
  header.writeUInt32LE(pcmBuffer.length, 40);
  return Buffer.concat([header, pcmBuffer]);
}

function inspectWavVolume(wavPath) {
  const out = execSync(`ffmpeg -i "${wavPath}" -af volumedetect -f null /dev/null 2>&1`, {
    encoding: 'utf8'
  });
  const meanMatch = out.match(/mean_volume:\s*([-\d.]+)\s*dB/);
  const maxMatch = out.match(/max_volume:\s*([-\d.]+)\s*dB/);
  const durMatch = out.match(/Duration:\s*([0-9:.]+)/);
  return {
    duration: durMatch ? durMatch[1] : 'unknown',
    meanVolumeDb: meanMatch ? parseFloat(meanMatch[1]) : null,
    maxVolumeDb: maxMatch ? parseFloat(maxMatch[1]) : null
  };
}

function prepareChineseSpeechPcm() {
  console.log(`[Prep] Generating Chinese speech via macOS 'say' (Tingting): "${ZH_TEXT}"`);
  execSync(`say -v Tingting -o "${AIFF_PATH}" "${ZH_TEXT}"`);
  execSync(
    `ffmpeg -y -i "${AIFF_PATH}" -f s16le -acodec pcm_s16le -ac 1 -ar 16000 "${PCM16K_PATH}" -loglevel error`
  );
  const pcm = fs.readFileSync(PCM16K_PATH);
  const durationSec = (pcm.length / 32000).toFixed(2);
  console.log(`[Prep] Ready: ${PCM16K_PATH} (${pcm.length} bytes, ${durationSec}s @ 16kHz PCM16 mono)`);
  return pcm;
}

async function runDirectVertexLiveTest(pcmBuffer) {
  console.log('\n=== [1] Direct Host -> Vertex AI Live API (global) Test ===');
  const accessToken = getGcloudAccessToken();
  const wsUrl =
    'wss://aiplatform.googleapis.com/ws/google.cloud.aiplatform.v1beta1.LlmBidiService/BidiGenerateContent';

  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'x-goog-user-project': PROJECT_ID
      }
    });

    const audioChunks = [];
    const inputTranscripts = [];
    const outputTranscripts = [];
    let tStreamStart = 0;
    let tFirstAudio = 0;
    let tLastOutput = 0;
    let finishedStreaming = false;
    let settleTimer = null;

    let settled = false;
    const hardTimeout = setTimeout(() => {
      if (!settled) finishTest();
    }, 13000);

    const finishTest = () => {
      if (settled) return;
      settled = true;
      clearTimeout(hardTimeout);
      if (settleTimer) clearTimeout(settleTimer);
      try {
        ws.terminate();
      } catch (_) {}

      const outPcm = Buffer.concat(audioChunks);
      const wavPath = '/tmp/live_translate_direct_en.wav';
      const jsonPath = '/tmp/live_translate_direct_transcripts.json';
      fs.writeFileSync(wavPath, buildWavBuffer(outPcm, 24000));

      const vol = inspectWavVolume(wavPath);
      const result = {
        mode: 'direct-vertex-global',
        model: LIVE_MODEL,
        firstAudioLatencyMs: tFirstAudio ? tFirstAudio - tStreamStart : null,
        totalElapsedMs: (tLastOutput || Date.now()) - tStreamStart,
        inputTranscript: inputTranscripts.join(''),
        outputTranscript: outputTranscripts.join(''),
        outputPcmBytes: outPcm.length,
        outputAudioChunks: audioChunks.length,
        wavPath,
        volume: vol
      };
      fs.writeFileSync(jsonPath, JSON.stringify(result, null, 2));
      console.log('[Direct Result]', JSON.stringify(result, null, 2));
      resolve(result);
    };

    const resetSettleTimer = () => {
      if (settleTimer) clearTimeout(settleTimer);
      settleTimer = setTimeout(() => {
        if (finishedStreaming && audioChunks.length > 0) {
          finishTest();
        }
      }, 1000);
    };

    ws.on('open', () => {
      console.log('[Direct] WS opened, sending setup...');
      ws.send(
        JSON.stringify({
          setup: {
            model: `projects/${PROJECT_ID}/locations/global/publishers/google/models/${LIVE_MODEL}`,
            generationConfig: {
              responseModalities: ['AUDIO'],
              translationConfig: {
                targetLanguageCode: 'en',
                echoTargetLanguage: false
              }
            },
            inputAudioTranscription: {},
            outputAudioTranscription: {}
          }
        })
      );
    });

    ws.on('message', async (raw) => {
      const msg = JSON.parse(raw.toString('utf8'));
      if (msg.setupComplete) {
        console.log('[Direct] setupComplete:', JSON.stringify(msg.setupComplete));
        tStreamStart = Date.now();
        const chunkBytes = 3200; // 100ms @ 16kHz 16-bit mono
        for (let offset = 0; offset < pcmBuffer.length; offset += chunkBytes) {
          const slice = pcmBuffer.subarray(offset, Math.min(offset + chunkBytes, pcmBuffer.length));
          ws.send(
            JSON.stringify({
              realtimeInput: {
                audio: {
                  data: slice.toString('base64'),
                  mimeType: 'audio/pcm;rate=16000'
                }
              }
            })
          );
          await new Promise((r) => setTimeout(r, 100));
        }
        // Send 1.2s trailing silence at 100ms intervals so continuous stream VAD flushes final words
        const silence = Buffer.alloc(3200).toString('base64');
        for (let i = 0; i < 12; i++) {
          ws.send(
            JSON.stringify({
              realtimeInput: {
                audio: {
                  data: silence,
                  mimeType: 'audio/pcm;rate=16000'
                }
              }
            })
          );
          await new Promise((r) => setTimeout(r, 100));
        }
        ws.send(JSON.stringify({ realtimeInput: { audioStreamEnd: true } }));
        finishedStreaming = true;
        console.log(`[Direct] Finished streaming audio + silence at T+${Date.now() - tStreamStart}ms`);
        resetSettleTimer();
        return;
      }

      const sc = msg.serverContent;
      if (!sc) return;

      if (sc.inputTranscription?.text) {
        inputTranscripts.push(sc.inputTranscription.text);
        console.log(`[Direct IN] ${sc.inputTranscription.text} (${sc.inputTranscription.languageCode || ''})`);
      }
      if (sc.outputTranscription?.text) {
        outputTranscripts.push(sc.outputTranscription.text);
        tLastOutput = Date.now();
        console.log(`[Direct OUT] ${sc.outputTranscription.text} (${sc.outputTranscription.languageCode || ''})`);
        resetSettleTimer();
      }
      if (sc.modelTurn?.parts) {
        for (const part of sc.modelTurn.parts) {
          if (part.inlineData?.data) {
            const buf = Buffer.from(part.inlineData.data, 'base64');
            const audible = hasAudiblePcmSample(buf);
            if (audible) {
              if (!tFirstAudio) {
                tFirstAudio = Date.now();
                console.log(`[Direct] First audio chunk at T+${tFirstAudio - tStreamStart}ms`);
              }
              tLastOutput = Date.now();
              audioChunks.push(buf);
              resetSettleTimer();
            } else if (finishedStreaming && audioChunks.length > 0) {
              finishTest();
              return;
            }
          }
        }
      }
    });

    ws.on('close', (code, reason) => {
      if (!settled) {
        console.log(`[Direct] WS closed (${code}): ${reason?.toString() || ''}`);
        finishTest();
      }
    });

    ws.on('error', (err) => {
      clearTimeout(hardTimeout);
      reject(err);
    });
  });
}

async function verifyUnauthRejected(wsBaseUrl) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`${wsBaseUrl}/ws/live-translate`);
    ws.on('unexpected-response', (req, res) => {
      const code = res.statusCode;
      res.resume();
      ws.terminate();
      if (code === 401) {
        resolve(401);
      } else {
        reject(new Error(`Expected 401 on unauthenticated WS upgrade, got ${code}`));
      }
    });
    ws.on('open', () => {
      ws.terminate();
      reject(new Error('Unauthenticated WS upgrade should not succeed'));
    });
    ws.on('error', () => {});
  });
}

async function runProxyRelayTest(pcmBuffer, proxyHttpUrl) {
  console.log(`\n=== [2] Proxy WS Relay Test (${proxyHttpUrl}) ===`);
  const wsBaseUrl = proxyHttpUrl.replace(/^http/, 'ws');

  const unauthStatus = await verifyUnauthRejected(wsBaseUrl);
  console.log(`[Relay Auth Gate] Unauthenticated /ws/live-translate rejected with HTTP ${unauthStatus}`);

  const authRes = await fetch(`${proxyHttpUrl}/api/auth/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      accountId: 'rokid_live_translate_test_01',
      code: 'test_valid_live_translate_01'
    })
  });
  if (!authRes.ok) {
    throw new Error(`Auth verify failed with HTTP ${authRes.status}`);
  }
  const authData = await authRes.json();
  const sessionToken = authData.sessionToken;
  if (!sessionToken) {
    throw new Error('No sessionToken returned from /api/auth/verify');
  }
  console.log(`[Relay Auth] Acquired session token (prefix: ${sessionToken.slice(0, 20)}...)`);

  const relayWsUrl = `${wsBaseUrl}/ws/live-translate?token=${encodeURIComponent(sessionToken)}&target=en`;

  return new Promise((resolve, reject) => {
    const ws = new WebSocket(relayWsUrl);
    const audioChunks = [];
    const inputTranscripts = [];
    const outputTranscripts = [];
    let tStreamStart = 0;
    let tFirstAudio = 0;
    let turnCompleted = false;

    const timeout = setTimeout(() => {
      ws.terminate();
      reject(new Error('Proxy relay test timed out after 25s'));
    }, 25000);

    const finalize = () => {
      clearTimeout(timeout);
      const tEnd = Date.now();
      try {
        ws.terminate();
      } catch (_) {}

      const outPcm = Buffer.concat(audioChunks);
      const wavPath = '/tmp/live_translate_relay_en.wav';
      const jsonPath = '/tmp/live_translate_relay_transcripts.json';
      fs.writeFileSync(wavPath, buildWavBuffer(outPcm, 24000));
      const vol = inspectWavVolume(wavPath);

      const result = {
        mode: 'proxy-ws-relay',
        proxyUrl: proxyHttpUrl,
        firstAudioLatencyMs: tFirstAudio ? tFirstAudio - tStreamStart : null,
        totalElapsedMs: tEnd - tStreamStart,
        turnCompleteReceived: turnCompleted,
        inputTranscript: inputTranscripts.join(''),
        outputTranscript: outputTranscripts.join(''),
        outputPcmBytes: outPcm.length,
        outputAudioChunks: audioChunks.length,
        wavPath,
        volume: vol
      };
      fs.writeFileSync(jsonPath, JSON.stringify(result, null, 2));
      console.log('[Relay Result]', JSON.stringify(result, null, 2));
      resolve(result);
    };

    ws.on('open', async () => {
      tStreamStart = Date.now();
      const chunkBytes = 3200; // 100ms @ 16kHz 16-bit mono
      for (let offset = 0; offset < pcmBuffer.length; offset += chunkBytes) {
        const slice = pcmBuffer.subarray(offset, Math.min(offset + chunkBytes, pcmBuffer.length));
        ws.send(slice, { binary: true });
        await new Promise((r) => setTimeout(r, 100));
      }
      ws.send(JSON.stringify({ type: 'audio_stream_end' }));
    });

    ws.on('message', (data, isBinary) => {
      if (isBinary) {
        const buf = Buffer.isBuffer(data) ? data : Buffer.from(data);
        if (!tFirstAudio) tFirstAudio = Date.now();
        audioChunks.push(buf);
        return;
      }

      const evt = JSON.parse(data.toString('utf8'));
      if (evt.type === 'input_transcript' && evt.text) {
        inputTranscripts.push(evt.text);
      } else if (evt.type === 'output_transcript' && evt.text) {
        outputTranscripts.push(evt.text);
      } else if (evt.type === 'turn_complete') {
        turnCompleted = true;
        finalize();
      } else if (evt.type === 'error') {
        clearTimeout(timeout);
        reject(new Error(`Relay error event: ${evt.code} - ${evt.message}`));
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function main() {
  const mode = process.argv[2] || 'all';
  const proxyUrl = process.argv[3] || DEFAULT_TAGGED_PROXY_URL;
  const pcmBuffer = prepareChineseSpeechPcm();

  if (mode === 'direct' || mode === 'all') {
    const directRes = await runDirectVertexLiveTest(pcmBuffer);
    if (!directRes.outputTranscript.toLowerCase().includes('meeting')) {
      throw new Error(`Unexpected direct output transcript: ${directRes.outputTranscript}`);
    }
    if (directRes.outputPcmBytes < 48000 || directRes.volume.maxVolumeDb < -35) {
      throw new Error('Direct output WAV is too short or silent');
    }
  }

  if (mode === 'relay' || mode === 'all') {
    const relayRes = await runProxyRelayTest(pcmBuffer, proxyUrl);
    if (!relayRes.turnCompleteReceived) {
      throw new Error('Did not receive turn_complete from relay');
    }
    if (!relayRes.outputTranscript.toLowerCase().includes('meeting')) {
      throw new Error(`Unexpected relay output transcript: ${relayRes.outputTranscript}`);
    }
    if (relayRes.outputPcmBytes < 48000 || relayRes.volume.maxVolumeDb < -35) {
      throw new Error('Relay output WAV is too short or silent');
    }
  }

  console.log('\n✅ ALL LIVE TRANSLATE VERIFICATION CHECKS PASSED');
  process.exit(0);
}

main().catch((err) => {
  console.error('\n❌ LIVE TRANSLATE TEST FAILED:', err);
  process.exit(1);
});
