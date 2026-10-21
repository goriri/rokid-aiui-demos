#!/usr/bin/env bash
# Content & format verification gate for Rokid Glasses AIUI review videos.
#
# Usage:
#   check_video.sh <video.mp4> [question_slice "a-b"] [tts_slices "a-b,c-d"]
#
# Gates checked:
#   1. Container/codec: H.264 (yuv420p, 480x352) + AAC audio
#   2. Duration: 15.0s <= duration <= 45.0s
#   3. File size: <= 50 MB
#   4. HUD luminance: YMAX > 20 on >= 90% of 1fps samples (HUD region already cropped)
#   5. Visual motion: mpdecimate distinct-frame count > 1
#   6. Audio volume: overall mean_volume > -35.0 dB, plus per-slice mean_volume > -35.0 dB
#   7. Visual inspection artifact: 3x3 contact sheet written to $WORKDIR (or next to video)
#
# Environment variables:
#   WORKDIR  Directory for contact sheet output (default: mktemp -d)

set -euo pipefail

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 <video.mp4> [question_slice \"a-b\"] [tts_slices \"a-b,c-d\"]" >&2
  exit 1
fi

VIDEO="$1"
Q_SLICES="${2:-}"
TTS_SLICES="${3:-}"

if [[ ! -f "$VIDEO" ]]; then
  echo "FAIL [FILE_EXISTS]: Video not found: $VIDEO" >&2
  exit 1
fi

WORKDIR="${WORKDIR:-$(mktemp -d)}"
mkdir -p "$WORKDIR"

python3 - "$VIDEO" "$Q_SLICES" "$TTS_SLICES" "$WORKDIR" << 'PYEOF'
import json
import os
import re
import subprocess
import sys

video_path, q_slices_arg, tts_slices_arg, workdir = sys.argv[1:5]
failures = 0

def report(gate, passed, detail):
    global failures
    status = "PASS" if passed else "FAIL"
    if not passed:
        failures += 1
    print(f"{status} [{gate}]: {detail}")

# 1. Probe container, streams, duration, size
probe_out = subprocess.check_output([
    "ffprobe", "-v", "error",
    "-show_entries", "format=duration,size:stream=index,codec_type,codec_name,pix_fmt,width,height",
    "-of", "json", video_path
], text=True)
info = json.loads(probe_out)

fmt = info.get("format", {})
duration = float(fmt.get("duration", 0.0))
size_bytes = int(fmt.get("size", os.path.getsize(video_path)))
size_mb = size_bytes / (1024.0 * 1024.0)

streams = info.get("streams", [])
v_stream = next((s for s in streams if s.get("codec_type") == "video"), {})
a_stream = next((s for s in streams if s.get("codec_type") == "audio"), {})

v_codec = v_stream.get("codec_name", "none")
pix_fmt = v_stream.get("pix_fmt", "none")
width = int(v_stream.get("width", 0))
height = int(v_stream.get("height", 0))
a_codec = a_stream.get("codec_name", "none")

print(
    f"INFO [SUMMARY]: file={video_path} video={v_codec}/{pix_fmt}/{width}x{height} "
    f"audio={a_codec} duration={duration:.2f}s size={size_bytes}B ({size_mb:.2f}MB)"
)

codec_ok = (v_codec == "h264" and pix_fmt == "yuv420p" and width == 480 and height == 352 and a_codec == "aac")
report("CODEC_FORMAT", codec_ok, f"video={v_codec} ({pix_fmt} {width}x{height}), audio={a_codec}")

dur_ok = (15.0 <= duration <= 45.0)
report("DURATION", dur_ok, f"{duration:.2f}s (required 15.0s..45.0s)")

size_ok = (size_bytes <= 50 * 1024 * 1024)
report("FILE_SIZE", size_ok, f"{size_mb:.2f}MB / {size_bytes}B (required <= 50.00MB)")

# 2. YMAX > 20 on >= 90% of 1fps samples
sig_proc = subprocess.run(
    ["ffmpeg", "-v", "info", "-i", video_path, "-vf", "fps=1,signalstats,metadata=mode=print", "-f", "null", "-"],
    capture_output=True, text=True
)
ymax_vals = [float(m.group(1)) for m in re.finditer(r"lavfi\.signalstats\.YMAX=([0-9.]+)", sig_proc.stderr + sig_proc.stdout)]
total_samples = len(ymax_vals)
nonblack_samples = sum(1 for y in ymax_vals if y > 20.0)
pct_nonblack = (nonblack_samples * 100.0 / total_samples) if total_samples > 0 else 0.0
min_y = int(min(ymax_vals)) if ymax_vals else 0
max_y = int(max(ymax_vals)) if ymax_vals else 0
ymax_ok = (total_samples > 0 and pct_nonblack >= 90.0)
report(
    "YMAX_1FPS",
    ymax_ok,
    f"{nonblack_samples}/{total_samples} ({pct_nonblack:.1f}%) samples with YMAX>20 (range {min_y}..{max_y}, required >=90%)"
)

# 3. mpdecimate distinct frame count
mpd_proc = subprocess.run(
    ["ffmpeg", "-v", "info", "-i", video_path, "-vf", "mpdecimate", "-fps_mode", "vfr", "-f", "null", "-"],
    capture_output=True, text=True
)
frame_matches = re.findall(r"frame=\s*(\d+)", mpd_proc.stderr + mpd_proc.stdout)
distinct_frames = int(frame_matches[-1]) if frame_matches else 0
mpd_ok = (distinct_frames > 1)
report("MPDECIMATE", mpd_ok, f"distinct_frames={distinct_frames} (required >1)")

# 4. volumedetect helper
def check_volume(label, ss=None, to=None):
    cmd = ["ffmpeg", "-v", "info"]
    if ss is not None and to is not None:
        cmd.extend(["-ss", str(ss), "-to", str(to)])
    cmd.extend(["-i", video_path, "-af", "volumedetect", "-f", "null", "-"])
    proc = subprocess.run(cmd, capture_output=True, text=True)
    out = proc.stderr + proc.stdout
    m_mean = re.search(r"mean_volume:\s*([-0-9.]+)\s*dB", out)
    m_max = re.search(r"max_volume:\s*([-0-9.]+)\s*dB", out)
    if not m_mean:
        report(label, False, "mean_volume not found (missing audio stream?)")
        return
    mean_db = float(m_mean.group(1))
    max_db = float(m_max.group(1)) if m_max else float("-inf")
    passed = (mean_db > -35.0)
    report(label, passed, f"mean_volume={mean_db:.1f} dB, max_volume={max_db:.1f} dB (required mean > -35.0 dB)")

check_volume("AUDIO_OVERALL")

def parse_and_check_slices(prefix, slices_str):
    if not slices_str.strip():
        return
    for raw_slice in slices_str.split(","):
        s = raw_slice.strip()
        if not s:
            continue
        if "-" not in s:
            report(f"{prefix}[{s}]", False, f"Invalid slice format '{s}' (expected 'start-end')")
            continue
        start_s, end_s = s.split("-", 1)
        check_volume(f"{prefix}[{start_s}-{end_s}s]", float(start_s), float(end_s))

parse_and_check_slices("AUDIO_QUESTION", q_slices_arg)
parse_and_check_slices("AUDIO_TTS", tts_slices_arg)

# 5. Write 3x3 contact sheet
stem = os.path.splitext(os.path.basename(video_path))[0]
contact_path = os.path.join(workdir, f"{stem}_contact_3x3.png")
step = max(0.5, duration / 9.5) if duration > 0 else 1.0
subprocess.run([
    "ffmpeg", "-y", "-v", "error", "-i", video_path,
    "-vf", f"fps=1/{step:.4f},scale=240:-1,tile=3x3",
    "-frames:v", "1", contact_path
], check=True)
cs_ok = (os.path.exists(contact_path) and os.path.getsize(contact_path) > 0)
report("CONTACT_SHEET", cs_ok, f"{contact_path}")

if failures > 0:
    print(f"RESULT: FAILED ({failures} gate(s) failed)")
    sys.exit(1)
print("RESULT: PASSED (all gates passed)")
PYEOF
