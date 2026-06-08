#!/usr/bin/env python3
"""
CHYing Agent — Docker Execution Bridge
Trae <-> Docker 的桥梁，在本地（Trae 侧）运行。

简化 docker exec/cp 调用，让 Agent 不用手写长命令。

Usage:
    from rexec import sh, cp_to, cp_from

    # 执行命令
    out = sh("file /root/challenge.elf")
    out = sh("strings /root/challenge.elf | grep flag")

    # 长输出自动写入 /tmp/out.txt 再读取
    out = sh("nmap -sV 192.168.1.1")  # 自动处理截断

    # 文件传输
    cp_to("solve.py", "/root/")
    cp_from("/root/flag.txt", "./")
"""

import subprocess
import tempfile
import os
import sys

CONTAINER = "chying-agent"
WORK_DIR = "/root"


def sh(cmd: str, workdir: str = WORK_DIR) -> str:
    """
    在 Docker 容器内执行命令，返回输出。

    自动处理：
    - 短命令：直接 docker exec
    - 长命令：写入 /tmp/out.txt 再读取，避免截断
    """
    # 简单命令直接执行
    if len(cmd) < 200:
        full_cmd = [
            "docker", "exec", CONTAINER,
            "bash", "-c", f"cd {workdir} && {cmd}"
        ]
    else:
        # 长命令写入临时文件再执行
        escaped = cmd.replace("'", "'\\''")
        full_cmd = [
            "docker", "exec", CONTAINER,
            "bash", "-c",
            f"cd {workdir} && {cmd} > /tmp/out.txt 2>&1"
        ]
        read_cmd = ["docker", "exec", CONTAINER, "cat", "/tmp/out.txt"]
        try:
            subprocess.run(full_cmd, capture_output=True, text=True, timeout=300)
            result = subprocess.run(read_cmd, capture_output=True, text=True, timeout=30)
            return result.stdout
        except subprocess.TimeoutExpired:
            return "[rexec] TIMEOUT: command exceeded 300s"
        except Exception as e:
            return f"[rexec] ERROR: {e}"

    # 短命令直接执行
    try:
        result = subprocess.run(full_cmd, capture_output=True, text=True, timeout=300)
        out = result.stdout + result.stderr
        # 如果输出较大，自动走文件模式重试
        if len(out) > 5000:
            return sh(f"{cmd} > /tmp/out.txt 2>&1 && cat /tmp/out.txt", workdir)
        return out.strip()
    except subprocess.TimeoutExpired:
        return "[rexec] TIMEOUT: command exceeded 300s"
    except Exception as e:
        return f"[rexec] ERROR: {e}"


def cp_to(local_path: str, container_path: str = WORK_DIR) -> str:
    """将本地文件复制到容器内"""
    target = f"{container_path.rstrip('/')}/{os.path.basename(local_path)}"
    full_cmd = ["docker", "cp", local_path, f"{CONTAINER}:{target}"]
    try:
        result = subprocess.run(full_cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return f"[rexec] Copied {local_path} -> {target}"
        return f"[rexec] CP ERROR: {result.stderr}"
    except Exception as e:
        return f"[rexec] CP ERROR: {e}"


def cp_from(container_path: str, local_dir: str = ".") -> str:
    """从容器内复制文件到本地"""
    full_cmd = ["docker", "cp", f"{CONTAINER}:{container_path}", local_dir]
    try:
        result = subprocess.run(full_cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return f"[rexec] Copied {container_path} -> {local_dir}"
        return f"[rexec] CP ERROR: {result.stderr}"
    except Exception as e:
        return f"[rexec] CP ERROR: {e}"


def run_script(script_path: str) -> str:
    """在容器内执行 /root/scripts/ 下的 Python 脚本"""
    return sh(f"python3 /root/scripts/{os.path.basename(script_path)}")


# CLI 入口
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 rexec.py sh <cmd>")
        print("       python3 rexec.py cp_to <local_path> [container_path]")
        print("       python3 rexec.py cp_from <container_path> [local_dir]")
        sys.exit(1)

    mode = sys.argv[1]
    if mode == "sh":
        print(sh(" ".join(sys.argv[2:])))
    elif mode == "cp_to":
        dest = sys.argv[3] if len(sys.argv) > 3 else WORK_DIR
        print(cp_to(sys.argv[2], dest))
    elif mode == "cp_from":
        dest = sys.argv[3] if len(sys.argv) > 3 else "."
        print(cp_from(sys.argv[2], dest))
