import argparse
import os
import re
import socket
import subprocess
import sys


def get_local_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def update_dart_files(ip: str) -> None:
    """Rewrite the LAN IP in Flutter service files to point at *ip*."""
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    files_to_update = [
        os.path.join(project_root, "lib/services/whisper_service.dart"),
        os.path.join(project_root, "lib/services/whisper_server_manager.dart"),
    ]

    # Matches http(s):// URLs — LAN IPs or previous ngrok addresses
    ip_pattern = re.compile(
        r"(https?://)(?:[\w\-]+\.ngrok(?:-free)?\.app|\d{1,3}(?:\.\d{1,3}){3})(:\d+)?"
    )

    for file_path in files_to_update:
        if not os.path.exists(file_path):
            print(f"[Warning] File not found: {file_path}")
            continue

        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        new_content = ip_pattern.sub(rf"http://{ip}:8000", content)

        if new_content != content:
            with open(file_path, "w", encoding="utf-8", newline="\n") as f:
                f.write(new_content)
            print(f"[Info] Updated server URL to http://{ip}:8000 in: {os.path.basename(file_path)}")
        else:
            print(f"[Info] Server URL in {os.path.basename(file_path)} is already correct.")


def main_lan() -> None:
    """Original LAN mode — binds to the local network IP."""
    ip = get_local_ip()
    print("=" * 60)
    print(f" Detected local network IP address: {ip}")
    print("=" * 60)

    update_dart_files(ip)

    print(f"\n[Info] Starting Whisper server on http://{ip}:8000 ...")
    print("[Info] Press Ctrl+C to stop the server.\n")

    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(project_root)

    try:
        subprocess.run(
            [sys.executable, "-m", "uvicorn", "tools.whisper_server:app",
             "--host", ip, "--port", "8000"],
            check=True,
        )
    except KeyboardInterrupt:
        print("\n[Hadarni] Server stopped by user.")
    except Exception as e:
        print(f"\n[Error] Failed to start server: {e}")


def main_ngrok() -> None:
    """Remote mode — tunnel through ngrok."""
    # ngrok_helper lives in the same package; import lazily so LAN mode
    # has zero dependency on it.
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(project_root)
    sys.path.insert(0, project_root)

    from tools.ngrok_helper import run_with_ngrok  # noqa: PLC0415
    run_with_ngrok()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Hadarni Whisper ASR server launcher"
    )
    parser.add_argument(
        "--ngrok",
        action="store_true",
        help="Tunnel through ngrok for remote access (phone on mobile data, etc.)",
    )
    args = parser.parse_args()

    if args.ngrok:
        main_ngrok()
    else:
        main_lan()


if __name__ == "__main__":
    main()
