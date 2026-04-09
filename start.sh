#!/usr/bin/env bash
set -euo pipefail

echo "BOOT: start.sh running"
echo "BOOT: whoami=$(whoami)"
echo "BOOT: pwd=$(pwd)"
echo "BOOT: ls /"
ls -la / || true

echo "BOOT: find comfy main.py"
python3 - <<'PY'
import os
cands = ["/comfyui/main.py", "/workspace/ComfyUI/main.py", "/ComfyUI/main.py"]
for c in cands:
    print("check", c, os.path.exists(c))
PY

# Try starting ComfyUI from likely locations
for d in /comfyui /workspace/ComfyUI /ComfyUI; do
  if [ -f "$d/main.py" ]; then
    echo "BOOT: starting ComfyUI from $d"
    cd "$d"
    python3 main.py --listen 127.0.0.1 --port 8188 &
    break
  fi
done

echo "BOOT: waiting for 8188..."
python3 - <<'PY'
import time, socket
for i in range(180):
    s = socket.socket()
    try:
        s.settimeout(1)
        s.connect(("127.0.0.1", 8188))
        print("BOOT: port 8188 is open")
        break
    except Exception:
        time.sleep(1)
    finally:
        s.close()
else:
    raise SystemExit("BOOT: port 8188 never opened")
PY

echo "BOOT: starting handler..."
cd /app
exec python3 -u /app/handler.py
