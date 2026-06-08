# CHYing Agent — Project Memory

## Tri-Link Configuration
- **Trae**: Brain — planning, orchestration, reasoning
- **Docker**: Hands — container `chying-agent`, all tool execution
- **Wiki**: Memory — `https://github.com/doudou0308/ctf-wiki`

## Container Status
- Name: `chying-agent`
- Image: `chying-agent-docker-tools:latest`
- Services: GhidraMCP (8089), MCP SSE (8766)

## Key Paths
| Resource | Path |
|----------|------|
| Project root | `.` |
| Agent instructions | `.claude/CLAUDE.md` |
| Docker bridge | `scripts/rexec.py` |
| Solve template | `scripts/solve.py` |
| Wiki root | `https://github.com/doudou0308/ctf-wiki` |
