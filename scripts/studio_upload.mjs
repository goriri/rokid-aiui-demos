#!/usr/bin/env node
/**
 * Rokid AIUI Global Studio Upload & Metadata Sync Script
 *
 * Safely packages and uploads .aix, cache.zip, icon.png, and review preview media
 * (demo.mp4, cover.png, shot1..3.png) to Aliyun OSS via Metis STS credentials,
 * then updates the existing cloud agent metadata via saveAIUIAgent (+ updateThirdAgent).
 *
 * SAFETY:
 *   --dry-run is ON by default. No OSS PUTs or Metis write calls are executed
 *   unless --execute (or --no-dry-run) is explicitly passed.
 *   All credentials, tokens, and OSS STS keys are redacted in console output.
 */

import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..');

const ENDPOINTS = {
  login: 'https://account-center.rokid.com/v2/login.do',
  accountInfo: 'https://account-center.rokid.com/v3/accountsNoVoiceAuthed.do',
  getAgentList: 'https://rcs-internal.rokid.com/metis/agent/getAIUIAgentList',
  getOssSts: 'https://rcs-internal.rokid.com/metis/user/oss/getOssSts',
  saveAIUIAgent: 'https://rcs-internal.rokid.com/metis/agent/saveAIUIAgent',
  updateThirdAgent: 'https://rcs-internal.rokid.com/metis/agent/updateThirdAgent',
  cozePublish: 'https://rcs-internal.rokid.com/agentStore/developer/cozePublish',
  craftSubmitReview: 'https://rcs-internal.rokid.com/aiuicode/api/craft/project/submit-review'
};

const DEMOS = [
  {
    key: '1',
    slug: '01-rokid-vision-voice-copilot',
    agentId: '059b26f3ffcd47ab8280a2d176b0f88a',
    legacyNames: ['AR随身眼脑助手', 'Vision Voice Copilot'],
    demoDir: path.join(REPO_ROOT, 'demos/01-rokid-vision-voice-copilot'),
    aixRelPath: 'dist/rokid-glasses-copilot.aix',
    iconRelPath: 'assets/icon.png',
    category: 'work',
    categoryName: '工作',
    versionLogSuffix:
      'Global Studio release of Vision Voice Copilot for Rokid Glasses 480x352 monochrome-green HUD with Metis voice Q&A, Cloud Run Gemini vision analysis, and 5Hz IMU telemetry dashboard.',
    permissionPurposes: {
      CAMERA:
        'Used when the user taps the temple in VISION mode to capture a single scene photo (wx.media.createCameraContext().takePhoto) for multimodal object and scene recognition.',
      RECORD_AUDIO:
        'Used when the user triggers voice interaction in CHAT mode to transcribe spoken queries (new SpeechRecognition()) for hands-free Q&A.'
    },
    reviewMediaRelPaths: [
      { type: 'video', relPath: 'assets/review/demo.mp4' },
      { type: 'image', relPath: 'assets/review/cover.png' },
      { type: 'image', relPath: 'assets/review/shot1.png' },
      { type: 'image', relPath: 'assets/review/shot2.png' },
      { type: 'image', relPath: 'assets/review/shot3.png' }
    ]
  },
  {
    key: '2',
    slug: '02-rokid-gcp-multimodal-agent',
    agentId: '68e11a45486e4b279704e1e3c43b4b4b',
    legacyNames: ['GCP多模态助手', 'GCP Multimodal Agent'],
    demoDir: path.join(REPO_ROOT, 'demos/02-rokid-gcp-multimodal-agent'),
    aixRelPath: 'dist/rokid-gcp-multimodal-agent.aix',
    iconRelPath: 'assets/icon.png',
    category: 'work',
    categoryName: '工作',
    versionLogSuffix:
      'Global Studio release of GCP Multimodal Agent for Rokid Glasses 480x352 monochrome-green HUD with Vertex AI Gemini vision Q&A, Cloud Translation bilingual subtitles, and Cloud Run health telemetry.',
    permissionPurposes: {
      CAMERA:
        'Used when the user taps the temple in GEMINI vision mode to capture a scene photo (wx.media.createCameraContext().takePhoto) for Vertex AI Gemini multimodal scene analysis.'
    },
    reviewMediaRelPaths: [
      { type: 'video', relPath: 'assets/review/demo.mp4' },
      { type: 'image', relPath: 'assets/review/cover.png' },
      { type: 'image', relPath: 'assets/review/shot1.png' },
      { type: 'image', relPath: 'assets/review/shot2.png' },
      { type: 'image', relPath: 'assets/review/shot3.png' }
    ]
  }
];

