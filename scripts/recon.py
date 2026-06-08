#!/usr/bin/env python3
"""
CHYing Agent — 快速侦察脚本
对目标 URL/端口/文件做基础侦察，输出结构化结果。

Usage:
    docker exec chying-agent python3 /root/scripts/recon.py http://target:port
    docker exec chying-agent python3 /root/scripts/recon.py target 80
"""

import sys
import subprocess
import json
import urllib.parse


def recon_web(url: str, timeout: int = 15):
    """Web 快速侦察"""
    print(f"[recon] Web target: {url}")
    
    # 请求头部
    try:
        import requests
        r = requests.get(url, timeout=timeout, verify=False, 
                        headers={"User-Agent": "Mozilla/5.0"})
        print(f"[+] Status: {r.status_code}")
        print(f"[+] Headers: {dict(r.headers)}")
        print(f"[+] Body preview: {r.text[:500]}...")
        
        # 常见路径检查
        common_paths = ["robots.txt", ".git/HEAD", ".env", "admin/", 
                       "api/", "swagger.json", "sitemap.xml"]
        for path in common_paths:
            try:
                r2 = requests.get(urllib.parse.urljoin(url, path), 
                                 timeout=5, verify=False)
                if r2.status_code == 200:
                    print(f"[+] Found: {path} ({len(r2.text)} bytes)")
            except:
                pass
    except Exception as e:
        print(f"[-] Request failed: {e}")


def recon_file(filepath: str):
    """文件快速侦察"""
    print(f"[recon] File: {filepath}")
    subprocess.run(["file", filepath])
    subprocess.run(["strings", filepath])
    subprocess.run(["exiftool", filepath])


def recon_binary(filepath: str):
    """二进制快速侦察"""
    print(f"[recon] Binary: {filepath}")
    subprocess.run(["file", filepath])
    result = subprocess.run(["strings", filepath], capture_output=True, text=True)
    # 搜索 flag 模式
    for line in result.stdout.split('\n'):
        if '{' in line and '}' in line:
            print(f"[+] Possible flag: {line.strip()}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: recon.py <url|file>")
        sys.exit(1)
    
    target = sys.argv[1]
    if target.startswith("http"):
        recon_web(target)
    else:
        recon_file(target)
