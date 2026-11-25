#Agent Docker Tools 🐳🔧

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

全自动 CTF 渗透 Docker 环境，基于三联动架构（Trae + Docker + Wiki）。

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
├── samples/                # 本地样本（容器内只读，启动时创建）
└── ctf-solutions/          # 报告输出目录（容器内可写）
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

### 方式一：启动（镜像不存在时可能需要构建）

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
docker compose ps
docker compose logs --tail=100 agent
```

## 本地文件分析

执行 `docker compose up -d` 后，把待分析文件放到仓库根目录的 `samples/`。例如，创建一个普通文本文件 `samples/sample.txt`，然后查看文件类型并保存报告：

```bash
docker compose exec -T agent sh -c 'file /root/challenges/sample.txt > /root/ctf-solutions/sample-report.txt'
```

报告保存在宿主机的 `ctf-solutions/sample-report.txt`。容器对 `samples/` 和 `scripts/` 只有读权限。修改脚本时，在宿主机的 `scripts/` 目录编辑。

### GhidraMCP 使用

容器启动时会尝试启动 GhidraMCP。通过 `docker compose logs --tail=100 agent` 查看启动日志。

- MCP SSE 供本机客户端连接，地址为 `http://127.0.0.1:8766/sse`。
- REST API 由容器内的 MCP 桥接进程通过 `127.0.0.1:8089` 访问。

`agent-work/.mcp.json` 已配置本机的 MCP SSE 地址。

### 容器的默认权限

默认使用 Docker 的 seccomp 配置，禁止进程通过执行程序获得额外权限，并移除 `NET_RAW`。需要原始套接字或附加到其他进程的调试操作会受到限制。样本和报告目录均排除在镜像构建上下文之外。

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

`docker-compose.yml` 默认给运行中的容器设置 `host.docker.internal:7897` 代理。如果没有可用代理，请在 `environment` 中删除或注释 `http_proxy` 和 `https_proxy`；需要时再按自己的环境配置。

如构建阶段也需要代理，编辑 `docker-compose.yml`，按实际代理地址配置 build args：

```yaml
build:
  args:
    http_proxy: http://host.docker.internal:7897
    https_proxy: http://host.docker.internal:7897
```

## 参考

- [yhy0/CHYing-agent — 原始项目](https://github.com/yhy0/CHYing-agent)
- [GhidraMCP — 逆向 MCP Server](https://github.com/bethington/ghidra-mcp)
- [doudou0308/ctf-wiki — 配套 CTF 知识图谱](https://github.com/doudou0308/ctf-wiki)

