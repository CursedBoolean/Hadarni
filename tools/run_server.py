import socket
import re
import os
import subprocess
import sys

def get_local_ip():
    try:
        # Connect to an external IP to determine local routing interface
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        # Fallback to local network search / localhost
        return "127.0.0.1"

def update_dart_files(ip):
    # We will search relative to project root
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    files_to_update = [
        os.path.join(project_root, "lib/services/whisper_service.dart"),
        os.path.join(project_root, "lib/services/whisper_server_manager.dart"),
    ]
    
    # Matches patterns like:
    # http://192.168.1.10:8000
    # http://192.168.1.13:5000
    # http://127.0.0.1:8000
    # Match group 1 is (http://)
    # Match group 2 is IP address
    # Match group 3 is (:port)
    ip_pattern = re.compile(r"(http://)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)")
    
    for file_path in files_to_update:
        if not os.path.exists(file_path):
            print(f"[Warning] File not found: {file_path}")
            continue
            
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Replace the IP part keeping the http:// and :port
        new_content = ip_pattern.sub(rf"\g<1>{ip}\g<2>", content)
        
        if new_content != content:
            with open(file_path, "w", encoding="utf-8", newline="\n") as f:
                f.write(new_content)
            print(f"[Info] Automatically updated server IP to {ip} in: {os.path.basename(file_path)}")
        else:
            print(f"[Info] Server IP in {os.path.basename(file_path)} is already {ip}")

def main():
    ip = get_local_ip()
    print("=" * 60)
    print(f" Detected local network IP address: {ip}")
    print("=" * 60)
    
    # Automatically rewrite the Dart service files with the detected host IP
    update_dart_files(ip)
    
    print(f"\n[Info] Starting Whisper server on http://{ip}:8000 ...")
    print("[Info] Press Ctrl+C to stop the server.\n")
    
    # We are in tools/ directory when start_whisper.bat runs, but let's change Cwd to project root to run uvicorn correctly.
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(project_root)
    
    try:
        subprocess.run(
            [sys.executable, "-m", "uvicorn", "tools.whisper_server:app", "--host", ip, "--port", "8000"],
            check=True
        )
    except KeyboardInterrupt:
        print("\n[Hadarni] Server stopped by user.")
    except Exception as e:
        print(f"\n[Error] Failed to start server: {e}")

if __name__ == "__main__":
    main()
