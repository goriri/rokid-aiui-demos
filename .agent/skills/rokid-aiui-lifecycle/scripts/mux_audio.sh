#!/usr/bin/env bash
# Host-side TTS & question audio synthesizer + ffmpeg muxer for Rokid Glasses HUD recordings.
#
# Usage (positional):
#   mux_audio.sh <video.mp4> <logcat_file> <start_epoch|auto> <events_spec> [out_video.mp4]
#
# Usage (multi-arg pairs):
#   mux_audio.sh <video.mp4> <logcat_file> <start_epoch|auto> "2.3:What should I wear today?" "tts:0:Wear a light jacket." [out_video.mp4]
#
# Environment variables:
#   WORKDIR         Working directory for intermediate audio files (default: mktemp -d)
#   ADB_SERIAL      Optional target device serial (if device settings need restoration)
#   HUD_DISPLAY_ID  Optional physical display ID override
#   HUD_CROP        Optional crop filter override (default: 480:352:0:180)
#
# Where:
#   <video.mp4>        Input MP4 video (e.g., 480x352 H.264 HUD capture)
#   <logcat_file>      Logcat dump file containing "Speech speak request accepted" (and optionally screenrecord start)
#   <start_epoch|auto> Recording start time as Unix epoch seconds (e.g. 1760930660.624),
#                      logcat time ("10-20 11:24:20.624" or "11:24:20.624"), or "auto" to parse
#                      the `screenrecord --display-id` start timestamp from <logcat_file>.
#   <events_spec>      Either:
#                        1) A JSON array (string or path to .json file) of objects:
#                           [{"time": 2.2, "text": "What should I wear today?", "voice": "Samantha"},
#                            {"time": "tts:0", "text": "Wear a breathable layered jacket."}]
#                        2) One or more "time:text" arguments, where `time` can be:
#                           - relative offset in seconds (e.g. "2.2" or 2.2)
#                           - Unix epoch seconds (e.g. "1760930672.120")
#                           - logcat timestamp (e.g. "11:24:32.120" or "10-20 11:24:32.120")
#                           - "tts:N" or "auto" (uses the N-th "Speech speak request accepted" timestamp from logcat)
#                           - "q:N" (uses the N-th "Key/Touch Event: Enter" + 0.5s offset from logcat)
#   [out_video.mp4]    Optional output MP4 path. Defaults to <video_stem>_with_audio.mp4 (or overwrites if --in-place).

set -euo pipefail

