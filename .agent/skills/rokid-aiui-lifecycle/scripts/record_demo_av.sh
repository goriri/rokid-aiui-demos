#!/usr/bin/env bash
# Unified HUD Video (screenrecord --display-id <physical_id>) +
# Device Audio (scrcpy --no-video --audio-source=output) +
# Host Question Audio (say + afplay) Recorder & Mixer.
#
# Usage:
#   record_demo_av.sh prep <text> [voice]
#   record_demo_av.sh start [max_sec]
#   record_demo_av.sh say <text> [voice]
#   record_demo_av.sh stop <out.mp4> [contact.png] [trim_sec]
#
# Environment variables:
#   ADB_SERIAL      Target device serial (auto-detected if exactly 1 device is connected)
#   HUD_DISPLAY_ID  Physical SurfaceFlinger display ID (auto-detected from dumpsys if unset)
#   HUD_CROP        FFmpeg crop filter for HUD region (default: 480:352:0:180)
#   WORKDIR         Working directory for intermediate files (default: mktemp -d)
#
# Why screenrecord + scrcpy --no-video:
#   scrcpy video mirroring allocates a secondary Qualcomm display/encoder client that starves
#   Camera3-OutputStream buffers during TakePhoto. Using screenrecord for video + scrcpy --no-video
#   for internal audio capture avoids all Camera3 buffer contention while capturing crystal-clear TTS.

set -euo pipefail

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
fi

HUD_CROP="${HUD_CROP:-480:352:0:180}"
REMOTE_MP4="/sdcard/hud_capture_raw.mp4"

