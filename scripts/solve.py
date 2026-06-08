#!/usr/bin/env python3
"""
CHYing Agent — CTF Solve Script Template
Usage:
    # Local execution
    python3 solve.py

    # Inside Docker container
    docker exec chying-agent python3 /root/scripts/solve.py
"""

import sys
import json
import struct
import hashlib
from pwn import *


def solve():
    """
    CTF challenge solver template.
    Replace this with your actual exploit logic.
    """
    log.info("CHYing Agent — Solve Script")
    
    # Example: connect to remote service
    # conn = remote("challenge.example.com", 1337)
    # conn.interactive()
    
    # Example: process local binary
    # elf = ELF("./challenge.elf")
    # ...

    flag = "flag{...}"  # Replace with actual flag extraction
    print(flag)
    return flag


if __name__ == "__main__":
    flag = solve()
