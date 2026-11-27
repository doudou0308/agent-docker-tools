# agent-docker-tools 项目记录

- 容器名为 `agent-docker-tools`，镜像为 `agent-docker-tools:local`。
- 容器内 Ghidra REST 监听 8089，宿主机 SSE 监听 `127.0.0.1:8766`。
- `samples/` 和 `scripts/` 在容器中只读，报告写到 `ctf-solutions/`。
- IDE 使用 `agent-work/.mcp.json`，项目操作说明见 `.claude/CLAUDE.md`，宿主机命令桥是 `scripts/rexec.py`。
- 配套知识库 [ctf-wiki](https://github.com/doudou0308/ctf-wiki)单独维护。
