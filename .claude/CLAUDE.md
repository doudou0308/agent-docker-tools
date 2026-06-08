# CHYing Agent — Tri-Link Operations

```
┌─────────────────────────────────────────────────────┐
│                    TRAE (Brain)                     │
│   Planning · Reasoning · Orchestration · You        │
├──────────────┬──────────────────┬───────────────────┤
│  DOCKER      │   WIKI           │   THIS REPO       │
│  (Hands)     │   (Memory)       │   (Config)        │
│  Execute     │   Knowledge      │   Dockerfile      │
│  Tools       │   Reference      │   Scripts         │
└──────────────┴──────────────────┴───────────────────┘
```

## 三联动核心规则

### Rule 1: Trae = Brain（你）
- 你是**总指挥**，负责规划 → 决策 → 编排
- 所有工具调用通过 Docker 执行，你本地不做任何安全工具操作
- 卡壳时查 Wiki，不要盲目试错

### Rule 2: Docker = Hands
- **所有命令在容器内执行**，不要在本机装工具
- 标准执行模板：
  ```bash
  docker exec chying-agent bash -c "<command> > /tmp/out.txt 2>&1"
  docker exec chying-agent cat /tmp/out.txt
  ```
- 文件传输：
  ```bash
  docker cp <local_file> chying-agent:/root/
  docker cp chying-agent:/root/<file> ./
  ```
- 也可用 `rexec.py` 脚本简化：
  ```python
  import sys; sys.path.insert(0, '/root/scripts')
  from rexec import sh, cp_to, cp_from
  output = sh("file /root/challenge.elf")
  ```

### Rule 3: Wiki = Memory
- 路径：`C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\`
- **仅当卡壳时检索**，不提前查知识库
- 检索命令：
  ```bash
  grep -ri "<关键词>" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\"
  ```
- 按赛道分类目录：
  - `Wiki/web/` — Web 安全
  - `Wiki/pwn/` — 二进制利用
  - `Wiki/crypto/` — 密码学
  - `Wiki/reverse/` — 逆向工程
  - `Wiki/forensics/` — 取证分析
  - `Wiki/osint/` — 开源情报
  - `Wiki/ai-ml/` — AI/ML 安全
  - `Wiki/misc/` — 杂项

---

## 标准解题流程

### Step 1: 零轮侦察（并行）
```bash
# 同时跑这三条
docker exec chying-agent bash -c "strings /root/<file> | grep -iE '(flag|ctf|pico)\{'"
docker exec chying-agent bash -c "file /root/<file>"
docker exec chying-agent bash -c "binwalk -e /root/<file> 2>/dev/null"
```

### Step 2: 确定赛道
根据侦察结果判断题型，对应使用容器内的工具。

### Step 3: 解题
```bash
# 使用 rexec 编写 exploit
docker exec chying-agent python3 /root/scripts/solve.py
```

### Step 4: 卡壳 → 查 Wiki
同一方向 2 轮无进展时：
```bash
grep -ri "<漏洞类型|工具名|关键词>" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\"
```

### Step 5: 拿 Flag → 停止
**不要做多余分析，flag 到手就结束。**

---

## 常用命令速查

### Docker 容器管理
```bash
docker compose up -d            # 启动
docker compose down             # 停止
docker compose build --no-cache # 重建
```

### 容器内执行
```bash
# 短输出
docker exec chying-agent <command>

# 长输出（写入文件再读取，防截断）
docker exec chying-agent bash -c "<command> > /tmp/out.txt 2>&1"
docker exec chying-agent cat /tmp/out.txt
```

### Wiki 检索速查
```bash
# 常见场景
grep -ri "SQL注入\|sqlmap\|sqli" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\web\\"
grep -ri "栈溢出\|ROP\|ret2" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\pwn\\"
grep -ri "RSA\|AES\|XOR" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\crypto\\"
grep -ri "变种虚拟机\|SMC\|花指令" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\reverse\\"
grep -ri "隐写\|内存取证\|网络取证" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\forensics\\"
```

---

## 项目文件索引

| 文件 | 作用 |
|------|------|
| `Dockerfile` | Docker 镜像构建（30+ 安全工具） |
| `docker-compose.yml` | 容器编排配置 |
| `docker/entrypoint.sh` | 容器启动脚本（GhidraMCP 自启） |
| `agent-work/.mcp.json` | MCP 服务配置 |
| `agent-work/CLAUDE.md` | Agent 行为指令（子） |
| `scripts/rexec.py` | Docker 执行桥接工具 |
| `scripts/solve.py` | 解题脚本模板 |
| `ctf-solutions/` | 解题记录 |
