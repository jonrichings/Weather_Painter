import base64
import requests
import runpod


def handler(event):
    inp = event.get("input", {}) or {}
    image_url = inp.get("image_url")

    if not image_url:
        return {"error": "Missing required field: input.image_url"}

    headers = {
    "User-Agent": "Mozilla/5.0 (compatible; RunpodServerless/1.0; +https://runpod.io)"
}
r = requests.get(image_url, headers=headers, timeout=60)

if r.status_code != 200:
    return {
        "error": f"Failed to fetch image: HTTP {r.status_code}",
        "body": r.text[:200]
    }

image_b64 = base64.b64encode(r.content).decode("utf-8")
return {"image_b64": image_b64}


if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
