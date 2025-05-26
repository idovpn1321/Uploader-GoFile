#!/usr/bin/env python3
"""
GoFile Uploader - Simple CLI tool to upload files to GoFile.io
Author: YourName
GitHub: https://github.com/idovpn1321/Uploader-Gofile
"""

import requests
import os
import sys

def get_best_server():
    """Get the best available server from GoFile API"""
    try:
        response = requests.get("https://api.gofile.io/getServer", timeout=10)
        response.raise_for_status()
        data = response.json()
        return data["data"]["server"] if data["status"] == "ok" else "srv-file1"
    except Exception as e:
        print(f"⚠️  Failed to get server: {str(e)}")
        return "srv-file1"  # Default fallback

def upload_file(file_path):
    """Upload file to GoFile"""
    if not os.path.exists(file_path):
        print("❌ Error: File not found!")
        return None

    server = get_best_server()
    file_name = os.path.basename(file_path)

    try:
        with open(file_path, "rb") as f:
            response = requests.post(
                f"https://{server}.gofile.io/uploadFile",
                files={"file": (file_name, f)},
                timeout=30
            )
        data = response.json()
        return data["data"]["downloadPage"] if data["status"] == "ok" else None
    except Exception as e:
        print(f"❌ Upload failed: {str(e)}")
        return None

def main():
    print("\n🔥 GoFile Uploader CLI")
    print("=" * 30)

    file_path = input("📁 Enter file path: ").strip()

    if not file_path:
        print("❌ No file path provided!")
        sys.exit(1)

    print("\n⏳ Uploading...")
    download_url = upload_file(file_path)

    if download_url:
        print("\n✅ Upload Successful!")
        print(f"🔗 Download URL: {download_url}")
    else:
        print("\n❌ Upload failed. Please try again.")

if __name__ == "__main__":
    main()