const PERMISSION_DESC_KEY_MAP = {
  INTERNET: 'internetDesc',
  CAMERA: 'cameraDesc',
  RECORD_AUDIO: 'recordaudioDesc',
  SPEAKER: 'speakerDesc',
  ROKID_ACCOUNT: 'accountDesc'
};

function parseArgs(argv) {
  let dryRun = true;
  let demoFilter = 'all';
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--dry-run') {
      dryRun = true;
    } else if (arg === '--execute' || arg === '--no-dry-run') {
      dryRun = false;
    } else if (arg === '--demo' && argv[i + 1]) {
      demoFilter = argv[++i];
    } else if (arg.startsWith('--demo=')) {
      demoFilter = arg.slice('--demo='.length);
    }
  }
  return { dryRun, demoFilter };
}

function loadEnv(envPath) {
  if (!fs.existsSync(envPath)) {
    throw new Error(`Missing .env file at ${envPath}`);
  }
  const raw = fs.readFileSync(envPath, 'utf8');
  const env = {};
  for (const line of raw.split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (m) {
      env[m[1]] = m[2].replace(/^['"]|['"]$/g, '');
    }
  }
  return env;
}

function md5Hex(bufOrStr) {
  return crypto.createHash('md5').update(bufOrStr).digest('hex');
}

function formatUtcCompact(date = new Date()) {
  return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
}

function randomLowerAlnum(len = 10, seedStr = '') {
  const alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  const bytes = seedStr
    ? crypto.createHash('sha256').update(seedStr).digest()
    : crypto.randomBytes(len);
  let out = '';
  for (let i = 0; i < len; i++) {
    out += alphabet[bytes[i % bytes.length] % alphabet.length];
  }
  return out;
}

function redactObject(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(redactObject);
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    const lower = k.toLowerCase();
    if (
      lower.includes('password') ||
      lower.includes('token') ||
      lower.includes('secret') ||
      lower.includes('accesskey') ||
      lower.includes('agentak') ||
      lower === 'authorization'
    ) {
      out[k] = '<REDACTED>';
    } else if (typeof v === 'object' && v !== null) {
      out[k] = redactObject(v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

function parseExistingCacheVersion(codeFilePath, agentId) {
  if (typeof codeFilePath !== 'string' || !codeFilePath.trim()) return 0;
  const re = new RegExp(`${agentId}-cache-v(\\d+)-(\\d{8}T\\d{6}Z)-([a-z0-9]{10})\\.zip`);
  const m = re.exec(codeFilePath);
  return m ? parseInt(m[1], 10) : 0;
}

function validateCacheFileName(agentId, fileName) {
  const re = new RegExp(`^${agentId}-cache-v(\\d+)-(\\d{8}T\\d{6}Z)-([a-z0-9]{10})\\.zip$`);
  return re.test(fileName);
}

function buildCacheZipBuffer(demoDir, topFolderName) {
  const tmpRoot = fs.mkdtempSync('/tmp/rokid-aiui-cache-');
  const stageDir = path.join(tmpRoot, topFolderName);
  const zipPath = path.join(tmpRoot, 'cache.zip');
  try {
    fs.mkdirSync(stageDir, { recursive: true });
    const allowEntries = ['app.js', 'app.json', 'package.json', 'gcp_config.js', 'pages', 'assets/icon.png'];
    for (const rel of allowEntries) {
      const srcPath = path.join(demoDir, rel);
      if (!fs.existsSync(srcPath)) continue;
      const destPath = path.join(stageDir, rel);
      fs.mkdirSync(path.dirname(destPath), { recursive: true });
      fs.cpSync(srcPath, destPath, { recursive: true });
    }
    execFileSync('zip', ['-rq', zipPath, topFolderName], { cwd: tmpRoot });
    return fs.readFileSync(zipPath);
  } finally {
    fs.rmSync(tmpRoot, { recursive: true, force: true });
  }
}

function readAixMetadata(demoDir, aixRelPath) {
  const stdout = execFileSync('npx', ['aix', 'show', aixRelPath], {
    cwd: demoDir,
    encoding: 'utf8'
  });
  const aixShow = JSON.parse(stdout);
  const appJson = JSON.parse(fs.readFileSync(path.join(demoDir, 'app.json'), 'utf8'));
  const pagesList = Array.isArray(appJson.pages) ? appJson.pages : ['pages/index/index'];
  const jsuiPages = pagesList.map((p) => `Page title: , page path: ${p}`).join('\n');
  return {
    aixShow,
    jsuiTitle: aixShow.agentName || '',
    jsuiVersion: aixShow.nativeVersion || '1.0.0',
    jsuiPages,
    jsuiTools: '[]'
  };
}

async function rokidLogin(account, password) {
  const isEmail = account.includes('@');
  const res = await fetch(ENDPOINTS.login, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json;charset=UTF-8',
      deviceType: 'web-n',
      type: 'web-n',
      timetag: String(Date.now())
    },
    body: JSON.stringify({
      deviceOs: 'Mac OS 10.15.7',
      deviceType: 'PC',
      deviceSolution: 'Chrome 120.0.0.0',
      userName: account,
      password: md5Hex(password),
      ...(isEmail ? {} : { regionCode: '+86' })
    })
  });
  const data = await res.json();
  const token = data?.access_token || data?.data?.access_token;
  if (!token) {
    throw new Error(`Rokid login failed (HTTP ${res.status}, code=${data?.code ?? 'unknown'})`);
  }
  return { status: res.status, token };
}

async function fetchAgentList(token) {
  const res = await fetch(ENDPOINTS.getAgentList, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      access_token: token
    },
    body: JSON.stringify({ pageNum: 1, pageSize: 100 })
  });
  const json = await res.json();
  if (!res.ok || (json?.code !== 0 && json?.code !== 1)) {
    throw new Error(`getAIUIAgentList failed: HTTP ${res.status}`);
  }
  return json?.data?.list || [];
}

async function fetchOssSts(token) {
  const res = await fetch(ENDPOINTS.getOssSts, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      access_token: token
    }
  });
  const json = await res.json();
  if (!res.ok || !json?.data?.bucketName) {
    throw new Error(`getOssSts failed: HTTP ${res.status}`);
  }
  return json.data;
}

