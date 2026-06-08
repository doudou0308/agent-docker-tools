#!/usr/bin/env python3
"""
CHYing Agent — CTF Solve Script Template
Usage:
    docker exec chying-agent python3 /root/scripts/solve.py
    docker exec chying-agent bash -c "python3 /root/scripts/solve.py > /tmp/out.txt 2>&1"
    docker exec chying-agent cat /tmp/out.txt
"""

import sys
import json
import struct
import hashlib
import subprocess
from pwn import *

context.log_level = 'info'


# ============================================================
# Web 类
# ============================================================
def web_solve(target: str):
    """Web challenge solver template"""
    log.info(f"Web target: {target}")
    # TODO: Implement web exploit logic
    # e.g. requests + SQLi/SSTI/JWT
    return target


# ============================================================
# Pwn 类
# ============================================================
def pwn_solve(target: str, port: int, binary: str = None):
    """Pwn challenge solver template"""
    log.info(f"Pwn target: {target}:{port}")
    
    if binary:
        elf = ELF(binary)
        # TODO: Implement exploit
        # e.g. ROP chain
        pass
    
    conn = remote(target, port)
    # conn.interactive()
    conn.close()
    return


# ============================================================
# Crypto 类
# ============================================================
def crypto_solve(data: str):
    """Crypto challenge solver template"""
    from Crypto.Util.number import *
    import gmpy2
    
    log.info("Crypto challenge")
    # TODO: Implement crypto attack
    # RSA / AES / ECC / PRNG
    return data


# ============================================================
# Reverse 类
# ============================================================
def reverse_solve(binary: str):
    """Reverse challenge solver template"""
    log.info(f"Reverse binary: {binary}")
    
    # Quick analysis
    subprocess.run(["file", binary])
    subprocess.run(["strings", binary])
    
    # TODO: Reverse engineering logic
    return binary


# ============================================================
# Forensics 类
# ============================================================
def forensics_solve(filepath: str):
    """Forensics challenge solver template"""
    log.info(f"Forensics file: {filepath}")
    
    # Quick analysis
    subprocess.run(["file", filepath])
    subprocess.run(["binwalk", "-e", filepath])
    
    # TODO: Extract flag from evidence
    return filepath


# ============================================================
# Main Entry
# ============================================================
def solve():
    log.info("CHYing Agent — Solve Script")
    # Modify this to call the appropriate solver
    # flag = web_solve("http://target:port")
    # flag = pwn_solve("target", 1337, "./challenge.elf")
    # flag = crypto_solve("ciphertext.txt")
    # flag = reverse_solve("./challenge.elf")
    # flag = forensics_solve("evidence.pcap")
    
    flag = "flag{...}"
    print(flag)
    return flag


if __name__ == "__main__":
    flag = solve()
