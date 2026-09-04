import puppeteer from 'puppeteer-core';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const TEMP_BASE = '/tmp/aiui_gcp_capture';
const tempFrames = path.join(TEMP_BASE, 'frames');
const tempScreenshots = path.join(TEMP_BASE, 'screenshots');
const tempRecordings = path.join(TEMP_BASE, 'recordings');

fs.rmSync(TEMP_BASE, { recursive: true, force: true });
fs.mkdirSync(tempFrames, { recursive: true });
fs.mkdirSync(tempScreenshots, { recursive: true });
fs.mkdirSync(tempRecordings, { recursive: true });

const targetUrl = process.argv[2] || 'http://127.0.0.1:63980/';

async function run() {
  console.log(`Connecting to Chrome at /Applications/Google Chrome.app/Contents/MacOS/Google Chrome...`);
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1200,900']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1200, height: 900 });

  page.on('console', msg => {
    console.log('[BROWSER CONSOLE]', msg.text());
  });
  page.on('requestfailed', req => {
    console.log('[REQ FAILED]', req.url(), req.failure()?.errorText);
  });
  page.on('requestfinished', req => {
    if (req.url().includes('8088')) {
      console.log('[RELAY REQ SUCCESS]', req.url(), req.response()?.status());
    }
  });

  console.log(`Navigating to ${targetUrl}...`);
  await page.goto(targetUrl, { waitUntil: 'networkidle0', timeout: 30000 });
  await page.waitForSelector('canvas', { timeout: 15000 });
  await new Promise(r => setTimeout(r, 2000));

  const overviewPath = path.join(tempScreenshots, '01_gcp_simulator_overview.png');
  await page.screenshot({ path: overviewPath });
  console.log('Capturing 01_gcp_simulator_overview.png...');

  const canvasHandle = await page.$('canvas');
  const box = await canvasHandle.boundingBox();
  const clip = {
    x: Math.round(box.x),
    y: Math.round(box.y),
    width: Math.round(box.width),
    height: Math.round(box.height)
  };
  console.log('HUD Canvas bounding box:', clip);

  let frameIdx = 0;
  async function recordFrames(count = 10, delay = 100) {
    for (let i = 0; i < count; i++) {
      const framePath = path.join(tempFrames, `frame_${String(frameIdx).padStart(4, '0')}.png`);
      await page.screenshot({ path: framePath, clip });
      frameIdx++;
      await new Promise(r => setTimeout(r, delay));
    }
  }

  async function clickButton(key) {
    console.log(`Triggering button click: ${key}`);
    const btn = await page.$(`button[data-key="${key}"]`);
    if (btn) {
      await btn.click();
    } else {
      await page.keyboard.press(key);
    }
  }

  // 1. Mode 1: Gemini reticle
  console.log('Capturing 02_gcp_gemini_reticle.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '02_gcp_gemini_reticle.png'), clip });
  await recordFrames(15);

  // 2. Click Enter -> Gemini 2.5 Flash Vision Inference
  console.log('Triggering Gemini 2.5 Flash inference (Enter)...');
  await clickButton('Enter');
  // Wait up to 12s for real Vertex AI response to return from Relay
  await page.waitForFunction(() => {
    const text = document.body.innerText;
    return text.includes('【Vertex AI // Gemini 2.5】') && !text.includes('正在通过 GCP Relay');
  }, { timeout: 15000 }).catch(() => console.log('Timeout waiting for Vertex AI, continuing...'));
  await new Promise(r => setTimeout(r, 600));
  console.log('Capturing 03_gcp_gemini_analyzed.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '03_gcp_gemini_analyzed.png'), clip });
  await recordFrames(15);

  // 3. Switch to Mode 2: AR TRANSLATOR (ArrowDown)
  console.log('Switching to Mode 2: AR TRANSLATOR (ArrowDown)...');
  await clickButton('ArrowDown');
  await new Promise(r => setTimeout(r, 800));
  console.log('Capturing 04_gcp_translate_subtitle.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '04_gcp_translate_subtitle.png'), clip });
  await recordFrames(15);

  // 4. Trigger Next Translation sentence (Enter)
  console.log('Triggering next translated sentence (Enter)...');
  await clickButton('Enter');
  // Wait for real translation response
  await page.waitForFunction(() => {
    const text = document.body.innerText;
    return !text.includes('正在实时翻译');
  }, { timeout: 5000 }).catch(() => {});
  await new Promise(r => setTimeout(r, 600));
  console.log('Capturing 05_gcp_translate_next.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '05_gcp_translate_next.png'), clip });
  await recordFrames(15);

  // 5. Switch to Mode 3: CLOUD CONSOLE (ArrowDown)
  console.log('Switching to Mode 3: CLOUD CONSOLE (ArrowDown)...');
  await clickButton('ArrowDown');
  await new Promise(r => setTimeout(r, 800));
  console.log('Capturing 06_gcp_console_health.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '06_gcp_console_health.png'), clip });
  await recordFrames(15);

  // 6. Cycle back to Gemini (ArrowDown)
  console.log('Cycling back to GEMINI (ArrowDown)...');
  await clickButton('ArrowDown');
  await new Promise(r => setTimeout(r, 800));
  await recordFrames(10);

  console.log(`Recorded total ${frameIdx} frames. Generating high-resolution media...`);

  const mp4Path = path.join(tempRecordings, 'rokid_gcp_demo.mp4');
  const gifPath = path.join(tempRecordings, 'rokid_gcp_demo.gif');

  execSync(`ffmpeg -y -framerate 10 -i "${tempFrames}/frame_%04d.png" -c:v libx264 -pix_fmt yuv420p "${mp4Path}"`, { stdio: 'inherit' });
  console.log('MP4 Video generated:', mp4Path);

  execSync(`ffmpeg -y -framerate 10 -i "${tempFrames}/frame_%04d.png" -vf "split[s0][s1];[s0]palettegen=max_colors=32[p];[s1][p]paletteuse=dither=bayer" "${gifPath}"`, { stdio: 'inherit' });
  console.log('GIF animation generated:', gifPath);

  console.log('Copying media to assets and artifacts...');
  const assetsScreenshots = path.join(projectRoot, 'assets', 'screenshots');
  const assetsRecordings = path.join(projectRoot, 'assets', 'recordings');
  fs.mkdirSync(assetsScreenshots, { recursive: true });
  fs.mkdirSync(assetsRecordings, { recursive: true });

  for (const f of fs.readdirSync(tempScreenshots)) {
    fs.copyFileSync(path.join(tempScreenshots, f), path.join(assetsScreenshots, f));
  }
  for (const f of fs.readdirSync(tempRecordings)) {
    fs.copyFileSync(path.join(tempRecordings, f), path.join(assetsRecordings, f));
  }

  // Copy to conversation artifact media directory
  const artifactMediaDir = '/Users/jush/.gemini/antigravity/brain/0034b021-4463-4213-8959-7fb1de639303/media';
  fs.mkdirSync(artifactMediaDir, { recursive: true });
  for (const f of fs.readdirSync(tempScreenshots)) {
    fs.copyFileSync(path.join(tempScreenshots, f), path.join(artifactMediaDir, f));
  }
  for (const f of fs.readdirSync(tempRecordings)) {
    fs.copyFileSync(path.join(tempRecordings, f), path.join(artifactMediaDir, f));
  }

  await browser.close();
  console.log('ALL GCP DEMO MATERIALS GENERATED SUCCESSFULLY!');
}

run().catch(err => {
  console.error('[Capture Error]', err);
  process.exit(1);
});
