#!/usr/bin/env python3
"""Run commands and copy files between the host and the local analysis container."""

import subprocess
import shlex
import os
import sys

CONTAINER = "agent-docker-tools"
WORK_DIR = "/root"


def run(cmd: str, workdir: str = WORK_DIR, timeout: float = 300) -> subprocess.CompletedProcess:
    """执行一次命令，保留 stdout、stderr 与退出码。"""
    return subprocess.run(
        ["docker", "exec", "-w", workdir, CONTAINER, "bash", "-c", cmd],
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def sh(cmd: str, workdir: str = WORK_DIR) -> str:
    """返回合并后的文本输出，兼容旧调用方。"""
    try:
        result = run(cmd, workdir)
        return (result.stdout + result.stderr).strip()
    except subprocess.TimeoutExpired:
        return "[rexec] TIMEOUT: command exceeded 300s"
    except (OSError, UnicodeError) as exc:
        return f"[rexec] ERROR: {exc}"


def _copy(source: str, destination: str, success_message: str):
    try:
        result = subprocess.run(
            ["docker", "cp", source, destination], capture_output=True, text=True, timeout=30
        )
    except subprocess.TimeoutExpired as exc:
        return 124, f"[rexec] CP ERROR: {exc}"
    except (OSError, ValueError) as exc:
        return 1, f"[rexec] CP ERROR: {exc}"

    if result.returncode == 0:
        return 0, success_message
    status = result.returncode if result.returncode > 0 else 128 - result.returncode
    return status, f"[rexec] CP ERROR: {result.stderr}"


def _copy_to(local_path: str, container_path: str):
    target = f"{container_path.rstrip('/')}/{os.path.basename(local_path)}"
    return _copy(local_path, f"{CONTAINER}:{target}", f"[rexec] Copied {local_path} -> {target}")


def _copy_from(container_path: str, local_dir: str):
    return _copy(f"{CONTAINER}:{container_path}", local_dir, f"[rexec] Copied {container_path} -> {local_dir}")


def cp_to(local_path: str, container_path: str = WORK_DIR) -> str:
    """将本地文件复制到容器内。"""
    return _copy_to(local_path, container_path)[1]


def cp_from(container_path: str, local_dir: str = ".") -> str:
    """从容器内复制文件到本地。"""
    return _copy_from(container_path, local_dir)[1]


def run_script(script_path: str) -> str:
    """在容器内执行 /root/scripts/ 下的 Python 脚本"""
    script = shlex.quote(os.path.basename(script_path))
    return sh(f"python3 /root/scripts/{script}")


# CLI 入口
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 rexec.py sh <cmd>")
        print("       python3 rexec.py cp_to <local_path> [container_path]")
        print("       python3 rexec.py cp_from <container_path> [local_dir]")
        sys.exit(1)

    mode = sys.argv[1]
    if mode == "sh":
        try:
            result = run(" ".join(sys.argv[2:]))
        except subprocess.TimeoutExpired:
            print("[rexec] TIMEOUT: command exceeded 300s", file=sys.stderr)
            sys.exit(124)
        except (OSError, UnicodeError) as exc:
            print(f"[rexec] ERROR: {exc}", file=sys.stderr)
            sys.exit(1)
        sys.stdout.write(result.stdout)
        sys.stderr.write(result.stderr)
        sys.exit(result.returncode)
    if mode in ("cp_to", "cp_from"):
        copy, default_dest = (_copy_to, WORK_DIR) if mode == "cp_to" else (_copy_from, ".")
        dest = sys.argv[3] if len(sys.argv) > 3 else default_dest
        status, message = copy(sys.argv[2], dest)
        print(message, file=sys.stderr if status else sys.stdout)
        sys.exit(status)
