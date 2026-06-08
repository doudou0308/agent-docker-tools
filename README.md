# CHYing Agent — Docker Tools 🐳🔧

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

基于[《7天Top 9：我如何让 Claude 手搓一个全自动 CTF 选手》](https://cn-sec.com/archives/4742645.html)的思路构建的全自动 CTF 渗透 Docker 环境。

> **核心理念**：极简工具设计，只给 LLM 最少的选择，但每个选择都足够强大。

## 目录结构

```
chying-agent-docker-tools/
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # 一键启动容器
├── .gitignore
├── README.md
├── docker/
│   └── entrypoint.sh       # 容器入口脚本
├── agent-work/             # Trae IDE Agent 工作区配置
│   ├── .mcp.json           # MCP 服务配置
│   └── CLAUDE.md           # Agent 行为指令
├── scripts/
│   └── solve.py            # 解题脚本模板
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

## Tri-Link: Trae + Docker + Wiki

本项目是 CHYing Agent 三联动架构的 **Docker 执行层**，配套知识库位于：

> **[doudou0308/ctf-wiki](https://github.com/doudou0308/ctf-wiki)** — 面向 LLM Agent 的 CTF 知识图谱
> 238+ 页，覆盖 11 个赛道（Web/Pwn/Crypto/Reverse/Forensics/Misc/AI-ML/云安全/代码审计/恶意软件/OSINT）

联动机制：

| 角色 | 组件 | 职责 |
|------|------|------|
| **Trae** (Brain) | Trae IDE + `.claude/CLAUDE.md` | 规划、推理、编排 |
| **Docker** (Hands) | 本镜像容器 | 执行安全工具、运行脚本 |
| **Wiki** (Memory) | [ctf-wiki](https://github.com/doudou0308/ctf-wiki) | 卡壳时定向检索知识点与 PoC |

标准流程：Trae 规划 → Docker 执行 → 卡壳查 Wiki → 继续推进。详见 `.claude/CLAUDE.md`。

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