async function putOssObject(sts, objectKey, buffer, contentType, fileNameForDisposition) {
  const date = new Date().toUTCString();
  const disposition = `inline; filename=${encodeURIComponent(fileNameForDisposition)}`;
  const canonicalizedHeaders = `x-oss-security-token:${sts.sessionToken}\n`;
  const canonicalizedResource = `/${sts.bucketName}/${objectKey}`;
  const stringToSign = `PUT\n\n${contentType}\n${date}\n${canonicalizedHeaders}${canonicalizedResource}`;
  const signature = crypto
    .createHmac('sha1', sts.secretKey)
    .update(stringToSign, 'utf8')
    .digest('base64');

  const url = `https://${sts.bucketName}.${sts.region}.aliyuncs.com/${objectKey}`;
  const res = await fetch(url, {
    method: 'PUT',
    headers: {
      Date: date,
      'Content-Type': contentType,
      'Content-Disposition': disposition,
      'x-oss-security-token': sts.sessionToken,
      Authorization: `OSS ${sts.accessKey}:${signature}`
    },
    body: buffer
  });
  if (!res.ok) {
    throw new Error(`OSS PUT failed for ${objectKey}: HTTP ${res.status}`);
  }
  return `${sts.cdnUrl.replace(/\/+$/, '')}/${objectKey}`;
}

