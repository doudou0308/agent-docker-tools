# 密码学速查

## 前置

```bash
pip install pycryptodome z3-solver sympy gmpy2 hashpumpy fpylll
# RsaCtfTool: /opt/tools/RsaCtfTool/
```

## 快速分类

| 输入 | 攻击方向 |
|------|----------|
| `n, e, c` | RSA攻击 |
| ECC曲线参数+点 | 椭圆曲线攻击 |
| key + ciphertext + mode | 对称密码攻击 |
| 多个密文 | OTP key reuse / 流密码 |
| LFSR / 位移寄存器 | 流密码攻击 |
| 随机数序列 | PRNG攻击 |
| 格/模方程 | 格密码攻击 |

## 快速检查

```bash
python3 -c "from Crypto.Util.number import *; n=<N>; print(f'bits={n.bit_length()}')"
python3 -c "from sympy import factorint; print(factorint(<n>))"
# XOR 快速分析
python3 -c "from pwn import xor; print(xor(bytes.fromhex('<hex>'), b'flag{'))"
# RsaCtfTool 一键
python3 /opt/tools/RsaCtfTool/RsaCtfTool.py -n <n> -e <e> --uncipher <c>
```

## RSA 攻击速查

| 条件 | 攻击 |
|------|------|
| `e=3`, 短明文 | 直接开立方 `gmpy2.iroot(c, 3)` |
| `e=3`, 多组 (n,c) | Hastad Broadcast (CRT+Coppersmith) |
| `d` 小 | Wiener attack (连分数) |
| n 可分解 | `sympy.factorint(n)`; [factordb.com](http://factordb.com) |
| 共模 | 共模攻击: `gcd(e1,e2)=1` 扩展欧几里得 |

## XOR 密钥恢复

```python
from pwn import xor
# 根据文件魔数推 key
data = open('encrypted.bin', 'rb').read()
magic = b'\x89PNG\r\n\x1a\n'  # PNG header
key = xor(data[:len(magic)], magic)
decrypted = xor(data, key * (len(data)//len(key)+1))
```

## AES 攻击决策

| 模式 | 攻击方法 |
|------|----------|
| ECB | Block shuffling / byte-at-a-time / cut-and-paste |
| CBC (无MAC) | IV bit-flip / Padding oracle |
| CTR (nonce复用) | Keystream复用 → XOR明文 |
| GCM (nonce复用) | Forbidden attack → 恢复GHASH密钥 |

## 常见陷阱

- `bytes_to_long`/`long_to_bytes` 方向搞反
- RSA 中 `phi = (p-1)*(q-1)` 但 `p==q` 时特例
- 哈希长度扩展攻击需要知道 `len(secret)`
