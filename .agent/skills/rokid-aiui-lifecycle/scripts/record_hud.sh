#!/usr/bin/env bash
# Reusable HUD video recorder for Rokid Glasses (480x352 HUD inside 480x640 physical display).
#
# Usage:
#   record_hud.sh start [max_seconds]
#   record_hud.sh stop <out_hud.mp4> [out_contact_3x3.png] [trim_seconds]
#   record_hud.sh <duration_seconds> <out_hud.mp4> [out_contact_3x3.png]
#
# Environment variables:
#   ADB_SERIAL      Target device serial (auto-detected if exactly 1 device is connected)
#   HUD_DISPLAY_ID  Physical SurfaceFlinger display ID (auto-detected from dumpsys if unset)
#   HUD_CROP        FFmpeg crop filter for HUD region (default: 480:352:0:180)
#   WORKDIR         Working directory for intermediate files (default: mktemp -d)

set -euo pipefail

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
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
STATE_PTR="${TMPDIR:-/tmp}/rokid_hud_workdir_${SERIAL}"
if [[ -n "${WORKDIR:-}" ]]; then
  mkdir -p "$WORKDIR"
elif [[ "${1:-}" != "start" && -f "$STATE_PTR" ]]; then
  WORKDIR="$(cat "$STATE_PTR")"
  mkdir -p "$WORKDIR"
else
  WORKDIR="$(mktemp -d)"
  printf "%s" "$WORKDIR" > "$STATE_PTR"
fi

PID_FILE="$WORKDIR/record_hud.pid"
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

postprocess_and_verify() {
  local raw_mp4="$1"
  local out_mp4="$2"
  local contact_png="${3:-}"
  local trim_sec="${4:-}"

  local trim_args=()
  if [[ -n "$trim_sec" ]]; then
    trim_args=(-t "$trim_sec")
  fi

  ffmpeg -y -v error -i "$raw_mp4" "${trim_args[@]+"${trim_args[@]}"}" \
    -vf "crop=${HUD_CROP},fps=30,scale=in_range=full:out_range=tv,format=yuv420p" \
    -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -color_range tv -movflags +faststart \
    "$out_mp4"

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

cmd="$1"
if [[ "$cmd" == "start" ]]; then
  max_sec="${2:-45}"
  DISPLAY_ID="$(resolve_display_id "$SERIAL")"
  save_and_wake
  adb -s "$SERIAL" shell "kill -2 \$(pidof screenrecord) 2>/dev/null || true; rm -f $REMOTE_MP4"
  adb -s "$SERIAL" shell "screenrecord --display-id $DISPLAY_ID --bit-rate 6000000 --time-limit $max_sec $REMOTE_MP4" &
  echo $! > "$PID_FILE"
  sleep 0.8
  KEEP_AWAKE_ACTIVE=1
  echo "Recording started (host PID $(cat "$PID_FILE"), display $DISPLAY_ID -> $REMOTE_MP4, workdir $WORKDIR)"
elif [[ "$cmd" == "stop" ]]; then
  out_mp4="$2"
  contact_png="${3:-}"
  trim_sec="${4:-}"
  adb -s "$SERIAL" shell "kill -2 \$(pidof screenrecord) 2>/dev/null || true"
  if [[ -f "$PID_FILE" ]]; then
    wait "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
  sleep 1.0
  raw_local="$WORKDIR/raw_$(basename "$out_mp4")"
  adb -s "$SERIAL" pull "$REMOTE_MP4" "$raw_local"
  postprocess_and_verify "$raw_local" "$out_mp4" "$contact_png" "$trim_sec"
else
  dur_sec="$1"
  out_mp4="$2"
  contact_png="${3:-}"
  DISPLAY_ID="$(resolve_display_id "$SERIAL")"
  save_and_wake
  adb -s "$SERIAL" shell "kill -2 \$(pidof screenrecord) 2>/dev/null || true; rm -f $REMOTE_MP4"
  adb -s "$SERIAL" shell "screenrecord --display-id $DISPLAY_ID --bit-rate 6000000 --time-limit $dur_sec $REMOTE_MP4"
  sleep 0.5
  raw_local="$WORKDIR/raw_$(basename "$out_mp4")"
  adb -s "$SERIAL" pull "$REMOTE_MP4" "$raw_local"
  postprocess_and_verify "$raw_local" "$out_mp4" "$contact_png" ""
fi
