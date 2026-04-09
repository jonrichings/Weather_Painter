#!/usr/bin/env bash
set -euo pipefail

echo "BOOT: start.sh running"
echo "BOOT: pwd=$(pwd)"
echo "BOOT: listing /"
ls -la /

echo "BOOT: listing /comfyui (if exists)"
ls -la /comfyui || true

echo "BOOT: listing /workspace (if exists)"
ls -la /workspace || true

# Find ComfyUI main.py
echo "BOOT: searching for ComfyUI main.py ..."
COMFY_MAIN="$(python3 - <<'PY'
import os
candidates = ["/comfyui/main.py", "/workspace/ComfyUI/main.py", "/ComfyUI/main.py"]
for c in candidates:
    if os.path.exists(c):
        print(c); raise SystemExit(0)
print("")
PY
)"
if [ -z "$COMFY_MAIN" ]; then
  echo "BOOT: Could not find ComfyUI main.py in expected locations"
  exit 1
fi
echo "BOOT: Found ComfyUI main.py at: $COMFY_MAIN"

COMFY_DIR="$(dirname "$COMFY_MAIN")"
cd "$COMFY_DIR"

echo "BOOT: Starting ComfyUI..."
python3 main.py --listen 127.0.0.1 --port 8188 &
COMFY_PID=$!
echo "BOOT: ComfyUI pid=$COMFY_PID"

echo "BOOT: Waiting for ComfyUI to respond..."
python3 - <<'PY'
import time, urllib.request
url = "http://127.0.0.1:8188/"
for i in range(180):
    try:
        urllib.request.urlopen(url, timeout=1)
        print("BOOT: ComfyUI is up")
        break
    except Exception:
        time.sleep(1)
else:
    raise SystemExit("BOOT: ComfyUI did not start in time")
PY

echo "BOOT: Starting handler..."
cd /app
exec python3 -u /app/handler.py