if [[ $# -lt 4 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 <video.mp4> <logcat_file> <start_epoch|auto> <events_json_or_time:text...> [out_video.mp4]" >&2
  exit 1
fi

CREATED_WORKDIR=0
if [[ -z "${WORKDIR:-}" ]]; then
  WORKDIR="$(mktemp -d)"
  CREATED_WORKDIR=1
else
  mkdir -p "$WORKDIR"
fi

cleanup() {
  if [[ "$CREATED_WORKDIR" == "1" && -n "${WORKDIR:-}" && -d "$WORKDIR" ]]; then
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT INT TERM

export WORKDIR

python3 - "$@" << 'PYEOF'
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

args = sys.argv[1:]
in_place = False
if "--in-place" in args:
    in_place = True
    args.remove("--in-place")

video_path = os.path.abspath(args[0])
logcat_path = os.path.abspath(args[1]) if args[1] not in ("-", "none", "null", "") else ""
start_epoch_arg = args[2]
rest = args[3:]

out_video = None
if in_place:
    out_video = video_path
elif len(rest) >= 2 and rest[-1].lower().endswith((".mp4", ".mov", ".mkv")):
    out_video = os.path.abspath(rest[-1])
    rest = rest[:-1]
else:
    stem, ext = os.path.splitext(video_path)
    out_video = f"{stem}_with_audio{ext or '.mp4'}"

if not os.path.exists(video_path):
    raise SystemExit(f"ERROR: Video file not found: {video_path}")

# Probe video duration
dur_out = subprocess.check_output([
    "ffprobe", "-v", "error", "-show_entries", "format=duration",
    "-of", "default=nw=1:nk=1", video_path
], text=True).strip()
video_duration = float(dur_out)

# Helper to parse logcat timestamp "MM-DD HH:MM:SS.mmm" or "HH:MM:SS.mmm" into epoch seconds
LOGCAT_TS_RE = re.compile(r"(?:(\d{2})-(\d{2})\s+)?(\d{2}):(\d{2}):(\d{2})\.(\d{3})")

def parse_logcat_ts(ts_str, default_year=None, default_month=10, default_day=20):
    m = LOGCAT_TS_RE.search(ts_str)
    if not m:
        return None
    mon, day, hh, mm, ss, ms = m.groups()
    year = default_year or datetime.datetime.now().year
    mon = int(mon) if mon else default_month
    day = int(day) if day else default_day
    dt = datetime.datetime(year, mon, day, int(hh), int(mm), int(ss), int(ms) * 1000)
    return dt.timestamp()

# Parse logcat file if present
screenrecord_epochs = []
tts_epochs = []
enter_epochs = []
default_mon, default_day = 10, 20

if logcat_path and os.path.exists(logcat_path):
    with open(logcat_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = LOGCAT_TS_RE.match(line)
            if not m:
                continue
            if m.group(1) and m.group(2):
                default_mon, default_day = int(m.group(1)), int(m.group(2))
            ts = parse_logcat_ts(line[:18], default_month=default_mon, default_day=default_day)
            if ts is None:
                continue
            if "screenrecord" in line and "--display-id" in line and "kill" not in line:
                screenrecord_epochs.append(ts)
            if "Speech speak request accepted" in line:
                tts_epochs.append(ts)
            if "Key/Touch Event: Enter" in line or "KeyUp: Enter" in line:
                enter_epochs.append(ts)

# Resolve recording start epoch
start_epoch = None
if start_epoch_arg.lower() in ("auto", "logcat", "0", ""):
    if screenrecord_epochs:
        start_epoch = screenrecord_epochs[-1]
    else:
        start_epoch = 0.0
else:
    try:
        val = float(start_epoch_arg)
        dt_from_epoch = datetime.datetime.fromtimestamp(val)
        if screenrecord_epochs:
            sr_dt = datetime.datetime.fromtimestamp(screenrecord_epochs[-1])
            if sr_dt.year != dt_from_epoch.year:
                dt_aligned = dt_from_epoch.replace(year=sr_dt.year, month=sr_dt.month, day=sr_dt.day)
                start_epoch = dt_aligned.timestamp()
            else:
                start_epoch = val
        else:
            start_epoch = val
    except ValueError:
        parsed = parse_logcat_ts(start_epoch_arg, default_month=default_mon, default_day=default_day)
        if parsed is None:
            raise SystemExit(f"ERROR: Cannot parse start_epoch '{start_epoch_arg}'")
        start_epoch = parsed

# Parse events list
raw_events = []
if len(rest) == 1:
    spec = rest[0].strip()
    if os.path.exists(spec) and spec.endswith(".json"):
        with open(spec, "r", encoding="utf-8") as f:
            raw_events = json.load(f)
    elif spec.startswith("["):
        raw_events = json.loads(spec)
    else:
        raw_events = [spec]
else:
    raw_events = list(rest)

normalized_events = []
auto_tts_idx = 0

for idx, ev in enumerate(raw_events):
    if isinstance(ev, str):
        m_tts = re.match(r"^(tts:\d+|q:\d+|auto):(.*)$", ev, re.DOTALL)
        m_log = re.match(r"^((?:\d{2}-\d{2}\s+)?\d{2}:\d{2}:\d{2}\.\d{3}):(.*)$", ev, re.DOTALL)
        if m_tts:
            t_spec, txt = m_tts.group(1), m_tts.group(2)
        elif m_log:
            t_spec, txt = m_log.group(1), m_log.group(2)
        elif ":" in ev:
            t_spec, txt = ev.split(":", 1)
        else:
            t_spec, txt = "auto", ev
        ev_dict = {"time": t_spec.strip(), "text": txt.strip()}
    elif isinstance(ev, dict):
        ev_dict = dict(ev)
        if "time" not in ev_dict and "t" in ev_dict:
            ev_dict["time"] = ev_dict["t"]
        if "time" not in ev_dict:
            ev_dict["time"] = "auto"
    else:
        raise SystemExit(f"ERROR: Unsupported event entry: {ev}")

    t_spec = ev_dict.get("time", "auto")
    text = str(ev_dict.get("text", "")).strip()
    if not text:
        continue
    voice = ev_dict.get("voice")
    rate = ev_dict.get("rate")

    offset_sec = 0.0
    is_question = bool(ev_dict.get("is_question", False))
    if isinstance(t_spec, (int, float)):
        val = float(t_spec)
        offset_sec = (val - start_epoch) if (val > 1e9 and start_epoch > 1e9) else val
    else:
        t_str = str(t_spec).strip()
        if t_str == "auto" or t_str.startswith("tts:"):
            t_idx = auto_tts_idx if t_str == "auto" else int(t_str.split(":", 1)[1])
            auto_tts_idx = max(auto_tts_idx, t_idx + 1)
            if t_idx < len(tts_epochs) and start_epoch > 0:
                offset_sec = max(0.0, tts_epochs[t_idx] - start_epoch)
            else:
                raise SystemExit(
                    f"ERROR: Requested TTS index {t_idx} ('{t_str}') but logcat has {len(tts_epochs)} 'Speech speak request accepted' entries."
                )
        elif t_str.startswith("q:"):
            q_idx = int(t_str.split(":", 1)[1])
            is_question = True
            if q_idx < len(enter_epochs) and start_epoch > 0:
                offset_sec = max(0.0, enter_epochs[q_idx] - start_epoch + 0.5)
            else:
                offset_sec = 2.0
        else:
            try:
                val = float(t_str)
                offset_sec = (val - start_epoch) if (val > 1e9 and start_epoch > 1e9) else val
            except ValueError:
                parsed = parse_logcat_ts(t_str, default_month=default_mon, default_day=default_day)
                if parsed is None:
                    raise SystemExit(f"ERROR: Could not parse event time '{t_str}'")
                offset_sec = max(0.0, parsed - start_epoch)

    if not voice:
        voice = "Samantha"
    if not rate:
        rate = 185 if is_question else 190

    offset_sec = max(0.0, min(offset_sec, max(0.0, video_duration - 0.5)))
    normalized_events.append({
        "index": idx,
        "offset_sec": offset_sec,
        "text": text,
        "voice": voice,
        "rate": int(rate),
    })

if not normalized_events:
    raise SystemExit("ERROR: No valid {time, text} audio events provided.")

normalized_events.sort(key=lambda x: x["offset_sec"])

print(f"[mux_audio] Video: {video_path} (duration={video_duration:.2f}s)")
print(f"[mux_audio] Logcat: {logcat_path or 'none'} (start_epoch={start_epoch:.3f}, tts_events_in_logcat={len(tts_epochs)})")

base_workdir = os.environ.get("WORKDIR") or tempfile.gettempdir()
tmpdir = tempfile.mkdtemp(prefix="mux_audio_", dir=base_workdir)
try:
    clip_paths = []
    for i, ev in enumerate(normalized_events):
        aiff_path = os.path.join(tmpdir, f"seg_{i}.aiff")
        wav_path = os.path.join(tmpdir, f"seg_{i}.wav")
        subprocess.run([
            "say", "-v", ev["voice"], "-r", str(ev["rate"]), "-o", aiff_path, ev["text"]
        ], check=True)
        subprocess.run([
            "ffmpeg", "-y", "-v", "error", "-i", aiff_path,
            "-af", "volume=1.6,alimiter=limit=0.89",
            "-ar", "48000", "-ac", "2", wav_path
        ], check=True)
        seg_dur = float(subprocess.check_output([
            "ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "default=nw=1:nk=1", wav_path
        ], text=True).strip())
        ev["duration_sec"] = seg_dur
        ev["wav_path"] = wav_path
        clip_paths.append(wav_path)

    for i in range(1, len(normalized_events)):
        prev_end = normalized_events[i - 1]["offset_sec"] + normalized_events[i - 1]["duration_sec"] + 0.20
        if normalized_events[i]["offset_sec"] < prev_end:
            max_allowed_start = max(0.0, video_duration - normalized_events[i]["duration_sec"] - 0.1)
            normalized_events[i]["offset_sec"] = min(prev_end, max_allowed_start)

    for i, ev in enumerate(normalized_events):
        print(f"  + seg[{i}] @ +{ev['offset_sec']:.2f}s ({ev['duration_sec']:.2f}s, voice={ev['voice']}): {ev['text']}")

    ff_cmd = [
        "ffmpeg", "-y", "-v", "error",
        "-i", video_path,
        "-f", "lavfi", "-t", f"{video_duration:.3f}", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000"
    ]
    for p in clip_paths:
        ff_cmd.extend(["-i", p])

    filter_parts = []
    mix_inputs = ["[1:a]"]
    for i, ev in enumerate(normalized_events):
        input_idx = i + 2
        delay_ms = int(round(ev["offset_sec"] * 1000))
        label = f"[a{i}]"
        filter_parts.append(f"[{input_idx}:a]adelay={delay_ms}|{delay_ms}{label}")
        mix_inputs.append(label)

    amix_count = len(mix_inputs)
    filter_parts.append(
        f"{''.join(mix_inputs)}amix=inputs={amix_count}:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.89[aout]"
    )
    filter_complex = ";".join(filter_parts)

    tmp_out = os.path.join(tmpdir, "out_muxed.mp4")
    ff_cmd.extend([
        "-filter_complex", filter_complex,
        "-map", "0:v:0", "-map", "[aout]",
        "-c:v", "copy",
        "-c:a", "aac", "-b:a", "128k", "-ar", "48000", "-ac", "2",
        "-movflags", "+faststart",
        "-shortest",
        tmp_out
    ])
    subprocess.run(ff_cmd, check=True)
    shutil.move(tmp_out, out_video)
    print(f"[mux_audio] Wrote muxed video: {out_video}")

    vd = subprocess.run(
        ["ffmpeg", "-i", out_video, "-af", "volumedetect", "-f", "null", "-"],
        capture_output=True, text=True
    )
    for line in vd.stderr.splitlines():
        if "volumedetect" in line and ("mean_volume" in line or "max_volume" in line):
            print(f"[mux_audio] {line.strip()}")
finally:
    shutil.rmtree(tmpdir, ignore_errors=True)
PYEOF
