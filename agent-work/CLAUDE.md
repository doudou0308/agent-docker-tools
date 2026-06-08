# CHYing Agent — Agent Workspace

> 主操作指令在 `../.claude/CLAUDE.md`（仓库根级），本文件为 agent-work 工作区补充。

## Tri-Link
- **Trae** (Brain) → 你负责规划编排
- **Docker** (Hands) → 所有命令通过 `rexec.py` 或 `docker exec chying-agent` 执行
- **Wiki** (Memory) → 卡壳时查 `https://github.com/doudou0308/ctf-wiki`

## 容器内脚本路径
- 解题脚本: `/root/scripts/solve.py`
- `rexec` 桥接: `/root/scripts/rexec.py`（也支持从宿主机 import）

## 快速执行
```python
import sys; sys.path.insert(0, '.')
from scripts.rexec import sh, cp_to, cp_from

out = sh("file /root/challenge.elf")
cp_to("solve.py", "/root/")
sh("python3 /root/scripts/solve.py")
```
