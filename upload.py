#!/usr/bin/env python3
"""
GoFile Uploader - Simple CLI tool to upload files to GoFile.io
Author: Idovpn1321
GitHub: https://github.com/idovpn1321/Uploader-Gofile
"""

import requests
import os
from time import sleep

# Daftar server GoFile alternatif (prioritas dari yang paling stabil)
SERVER_LIST = [
    "store1",
    "srv-file1",
    "srv-file2",
    "srv-file3",
    "srv-file4",
    "srv-file5",
    "srv-file6",
    "srv-file7",
    "srv-file8",
    "srv-file9"
]

def upload_to_gofile(file_path):
    """
    Upload file ke GoFile dengan mencoba multiple server
    Returns:
        str: Link download atau None jika semua server gagal
    """
    if not os.path.exists(file_path):
        print("❌ File tidak ditemukan")
        return None

    file_name = os.path.basename(file_path)
    
    for attempt, server in enumerate(SERVER_LIST, 1):
        try:
            print(f"\n🔍 Mencoba Server: {server} (Attempt {attempt}/{len(SERVER_LIST)})")
            
            upload_url = f"https://{server}.gofile.io/uploadFile"
            
            with open(file_path, "rb") as f:
                response = requests.post(
                    upload_url,
                    files={"file": (file_name, f)},
                    timeout=30
                )
            
            data = response.json()
            
            if data.get("status") == "ok":
                print(f"✅ Berhasil di Server: {server}")
                return data["data"]["downloadPage"]
            else:
                print(f"⚠️ Server {server} merespon error: {data.get('message', 'Unknown error')}")
                
        except Exception as e:
            print(f"⚠️ Gagal di Server {server}: {str(e)}")
        
        # Jeda sebentar sebelum coba server berikutnya
        if attempt < len(SERVER_LIST):
            sleep(1)
    
    print("\n❌ Semua server gagal merespon")
    return None

# Contoh penggunaan
if __name__ == "__main__":
    print("🔥 GoFile Multi-Server Uploader")
    print("=" * 40)
    
    file_path = input("Masukkan path file: ").strip()
    
    if not file_path:
        print("⚠️ Harap masukkan path file yang valid")
    else:
        print(f"\n📁 File: {os.path.basename(file_path)}")
        print(f"📏 Ukuran: {os.path.getsize(file_path)/1024:.2f} KB")
        print("\n⏳ Mulai mengupload...")
        
        download_link = upload_to_gofile(file_path)
        
        if download_link:
            print(f"\n🎉 Upload Berhasil!")
            print(f"🔗 Download URL: {download_link}")
        else:
            print("\n😞 Gagal upload setelah mencoba semua server")
