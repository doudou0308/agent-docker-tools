# CHYing Agent — Docker Tools 🐳🔧

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

基于[《7天Top 9：我如何让 Claude 手搓一个全自动 CTF 选手》](https://cn-sec.com/archives/4742645.html)的思路构建的全自动 CTF 渗透 Docker 环境。

> **核心哲学**：极简工具设计，只给 LLM 最少的选择，但每个选择都足够强大。

## 目录结构

```
chying-agent-docker-tools/
├── Dockerfile              # 完整的 Docker 镜像构建文件
├── docker-compose.yml      # 一键启动容器
├── .gitignore
├── README.md
├── docker/
│   └── entrypoint.sh       # 容器入口脚本（启动 GhidraMCP 等服务）
├── .trae/
│   └── memory/
│       └── project_memory.md  # 项目记忆（知识库路径、解题规则、工作流）
├── agent-work/             # Trae IDE Agent 工作区配置
│   ├── .mcp.json           # MCP 服务配置（GhidraMCP, Chrome DevTools）
│   └── CLAUDE.md           # Agent 行为指令
├── scripts/
│   ├── solve.py            # CTF 解题脚本模板（Web/Pwn/Crypto/Reverse/Forensics）
│   └── recon.py            # 快速侦察脚本
├── docs/
│   └── cheatsheets/        # CTF 分类速查表
│       ├── web.md          # Web 安全（SQLi/SSTI/SSRF/JWT/反序列化）
│       ├── pwn.md          # 二进制利用（栈/堆/ROP/格式化字符串）
│       ├── crypto.md       # 密码学（RSA/AES/ECC/PRNG/格密码）
│       ├── reverse.md      # 逆向工程（静态/动态/加壳/VM）
│       └── forensics.md    # 取证分析（磁盘/内存/网络/隐写）
└── ctf-solutions/          # 解题记录输出目录
```

## 内置工具

| 类别 | 工具 |
|------|------|
| **Web 安全** | sqlmap, ffuf, whatweb, nuclei, wpscan, commix, subfinder, arjun, katana, httpx |
| **二进制/Pwn** | pwntools, gdb, pwndbg, ROPGadget, one_gadget, radare2 |
| **逆向** | Ghidra 12.0.3 + GhidraMCP (MCP Server), JADX 1.5.5 |
| **密码学** | RsaCtfTool, gmpy2, pycryptodome, z3-solver, hashcat, john |
| **取证** | binwalk, foremost, sleuthkit, tshark, volatility3, steghide, exiftool |
| **Java 反序列化** | ysoserial |
| **其他** | jwt_tool, tplmap, XSStrike, Gopherus, phpggc, Metasploit, nuclei-templates, vulhub, SecLists |

## 快速开始

### 方式一：使用已有镜像（推荐）

```bash
docker compose up -d
```

### 方式二：从 Dockerfile 构建

```bash
docker compose build
docker compose up -d
```

### 验证容器运行

```bash
docker ps | grep chying-agent
```

## 典型工作流

```bash
# 1. 启动容器
docker compose up -d

# 2. 将解题脚本/文件复制到容器
docker cp solve.py chying-agent:/root/
docker cp challenge.elf chying-agent:/root/

# 3. 在容器内执行命令
docker exec chying-agent python3 /root/solve.py

# 4. 执行并将结果写入文件（推荐用于长输出）
docker exec chying-agent bash -c "python3 /root/solve.py > /tmp/out.txt 2>&1"
docker exec chying-agent cat /tmp/out.txt
```

### GhidraMCP 使用

容器启动后自动运行 GhidraMCP（约需 30-60 秒初始化）。

- REST API: `http://localhost:8089`
- MCP SSE: `http://localhost:8766/sse`

在 `agent-work/.mcp.json` 中已配置好 MCP 连接。

## 分类速查表

`docs/cheatsheets/` 目录提供五大 CTF 类别的命令速查：

| 速查表 | 前置准备 | 快速侦察 | 核心攻击 | 常见陷阱 |
|--------|---------|---------|---------|---------|
| [web.md](docs/cheatsheets/web.md) | pip install | curl/gobuster | SQLi/SSTI/SSRF/JWT | URL 编码失真 |
| [pwn.md](docs/cheatsheets/pwn.md) | pwntools/ROPgadget | checksec | ret2/ROP/格式化字符串 | movaps 栈对齐 |
| [crypto.md](docs/cheatsheets/crypto.md) | pycryptodome/gmpy2 | 参数识别 | RSA/AES/PRNG/格 | phi 特例 |
| [reverse.md](docs/cheatsheets/reverse.md) | GhidraMCP/objdump | file/strings | SMC/VM/加壳 | .rodata 硬编码 |
| [forensics.md](docs/cheatsheets/forensics.md) | binwalk/volatility3 | file/binwalk | 隐写/雕刻/MFT | 文件末尾附加 |

## 脚本辅助

```bash
# 快速侦察（URL/文件）
docker exec chying-agent python3 /root/scripts/recon.py http://target:port
docker exec chying-agent python3 /root/scripts/recon.py challenge.elf

# 解题模板（修改 solve.py 调用对应类别函数）
docker exec chying-agent python3 /root/scripts/solve.py
```

## 知识库

本项目配合你的本地知识库使用：

- **Obsidian Wiki（217 页）**: `C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\`
- **Trae Skills（118 个）**: `C:\Users\ZZH\.trae\skills\`
- **项目记忆**: `.trae/memory/project_memory.md` 自动关联

解题时 Trae Agent 优先查 `docs/cheatsheets/` 速查表，卡壳时自动检索知识库。

## Trae IDE 集成

本项目专为 Trae IDE + Claude Agent 设计。将项目在 Trae 中打开后：

1. Agent 自动读取 `agent-work/CLAUDE.md` 获取工作指令
2. 通过 `.mcp.json` 连接 GhidraMCP 和 Chrome DevTools
3. 解题脚本和结果同步到 `ctf-solutions/` 目录

## 构建代理配置

如果需要在代理环境下构建，编辑 `docker-compose.yml` 取消代理设置注释：

```yaml
build:
  args:
    http_proxy: http://host.docker.internal:7897
    https_proxy: http://host.docker.internal:7897
```

## 参考

- [原文：7天Top 9：我如何让 Claude 手搓一个全自动 CTF 选手](https://cn-sec.com/archives/4742645.html)
- [yhy0/CHYing-agent — 原始项目](https://github.com/yhy0/CHYing-agent)
- [GhidraMCP — 逆向 MCP Server](https://github.com/bethington/ghidra-mcp)
