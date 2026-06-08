# 逆向工程速查

## 快速检查

```bash
file binary
strings binary | head -50
# 加壳检测
python3 -c "data=open('binary','rb').read(); print('UPX' in data or 'UPX!' in data)"
```

## 静态分析

```bash
# ELF
readelf -a binary
objdump -d binary | head -100

# 查字符串搜索 main/flag/check
strings binary | grep -iE '(flag|main|check|key)'
```

## 动态调试

```bash
# GDB
gdb ./binary
# pwndbg: break main / run / disassemble / x/s $rdi
```

## 加壳/混淆处理

| 类型 | 处理方式 |
|------|----------|
| UPX | `upx -d binary` |
| SMC (自修改代码) | GDB断点执行后 dump 内存 |
| VM | 识别 opcode 表 → 反汇编脚本 |
| 花指令 | 识别 jmp/call 混淆模式 → nop 填充 |

## Python 相关

```bash
# PyInstaller 解包
python3 /opt/tools/pyinstxtractor/pyinstxtractor.py binary.exe
# pyc 反编译
python3 -m uncompyle6 binary.pyc
```

## 常见陷阱

- `.rodata` / `.rdata` 段直接存硬编码 flag（先 `strings` 看看）
- 反调试 `ptrace(TRACEME, ...)` → `return 0` patch
- 编译器优化后代码与源码差异大
- GhidraMCP 可用: MCP SSE at http://localhost:8766/sse
