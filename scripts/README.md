# Rokid AIUI Global Studio Upload Scripts

## `studio_upload.mjs`

Automates packaging and uploading `.aix`, `cache.zip` (following Studio's strict `^${agentId}-cache-v(\d+)-(\d{8}T\d{6}Z)-([a-z0-9]{10})\.zip$` regex and single top-level folder rule), `assets/icon.png`, and review preview media (`demo.mp4`, `cover.png`, `shot1..3.png`) to Aliyun OSS (`rokid-arapp`, `oss-ap-southeast-1`), then updates existing cloud agent metadata via `saveAIUIAgent` (+ `updateThirdAgent`).

### Usage

- **Dry-run mode (default ON, read-only)**:
  ```bash
  node scripts/studio_upload.mjs --dry-run
  # Or target a single demo:
  node scripts/studio_upload.mjs --dry-run --demo 1
  node scripts/studio_upload.mjs --dry-run --demo 2
  ```

- **Live upload & save mode (only when explicitly approved)**:
  ```bash
  node scripts/studio_upload.mjs --execute
  ```

### Review Submission Endpoints (Reference Only — Not Called Automatically)

1. **Save Draft & Review Assets**: `POST https://rcs-internal.rokid.com/metis/agent/updateThirdAgent` (and `POST https://rcs-internal.rokid.com/metis/agent/saveAIUIAgent`)
2. **Submit for Store Review (`确认并提交`)**: `POST https://rcs-internal.rokid.com/agentStore/developer/cozePublish`
   - Secondary Craft BFF endpoint: `POST https://rcs-internal.rokid.com/aiuicode/api/craft/project/submit-review`
   - Web UI gate: requires real-name verification (`majorCheckStatus === 2 || idcardCheckStatus === 1` from `GET https://account-center.rokid.com/v3/accountsNoVoiceAuthed.do`).