async function main() {
  const { dryRun, demoFilter } = parseArgs(process.argv);
  const env = loadEnv(path.join(REPO_ROOT, '.env'));
  if (!env.ROKID_ACCOUNT || !env.ROKID_PASSWORD) {
    throw new Error('ROKID_ACCOUNT and ROKID_PASSWORD must be set in .env');
  }

  console.log(`[StudioUpload] Mode: ${dryRun ? 'DRY-RUN (no mutations)' : 'EXECUTE (live upload & save)'}`);
  const loginResult = await rokidLogin(env.ROKID_ACCOUNT, env.ROKID_PASSWORD);
  console.log(`[StudioUpload] Login: SUCCESS (HTTP ${loginResult.status}, token=<REDACTED>)`);

  const existingAgents = await fetchAgentList(loginResult.token);
  console.log(`[StudioUpload] Fetched ${existingAgents.length} existing cloud agent(s) from getAIUIAgentList.`);

  const sts = await fetchOssSts(loginResult.token);
  console.log(
    `[StudioUpload] OSS STS ready: bucket=${sts.bucketName}, region=${sts.region}, dir=${sts.directory}, cdn=${sts.cdnUrl}, credentials=<REDACTED>`
  );

  const selectedDemos = DEMOS.filter(
    (d) => demoFilter === 'all' || demoFilter === d.key || demoFilter === d.slug
  );

  const now = new Date();
  const tsMillis = now.getTime();
  const utcCompact = formatUtcCompact(now);
  const baseDir = sts.directory.replace(/\/+$/, '');

  for (const demo of selectedDemos) {
    const cloudAgent = existingAgents.find(
      (a) => a.agentId === demo.agentId || demo.legacyNames.includes(a.agentName)
    );
    if (!cloudAgent) {
      throw new Error(`Could not find existing cloud agent for demo ${demo.slug} (${demo.agentId})`);
    }

    const { aixShow, jsuiTitle, jsuiVersion, jsuiPages, jsuiTools } = readAixMetadata(
      demo.demoDir,
      demo.aixRelPath
    );

    const aixAbsPath = path.join(demo.demoDir, demo.aixRelPath);
    const aixBuf = fs.readFileSync(aixAbsPath);
    const aixMd5 = md5Hex(aixBuf);
    const aixObjectKey = `${baseDir}/${cloudAgent.agentId}-${tsMillis}.aix`;
    const aixCdnUrl = `${sts.cdnUrl.replace(/\/+$/, '')}/${aixObjectKey}`;

    const prevCacheVer = parseExistingCacheVersion(cloudAgent.codeFilePath, cloudAgent.agentId);
    const nextCacheVer = prevCacheVer + 1;
    const cacheRandomId = randomLowerAlnum(10, `${cloudAgent.agentId}:${aixMd5}`);
    const cacheFileName = `${cloudAgent.agentId}-cache-v${nextCacheVer}-${utcCompact}-${cacheRandomId}.zip`;
    if (!validateCacheFileName(cloudAgent.agentId, cacheFileName)) {
      throw new Error(`Generated cache.zip filename failed Studio regex: ${cacheFileName}`);
    }
    const cacheBuf = buildCacheZipBuffer(demo.demoDir, aixShow.agentName);
    const cacheMd5 = md5Hex(cacheBuf);
    const cacheObjectKey = `${baseDir}/cache/${cacheFileName}`;
    const cacheAccelUrl = `https://${sts.bucketName}.oss-accelerate.aliyuncs.com/${cacheObjectKey}`;

    const iconAbsPath = path.join(demo.demoDir, demo.iconRelPath);
    const iconBuf = fs.readFileSync(iconAbsPath);
    const iconMd5 = md5Hex(iconBuf);
    const iconRand = randomLowerAlnum(10, `icon:${cloudAgent.agentId}:${iconMd5}`);
    const iconObjectKey = `${baseDir}/${iconRand}${tsMillis}icon.png`;
    const iconCdnUrl = `${sts.cdnUrl.replace(/\/+$/, '')}/${iconObjectKey}`;

    const plannedPreviewUploads = [];
    const previewMaterials = [];
    for (const item of demo.reviewMediaRelPaths) {
      const absPath = path.join(demo.demoDir, item.relPath);
      if (!fs.existsSync(absPath)) continue;
      const buf = fs.readFileSync(absPath);
      const itemMd5 = md5Hex(buf);
      const baseName = path.basename(absPath);
      const suffix = baseName.slice(-5);
      const rand = randomLowerAlnum(10, `media:${cloudAgent.agentId}:${baseName}:${itemMd5}`);
      const objectKey = `${baseDir}/${rand}${tsMillis}${suffix}`;
      const cdnUrl = `${sts.cdnUrl.replace(/\/+$/, '')}/${objectKey}`;
      plannedPreviewUploads.push({
        type: item.type,
        localPath: path.relative(REPO_ROOT, absPath),
        sizeBytes: buf.length,
        md5: itemMd5,
        objectKey,
        cdnUrl,
        buffer: buf,
        mime: item.type === 'video' ? 'video/mp4' : 'image/png',
        fileName: baseName
      });
      previewMaterials.push({ type: item.type, url: cdnUrl });
    }

    const permissionsList = Array.isArray(aixShow.permissions) ? aixShow.permissions : [];
    const permissionsDescObj = {};
    const needParamObj = {};
    for (const perm of permissionsList) {
      const purpose = demo.permissionPurposes[perm] || '';
      const descKey = PERMISSION_DESC_KEY_MAP[perm] || perm.toLowerCase();
      permissionsDescObj[descKey] = purpose;
      needParamObj[perm] = purpose;
    }

    const versionLog = `v${aixShow.nativeVersion}: ${demo.versionLogSuffix}`;
    const validServerCategories = ['life', 'work', 'entertainment', 'study'];
    const resolvedCategory = validServerCategories.includes(cloudAgent.category)
      ? cloudAgent.category
      : demo.category;

    const savePayload = {
      agentId: cloudAgent.agentId,
      thirdAgentId: cloudAgent.thirdAgentId || cloudAgent.agentId,
      agentName: aixShow.agentName,
      agentVersion: aixShow.nativeVersion,
      nativeVersion: aixShow.nativeVersion,
      category: resolvedCategory,
      categoryName: demo.categoryName,
      description: aixShow.agentDesc,
      agentPrompt: aixShow.agentPrompt,
      prologue: aixShow.agentPrompt,
      versionLog,
      icon: iconCdnUrl,
      filePath: aixCdnUrl,
      fileMd5: aixMd5,
      codeFilePath: cacheObjectKey,
      codeFileMd5: cacheMd5,
      permissions: permissionsList.join(','),
      permissionsDesc: JSON.stringify(permissionsDescObj),
      needParam: JSON.stringify(needParamObj),
      needUserAgree: 0,
      previewMaterials,
      widgets: '[]',
      jsuiTitle,
      jsuiVersion,
      jsuiPages,
      jsuiTools,
      cutParamStr: jsuiTools,
      modelVendor: 'native'
    };

    const updateThirdAgentPayload = {
      ...cloudAgent,
      ...savePayload,
      codeFilePath: cacheObjectKey
    };

    console.log(`\n============================================================`);
    console.log(`[Demo ${demo.key}] ${demo.slug} -> Cloud Agent ${cloudAgent.agentId}`);
    console.log(`  Current Cloud Name/Status : "${cloudAgent.agentName}" (status=${cloudAgent.status}, displayStatus=${cloudAgent.displayStatus})`);
    console.log(`  Target Name / Version     : "${aixShow.agentName}" v${aixShow.nativeVersion} (ink ${aixShow.inkVersion})`);
    console.log(`  Planned OSS PUT #1 (.aix) : ${aixObjectKey} (${aixBuf.length} bytes, md5=${aixMd5})`);
    console.log(`  Planned OSS PUT #2 (cache): ${cacheObjectKey} (${cacheBuf.length} bytes, md5=${cacheMd5}, topDir="${aixShow.agentName}/")`);
    console.log(`  Planned OSS PUT #3 (icon) : ${iconObjectKey} (${iconBuf.length} bytes, md5=${iconMd5})`);
    console.log(`  Planned OSS PUT #4..${3 + plannedPreviewUploads.length} (previewMaterials, ${plannedPreviewUploads.length} files):`);
    for (const media of plannedPreviewUploads) {
      console.log(`    - [${media.type}] ${media.localPath} -> ${media.objectKey} (${media.sizeBytes} bytes, md5=${media.md5})`);
    }
    console.log(`  Planned POST ${ENDPOINTS.saveAIUIAgent}:`);
    console.log(
      JSON.stringify(
        redactObject({
          headers: { 'Content-Type': 'application/json', access_token: '<REDACTED>' },
          body: savePayload
        }),
        null,
        2
      )
    );

    if (!dryRun) {
      await putOssObject(sts, aixObjectKey, aixBuf, 'application/octet-stream', path.basename(aixAbsPath));
      await putOssObject(sts, cacheObjectKey, cacheBuf, 'application/zip', cacheFileName);
      await putOssObject(sts, iconObjectKey, iconBuf, 'image/png', 'icon.png');
      for (const media of plannedPreviewUploads) {
        await putOssObject(sts, media.objectKey, media.buffer, media.mime, media.fileName);
      }

      const updateRes = await fetch(ENDPOINTS.updateThirdAgent, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', access_token: loginResult.token },
        body: JSON.stringify(updateThirdAgentPayload)
      });
      const updateJson = await updateRes.json();
      console.log(
        `  [LIVE] updateThirdAgent response: HTTP ${updateRes.status}, code=${updateJson?.code}, msg=${updateJson?.msg}, nativeVersion=${updateJson?.data?.nativeVersion}`
      );
    }
  }
}

main().catch((err) => {
  console.error(`[StudioUpload] ERROR: ${err.message}`);
  process.exit(1);
});
