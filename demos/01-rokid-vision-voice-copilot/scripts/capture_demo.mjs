import puppeteer from 'puppeteer-core';
import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const url = process.argv[2] || 'http://127.0.0.1:59609/';

// Use /tmp to completely prevent dev server hot-reload file watching
const tempBase = '/tmp/aiui_demo_capture';
const tempScreenshots = path.join(tempBase, 'screenshots');
const tempFrames = path.join(tempBase, 'frames');
const tempRecordings = path.join(tempBase, 'recordings');

const finalScreenshots = path.resolve('assets/simulator');
const finalRecordings = path.resolve('assets/simulator');
const artifactDir = '/Users/jush/.gemini/antigravity/brain/0034b021-4463-4213-8959-7fb1de639303/media';

fs.rmSync(tempBase, { recursive: true, force: true });
fs.mkdirSync(tempScreenshots, { recursive: true });
fs.mkdirSync(tempFrames, { recursive: true });
fs.mkdirSync(tempRecordings, { recursive: true });

fs.mkdirSync(finalScreenshots, { recursive: true });
fs.mkdirSync(finalRecordings, { recursive: true });
fs.mkdirSync(artifactDir, { recursive: true });

async function run() {
  console.log(`Connecting to Chrome at ${chromePath}...`);
  const browser = await puppeteer.launch({
    executablePath: chromePath,
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu', '--window-size=1200,900']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1200, height: 900, deviceScaleFactor: 2 });

  page.on('console', (msg) => console.log('[SIM LOG]', msg.text()));

  console.log(`Navigating to ${url}...`);
  await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });

  await page.waitForSelector('#canvas-host', { timeout: 15000 });
  await new Promise((r) => setTimeout(r, 2500));

  console.log('Capturing 01_simulator_overview.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '01_simulator_overview.png') });

  const hostHandle = await page.$('#canvas-host');
  const box = await hostHandle.boundingBox();
  console.log('HUD Canvas bounding box:', box);

  const clip = {
    x: Math.round(box.x),
    y: Math.round(box.y),
    width: Math.round(box.width),
    height: Math.round(box.height)
  };

  let frameIdx = 0;
  async function recordFrames(count, delayMs = 120) {
    for (let i = 0; i < count; i++) {
      const filename = path.join(tempFrames, `frame_${String(frameIdx).padStart(4, '0')}.png`);
      await page.screenshot({ path: filename, clip });
      frameIdx++;
      if (delayMs > 0) {
        await new Promise((r) => setTimeout(r, delayMs));
      }
    }
  }

  async function clickButton(key) {
    console.log(`Triggering button click: ${key}`);
    const btn = await page.$(`button[data-key="${key}"]`);
    if (btn) {
      await btn.click();
    }
  }

  // 1. Initial State: Mode 1 CHAT (Idle)
  console.log('Capturing 02_hud_chat_mode.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '02_hud_chat_mode.png'), clip });
  await recordFrames(10);

  // 2. Trigger voice turn (Enter)
  console.log('Triggering Chat interaction (Enter)...');
  await clickButton('Enter');
  await new Promise((r) => setTimeout(r, 900));
  console.log('Capturing 03_hud_chat_active.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '03_hud_chat_active.png'), clip });
  await recordFrames(15);

  // 3. Switch to Mode 2: VISION (ArrowDown)
  console.log('Switching to Mode 2: VISION (ArrowDown)...');
  await clickButton('ArrowDown');
  await new Promise((r) => setTimeout(r, 600));
  console.log('Capturing 04_hud_vision_reticle.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '04_hud_vision_reticle.png'), clip });
  await recordFrames(15);

  // 4. Trigger Photo Capture in VISION mode (Enter)
  console.log('Triggering Photo Capture in VISION mode (Enter)...');
  await clickButton('Enter');
  await new Promise((r) => setTimeout(r, 1000));
  console.log('Capturing 05_hud_vision_result.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '05_hud_vision_result.png'), clip });
  await recordFrames(15);

  // 5. Switch to Mode 3: DASHBOARD (ArrowDown)
  console.log('Switching to Mode 3: DASHBOARD (ArrowDown)...');
  await clickButton('ArrowDown');
  await new Promise((r) => setTimeout(r, 600));
  console.log('Capturing 06_hud_dashboard_imu.png...');
  await page.screenshot({ path: path.join(tempScreenshots, '06_hud_dashboard_imu.png'), clip });
  await recordFrames(20);

  // 6. Return back to CHAT mode (ArrowDown)
  console.log('Cycling back to CHAT (ArrowDown)...');
  await clickButton('ArrowDown');
  await new Promise((r) => setTimeout(r, 600));
  await recordFrames(10);

  await browser.close();
  console.log(`Recorded total ${frameIdx} frames. Generating high-resolution media...`);

  // Generate MP4 video
  try {
    execSync(
      `ffmpeg -y -framerate 10 -i "${tempFrames}/frame_%04d.png" -c:v libx264 -pix_fmt yuv420p "${tempRecordings}/rokid_copilot_demo.mp4"`,
      { stdio: 'inherit' }
    );
    console.log(`MP4 Video generated: ${tempRecordings}/rokid_copilot_demo.mp4`);
  } catch (e) {
    console.error('ffmpeg mp4 error:', e);
  }

  // Generate high quality GIF
  try {
    execSync(
      `ffmpeg -y -framerate 10 -i "${tempFrames}/frame_%04d.png" -vf "split[s0][s1];[s0]palettegen=max_colors=32[p];[s1][p]paletteuse=dither=bayer" "${tempRecordings}/rokid_copilot_demo.gif"`,
      { stdio: 'inherit' }
    );
    console.log(`GIF animation generated: ${tempRecordings}/rokid_copilot_demo.gif`);
  } catch (e) {
    console.error('ffmpeg gif error:', e);
  }

  // Copy media to final repository directories and artifact directory
  console.log('Copying media to assets and artifacts...');
  execSync(`cp -r "${tempScreenshots}/"* "${finalScreenshots}/"`);
  execSync(`cp "${tempRecordings}/rokid_copilot_demo.mp4" "${finalRecordings}/"`);
  execSync(`cp "${tempRecordings}/rokid_copilot_demo.gif" "${finalRecordings}/"`);

  execSync(`cp -r "${tempScreenshots}/"* "${artifactDir}/"`);
  execSync(`cp "${tempRecordings}/rokid_copilot_demo.mp4" "${artifactDir}/"`);
  execSync(`cp "${tempRecordings}/rokid_copilot_demo.gif" "${artifactDir}/"`);

  console.log('ALL DEMO MATERIALS GENERATED SUCCESSFULLY!');
}

run().catch((err) => {
  console.error('Capture script error:', err);
  process.exit(1);
});
