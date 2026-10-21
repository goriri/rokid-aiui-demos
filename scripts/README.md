# Rokid AIUI Global Studio Upload Scripts

## `studio_upload.mjs`

Automates packaging and uploading `.aix`, `cache.zip` (following Studio's strict `^${agentId}-cache-v(\d+)-(\d{8}T\d{6}Z)-([a-z0-9]{10})\.zip$` regex and single top-level folder rule), `assets/icon.png`, and review preview media (`demo.mp4`, `cover.png`, `shot1..3.png`) to Aliyun OSS (`rokid-arapp`, `oss-ap-southeast-1`), then syncs cloud agent metadata via `saveAIUIAgent` and `updateThirdAgent` (called once per run because the Studio backend auto-increments `nativeVersion` by `+0.0.1` on every save).

### Modes & CLI Flags

- `--dry-run` *(default)*: Read-only verification. Logs in, inspects `getAIUIAgentList`, validates `.aix` metadata and `cache.zip` regex naming, and prints the exact redacted OSS PUTs and `saveAIUIAgent` / `updateThirdAgent` payloads without mutating cloud state.
- `--execute` (or `--no-dry-run`): Performs live OSS uploads and calls `updateThirdAgent` once to persist the draft.
- `--demo <1|2|slug>`: Targets a single demo (`1` = `Vision Voice Copilot`, `2` = `GCP Live Translator`) instead of all configured demos.
- `--create`: Creates a brand-new Studio agent when no existing agent in `getAIUIAgentList` matches the current `app.json` `agentName`:
  1. Calls `POST /metis/agent/saveAIUIAgent` with a bootstrap payload (`nativeVersion: "1.0.0"`, `modelVendor: "native"`) to allocate a new 32-char `agentId` (new Studio agents always start at `1.0.0`).
  2. Uploads `.aix`, `cache-v1-...zip` (with top-level folder `<agentName>/`), `icon.png`, and `previewMaterials` (`demo.mp4`, `cover.png`, `shot1..3.png`) to OSS under the new `agentId`.
  3. Calls `POST /metis/agent/updateThirdAgent` once with full permissions, purpose strings (`permissionsDesc` / `needParam`), and media URLs (used to create `GCP Live Translator` `48c2e202270c469886dde77ef1ecc936` while keeping `GCP Multimodal Agent` `68e11a45486e4b279704e1e3c43b4b4b` under review).

### Usage Examples

- **Dry-run mode (default ON, read-only)**:
  ```bash
  node scripts/studio_upload.mjs --dry-run
  # Target a single demo:
  node scripts/studio_upload.mjs --dry-run --demo 1
  node scripts/studio_upload.mjs --dry-run --demo 2
  # Preview creating a brand-new Studio agent:
  node scripts/studio_upload.mjs --create --demo 2 --dry-run
  ```

- **Live upload & save mode (only when explicitly approved)**:
  ```bash
  node scripts/studio_upload.mjs --execute
  # Create a brand-new Studio agent, upload OSS assets, and save draft:
  node scripts/studio_upload.mjs --create --demo 2 --execute
  ```

### Review Submission Path (`构建与提审`)

1. **Save Draft & Review Assets**: `POST https://rcs-internal.rokid.com/metis/agent/updateThirdAgent` (and `POST https://rcs-internal.rokid.com/metis/agent/saveAIUIAgent` when creating a new agent with `--create`).
2. **Real-Name Gate Check**: `GET https://account-center.rokid.com/v3/accountsNoVoiceAuthed.do` must report `majorCheckStatus === 2 || idcardCheckStatus === 1`.
3. **Submit for Store Review (`确认并提交`)**: `POST https://rcs-internal.rokid.com/agentStore/developer/cozePublish` (with `botId: <agentId>`, `name`, `description`, `prompt`, `logo`, `prologue`, `category`, `modelVendor: "native"`, `versionLog`), then verify `getAIUIAgentList` reports `displayStatus: "checking"`.
   - Secondary Craft BFF endpoint: `POST https://rcs-internal.rokid.com/aiuicode/api/craft/project/submit-review`.
