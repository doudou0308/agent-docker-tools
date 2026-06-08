# 取证分析速查

## 快速检查

```bash
file evidence
strings evidence | grep -iE '(flag|ctf|pico)\{'
binwalk -e evidence
exiftool evidence
```

## 隐写

| 文件类型 | 检查 |
|----------|------|
| PNG/JPEG | `zsteg file.png` / steghide / `strings` |
| 音频 | `sox file.wav` / 频谱图查看 |
| 文件尾部 | `tail -c +<offset> file` / 16进制查看器 |

## 网络取证 (PCAP)

```bash
# 统计
tshark -r capture.pcap -q -z io,phs
# HTTP 对象导出
tshark -r capture.pcap --export-objects http,/tmp/
# 提取 flag 字符串
strings capture.pcap | grep -i flag
```

## 内存取证

```bash
# Volatility3
python3 -m volatility -f memory.dump windows.pslist
python3 -m volatility -f memory.dump windows.cmdline
python3 -m volatility -f memory.dump windows.netscan
```

## 文件恢复

| 操作 | 命令 |
|------|------|
| 文件雕刻 | `foremost -i disk.img -o output/` |
| 删除文件恢复 | `fls -r disk.img` → `icat disk.img <inode>` |
| MFT解析 | 需 MFTECmd 工具 |

## 常见陷阱

- 图片末尾附加 zip → `binwalk -e` 或手动 `unzip image.jpg`
- 文件头损坏 → 16进制修复魔数
- NTFS 流 (ADS): `dir /R`
- 时间戳隐藏在文件属性(ctime/mtime/atime)而非内容中
