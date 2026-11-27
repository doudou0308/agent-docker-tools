# agent-docker-tools 工作区

从仓库根目录启动 Compose，并在 IDE 中加载 [.mcp.json](.mcp.json)。GhidraMCP 的 SSE 端点是 `http://127.0.0.1:8766/sse`。

本地样本通过 `/root/challenges` 只读访问，报告写入 `/root/ctf-solutions`。宿主机上的命令桥是 [scripts/rexec.py](../scripts/rexec.py)。

容器操作见[项目说明](../.claude/CLAUDE.md)。单独维护的知识库见 [ctf-wiki](https://github.com/doudou0308/ctf-wiki)。