resolve_serial() {
  if [[ -n "${ADB_SERIAL:-}" ]]; then
    printf "%s" "$ADB_SERIAL"
    return 0
  fi
  local devs=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && devs+=("$line")
  done < <(adb devices | awk 'NR>1 && $2=="device" {print $1}')
  if [[ ${#devs[@]} -eq 0 ]]; then
    echo "ERROR: No connected ADB device found (set ADB_SERIAL or connect a device)." >&2
    return 1
  elif [[ ${#devs[@]} -gt 1 ]]; then
    echo "ERROR: Multiple ADB devices found (${devs[*]}). Set ADB_SERIAL explicitly." >&2
    return 1
  fi
  printf "%s" "${devs[0]}"
}

resolve_display_id() {
  local serial="$1"
  if [[ -n "${HUD_DISPLAY_ID:-}" ]]; then
    printf "%s" "$HUD_DISPLAY_ID"
    return 0
  fi
  local did
  did=$(adb -s "$serial" shell dumpsys SurfaceFlinger --display-id 2>/dev/null \
    | awk '/Display [0-9]+/ {for(i=1;i<=NF;i++) if ($i ~ /^[0-9]{5,}$/) {print $i; exit}}' \
    | tr -d '\r')
  if [[ -z "$did" ]]; then
    echo "ERROR: Could not auto-detect physical display ID from SurfaceFlinger (set HUD_DISPLAY_ID)." >&2
    return 1
  fi
  printf "%s" "$did"
}

SERIAL="$(resolve_serial)"
STATE_PTR="${TMPDIR:-/tmp}/rokid_av_workdir_${SERIAL}"
if [[ -n "${WORKDIR:-}" ]]; then
  mkdir -p "$WORKDIR"
elif [[ -f "$STATE_PTR" ]]; then
  WORKDIR="$(cat "$STATE_PTR")"
  mkdir -p "$WORKDIR"
else
  WORKDIR="$(mktemp -d)"
  printf "%s" "$WORKDIR" > "$STATE_PTR"
fi

RAW_MP4="$WORKDIR/av_capture_raw.mp4"
RAW_AUDIO="$WORKDIR/av_capture_raw.opus"
SCRCPY_LOG="$WORKDIR/av_scrcpy.log"
SR_PID_FILE="$WORKDIR/av_sr.pid"
SCRCPY_PID_FILE="$WORKDIR/av_scrcpy.pid"
START_EPOCH_FILE="$WORKDIR/av_start.epoch"
QUESTIONS_TSV="$WORKDIR/av_questions.tsv"
PREP_AIFF="$WORKDIR/av_q_prep.aiff"
PREP_TXT="$WORKDIR/av_q_prep.txt"
ORIG_SETTINGS_FILE="$WORKDIR/orig_device_settings.env"
KEEP_AWAKE_ACTIVE=0

save_and_wake() {
  local orig_timeout orig_stayon
  orig_timeout=$(adb -s "$SERIAL" shell settings get system screen_off_timeout 2>/dev/null | tr -d '\r' || true)
  if [[ -z "$orig_timeout" || "$orig_timeout" == "null" ]]; then
    orig_timeout=5000
  fi
  orig_stayon=$(adb -s "$SERIAL" shell settings get global stay_on_while_plugged_in 2>/dev/null | tr -d '\r' || true)
  if [[ -z "$orig_stayon" || "$orig_stayon" == "null" ]]; then
    orig_stayon=0
  fi
  printf "%s\n%s\n" "$orig_timeout" "$orig_stayon" > "$ORIG_SETTINGS_FILE"
  adb -s "$SERIAL" shell "settings put system screen_off_timeout 600000; svc power stayon true 2>/dev/null || true; input keyevent 224" >/dev/null 2>&1 || true
}

restore_device_settings() {
  if [[ "${KEEP_AWAKE_ACTIVE:-0}" == "1" ]]; then
    return 0
  fi
  if [[ -n "${SERIAL:-}" && -f "${ORIG_SETTINGS_FILE:-}" ]]; then
    local orig_timeout orig_stayon
    orig_timeout=$(sed -n '1p' "$ORIG_SETTINGS_FILE" 2>/dev/null || echo "5000")
    orig_stayon=$(sed -n '2p' "$ORIG_SETTINGS_FILE" 2>/dev/null || echo "0")
    adb -s "$SERIAL" shell "settings put system screen_off_timeout ${orig_timeout:-5000}; svc power stayon false 2>/dev/null || true; settings put global stay_on_while_plugged_in ${orig_stayon:-0} 2>/dev/null || true" >/dev/null 2>&1 || true
    rm -f "$ORIG_SETTINGS_FILE"
  fi
}

trap restore_device_settings EXIT INT TERM

prep_question() {
  local text="$1"
  local voice="${2:-Samantha}"
  KEEP_AWAKE_ACTIVE=1
  rm -f "$PREP_AIFF" "$PREP_TXT"
  say -v "$voice" -r 180 -o "$PREP_AIFF" "$text"
  printf "%s" "$text" > "$PREP_TXT"
  echo "[record_demo_av] Pre-rendered question audio ($PREP_AIFF): $text"
}

start_recording() {
  local max_sec="${1:-60}"
  local display_id
  display_id="$(resolve_display_id "$SERIAL")"
  save_and_wake
  if [[ -f "$SCRCPY_PID_FILE" ]]; then
    kill -TERM "$(cat "$SCRCPY_PID_FILE")" 2>/dev/null || true
    rm -f "$SCRCPY_PID_FILE"
  fi
  pkill -TERM -f "scrcpy -s $SERIAL" 2>/dev/null || true
  adb -s "$SERIAL" shell "kill -2 \$(pidof screenrecord) 2>/dev/null || true; rm -f $REMOTE_MP4"
  rm -f "$RAW_MP4" "$RAW_AUDIO" "$SCRCPY_LOG" "$START_EPOCH_FILE" "$QUESTIONS_TSV"
  touch "$QUESTIONS_TSV"

  # 1. Start scrcpy audio-only capture (--no-video --audio-source=output)
  scrcpy -s "$SERIAL" \
    --no-video \
    --audio-source=output \
    --audio-codec=opus \
    --record="$RAW_AUDIO" \
    --no-playback \
    --no-window \
    --time-limit="$max_sec" > "$SCRCPY_LOG" 2>&1 &
  local spid=$!
  echo "$spid" > "$SCRCPY_PID_FILE"

  for _ in {1..60}; do
    if [[ -s "$RAW_AUDIO" ]]; then
      break
    fi
    sleep 0.05
  done

  # 2. Start screenrecord on physical HUD display
  adb -s "$SERIAL" shell "screenrecord --display-id $display_id --bit-rate 6000000 --time-limit $max_sec $REMOTE_MP4" &
  local srpid=$!
  echo "$srpid" > "$SR_PID_FILE"
  sleep 0.6

  python3 -c "import time; print(f'{time.time():.3f}')" > "$START_EPOCH_FILE"
  KEEP_AWAKE_ACTIVE=1
  echo "[record_demo_av] Recording started (scrcpy PID $spid, sr PID $srpid, display $display_id, t0=$(cat "$START_EPOCH_FILE"), workdir $WORKDIR)"
}

play_question() {
  local text="$1"
  local voice="${2:-Samantha}"
  KEEP_AWAKE_ACTIVE=1
  local idx=0
  if [[ -f "$QUESTIONS_TSV" ]]; then
    idx=$(wc -l < "$QUESTIONS_TSV" | tr -d ' ')
  fi
  local q_aiff="$WORKDIR/av_q_${idx}.aiff"
  if [[ -f "$PREP_AIFF" && -f "$PREP_TXT" && "$(cat "$PREP_TXT")" == "$text" ]]; then
    cp "$PREP_AIFF" "$q_aiff"
  else
    say -v "$voice" -r 180 -o "$q_aiff" "$text"
  fi
  local t0=0
  if [[ -f "$START_EPOCH_FILE" ]]; then
    t0=$(cat "$START_EPOCH_FILE")
  fi
  local offset
  offset=$(python3 -c "import time; print(f'{max(0.0, time.time() - float(\"$t0\")):.3f}')")
  printf "%s\t%s\t%s\n" "$offset" "$q_aiff" "$text" >> "$QUESTIONS_TSV"
  echo "[record_demo_av] Playing question @ +${offset}s ($q_aiff): $text"
  afplay "$q_aiff"
}

stop_and_mux() {
  local out_mp4="$1"
  local contact_png="${2:-}"
  local trim_sec="${3:-}"
  KEEP_AWAKE_ACTIVE=0

  # Stop screenrecord on device
  adb -s "$SERIAL" shell "kill -2 \$(pidof screenrecord) 2>/dev/null || true"
  if [[ -f "$SR_PID_FILE" ]]; then
    wait "$(cat "$SR_PID_FILE")" 2>/dev/null || true
    rm -f "$SR_PID_FILE"
  fi

  # Stop scrcpy audio-only capture on host
  if [[ -f "$SCRCPY_PID_FILE" ]]; then
    local spid
    spid=$(cat "$SCRCPY_PID_FILE")
    kill -TERM "$spid" 2>/dev/null || true
    for _ in {1..40}; do
      if ! kill -0 "$spid" 2>/dev/null; then
        break
      fi
      sleep 0.1
    done
    rm -f "$SCRCPY_PID_FILE"
  fi
  pkill -TERM -f "scrcpy -s $SERIAL" 2>/dev/null || true
  sleep 0.8

  adb -s "$SERIAL" pull "$REMOTE_MP4" "$RAW_MP4" >/dev/null

  python3 - "$RAW_MP4" "$RAW_AUDIO" "$QUESTIONS_TSV" "$out_mp4" "$trim_sec" "$HUD_CROP" << 'PYEOF'
import os
import subprocess
import sys

raw_mp4, raw_audio, questions_tsv, out_mp4, trim_sec, hud_crop = sys.argv[1:7]

dur_str = subprocess.check_output([
    "ffprobe", "-v", "error", "-show_entries", "format=duration",
    "-of", "default=nw=1:nk=1", raw_mp4
], text=True).strip()
raw_dur = float(dur_str)
target_dur = min(raw_dur, float(trim_sec)) if trim_sec else raw_dur

questions = []
if os.path.exists(questions_tsv):
    with open(questions_tsv, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 2 and os.path.exists(parts[1]):
                questions.append((float(parts[0]), parts[1], parts[2] if len(parts) > 2 else ""))

cmd = ["ffmpeg", "-y", "-v", "error", "-i", raw_mp4]
if trim_sec:
    cmd.extend(["-t", str(target_dur)])

has_dev_audio = os.path.exists(raw_audio) and os.path.getsize(raw_audio) > 100
if has_dev_audio:
    cmd.extend(["-i", raw_audio])
else:
    cmd.extend(["-f", "lavfi", "-t", f"{target_dur:.3f}", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000"])

for _, q_path, _ in questions:
    cmd.extend(["-i", q_path])

vf = f"crop={hud_crop},fps=30,scale=in_range=full:out_range=tv,format=yuv420p"

if questions:
    filter_parts = [
        f"[0:v]{vf}[vout]",
        "[1:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=1.6[adev]"
    ]
    mix_inputs = ["[adev]"]
    for i, (offset_s, _, _) in enumerate(questions):
        in_idx = i + 2
        delay_ms = int(round(max(0.0, offset_s) * 1000))
        lbl = f"[aq{i}]"
        filter_parts.append(
            f"[{in_idx}:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=1.8,adelay={delay_ms}|{delay_ms}{lbl}"
        )
        mix_inputs.append(lbl)
    n_in = len(mix_inputs)
    filter_parts.append(
        f"{''.join(mix_inputs)}amix=inputs={n_in}:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.89[aout]"
    )
    cmd.extend([
        "-filter_complex", ";".join(filter_parts),
        "-map", "[vout]", "-map", "[aout]"
    ])
else:
    cmd.extend([
        "-vf", vf,
        "-af", "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=1.6,alimiter=limit=0.89",
        "-map", "0:v:0", "-map", "1:a:0"
    ])

cmd.extend([
    "-c:v", "libx264", "-preset", "fast", "-crf", "18",
    "-pix_fmt", "yuv420p", "-color_range", "tv",
    "-c:a", "aac", "-b:a", "128k", "-ar", "48000", "-ac", "2",
    "-movflags", "+faststart",
    "-shortest",
    out_mp4
])
subprocess.run(cmd, check=True)
PYEOF

  echo "=== Verification Gate: $out_mp4 ==="
  local stats
  stats=$(ffmpeg -v info -i "$out_mp4" -vf "fps=1,signalstats,metadata=mode=print" -f null - 2>&1 | grep "lavfi.signalstats.YMAX=" | cut -d= -f2 || true)
  local total=0
  local nonblack=0
  local min_ymax=999
  local max_ymax=0
  local y yi
  while IFS= read -r y; do
    [[ -z "$y" ]] && continue
    total=$((total + 1))
    yi=${y%.*}
    if (( yi > 20 )); then
      nonblack=$((nonblack + 1))
    fi
    if (( yi < min_ymax )); then min_ymax=$yi; fi
    if (( yi > max_ymax )); then max_ymax=$yi; fi
  done <<< "$stats"

  local pct=0
  if (( total > 0 )); then
    pct=$(( nonblack * 100 / total ))
  fi
  local distinct
  distinct=$(ffmpeg -v info -i "$out_mp4" -vf "mpdecimate" -fps_mode vfr -f null - 2>&1 | grep -Eo "frame=[ ]*[0-9]+" | tail -n 1 | awk -F= '{gsub(/ /,"",$2); print $2}' || true)
  echo "1fps samples: $nonblack/$total (${pct}%) with YMAX>20 (YMAX range: ${min_ymax}..${max_ymax}), mpdecimate distinct frames: ${distinct}"

  echo "=== Audio volumedetect: $out_mp4 ==="
  ffmpeg -i "$out_mp4" -af volumedetect -f null - 2>&1 | grep -E "mean_volume|max_volume" || true

  if [[ -n "$contact_png" ]]; then
    local dur step
    dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$out_mp4")
    step=$(python3 -c "d=float('$dur'); print(max(0.5, d/9.5))")
    ffmpeg -y -v error -i "$out_mp4" -vf "fps=1/${step},scale=240:-1,tile=3x3" -frames:v 1 "$contact_png"
    echo "3x3 contact sheet saved: $contact_png"
  fi

  if (( pct < 90 )); then
    echo "ERROR: Video failed YMAX>20 gate (${pct}% < 90%)" >&2
    return 1
  fi
}

cmd="${1:-}"
case "$cmd" in
  prep)
    prep_question "$2" "${3:-Samantha}"
    ;;
  start)
    start_recording "${2:-60}"
    ;;
  say|ask)
    play_question "$2" "${3:-Samantha}"
    ;;
  stop)
    stop_and_mux "$2" "${3:-}" "${4:-}"
    ;;
  *)
    echo "Usage: $0 {prep <text> [voice]|start [max_sec]|say <text> [voice]|stop <out.mp4> [contact.png] [trim_sec]}" >&2
    exit 1
    ;;
esac
