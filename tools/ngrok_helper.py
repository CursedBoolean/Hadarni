"""
Hadarni — ngrok tunnel helper
==============================
Starts uvicorn on localhost:8000 in a background thread, then launches ngrok
and polls its local REST API (http://127.0.0.1:4040/api/tunnels) until a
public HTTPS URL appears.

Usage (called by run_server.py --ngrok):
    from tools.ngrok_helper import run_with_ngrok
    run_with_ngrok()
"""

import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.request
from pathlib import Path

_PORT = 8000
_NGROK_API = "http://127.0.0.1:4040/api/tunnels"
_POLL_INTERVAL = 1.5   # seconds between polls
_POLL_TIMEOUT  = 30    # give up after this many seconds


# ── helpers ───────────────────────────────────────────────────────────────────

def _get_ngrok_url(timeout: float = _POLL_TIMEOUT) -> str:
    """Poll the ngrok local API until a public URL is available."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(_NGROK_API, timeout=3) as resp:
                data = json.loads(resp.read())
            for tunnel in data.get("tunnels", []):
                url: str = tunnel.get("public_url", "")
                if url.startswith("https://"):
                    return url
        except Exception:
            pass
        time.sleep(_POLL_INTERVAL)

    raise RuntimeError(
        f"ngrok did not expose a tunnel after {timeout}s.\n"
        "Make sure ngrok is installed and your auth token is configured:\n"
        "  ngrok config add-authtoken <YOUR_TOKEN>\n"
        "Get a free token at https://dashboard.ngrok.com/get-started/your-authtoken"
    )


def _update_dart_files(url: str) -> None:
    """Rewrite baseUrl in the Flutter service files to point at the ngrok URL."""
    project_root = Path(__file__).parent.parent

    targets = [
        project_root / "lib" / "services" / "whisper_service.dart",
        project_root / "lib" / "services" / "whisper_server_manager.dart",
    ]

    # Matches any http(s):// URL used as the base, including previous ngrok URLs
    pattern = re.compile(
        r"(https?://)(?:[\w\-]+\.ngrok(?:-free)?\.app|\d{1,3}(?:\.\d{1,3}){3})(:\d+)?"
    )

    for path in targets:
        if not path.exists():
            print(f"[Warning] File not found, skipping: {path}")
            continue

        original = path.read_text(encoding="utf-8")

        # Replace any existing URL (LAN IP or previous ngrok URL) with the new one.
        # ngrok HTTPS URLs have no port suffix, so we strip the port group when present.
        new_content = pattern.sub(url, original)

        if new_content != original:
            path.write_text(new_content, encoding="utf-8", newline="\n")
            print(f"[Info] Updated base URL → {url}  in: {path.name}")
        else:
            print(f"[Info] Base URL already set correctly in: {path.name}")


def _start_uvicorn_thread() -> threading.Thread:
    """Launch uvicorn on localhost in a daemon thread so it exits with the process."""
    project_root = Path(__file__).parent.parent

    def _run():
        # Change to project root so `tools.whisper_server` is importable
        os.chdir(project_root)
        subprocess.run(
            [
                sys.executable, "-m", "uvicorn",
                "tools.whisper_server:app",
                "--host", "127.0.0.1",
                "--port", str(_PORT),
            ],
            check=False,
        )

    t = threading.Thread(target=_run, daemon=True, name="uvicorn")
    t.start()
    return t


def _start_ngrok_process() -> subprocess.Popen:
    """Spawn ngrok as a subprocess."""
    return subprocess.Popen(
        ["ngrok", "http", str(_PORT)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


# ── public entry-point ────────────────────────────────────────────────────────

def run_with_ngrok() -> None:
    """
    Full ngrok-mode startup sequence:
      1. Start uvicorn (loopback only) in a background thread.
      2. Start ngrok.
      3. Poll for the public URL and rewrite Dart service files.
      4. Print the URL and block until the user hits Ctrl-C.
    """
    print("\n" + "=" * 60)
    print("  Hadarni Whisper ASR — Remote (ngrok) Mode")
    print("=" * 60)

    print("\n[Step 1] Starting uvicorn on localhost:8000 …")
    _start_uvicorn_thread()
    # Give uvicorn a moment to bind before ngrok tries to connect
    time.sleep(2)

    print("[Step 2] Starting ngrok tunnel …")
    ngrok_proc = _start_ngrok_process()

    try:
        print("[Step 3] Waiting for ngrok to publish a URL …")
        public_url = _get_ngrok_url()

        print("\n" + "=" * 60)
        print(f"  ✅  Public URL:  {public_url}")
        print("=" * 60)
        print("\n[Step 4] Rewriting Dart service files …")
        _update_dart_files(public_url)

        print("\n[Info] Server is live. Press Ctrl-C to stop.\n")

        # Keep the main thread alive while uvicorn + ngrok run in the background
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        print("\n[Hadarni] Shutting down …")
    except RuntimeError as exc:
        print(f"\n[Error] {exc}")
        raise SystemExit(1)
    finally:
        ngrok_proc.terminate()
        ngrok_proc.wait()
        print("[Hadarni] ngrok stopped.")
