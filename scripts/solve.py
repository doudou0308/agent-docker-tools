#!/usr/bin/env python3
"""
CHYing Agent — CTF Solve Script Template
Usage:
    docker exec chying-agent python3 /root/scripts/solve.py
"""

import sys
from pwn import *


def solve():
    log.info("CHYing Agent — Solve Script")
    
    # Example: connect to remote service
    # conn = remote("challenge.example.com", 1337)
    # conn.interactive()
    
    # Example: process local binary
    # elf = ELF("./challenge.elf")
    # ...

    flag = "flag{...}"
    print(flag)
    return flag


if __name__ == "__main__":
    flag = solve()
