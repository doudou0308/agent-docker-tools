# CLAUDE.md — CHYing Agent Workspace

## Usage Workflow
1. Start the container: `docker compose up -d`
2. Execute commands inside container: `docker exec chying-agent <command>`
3. Copy files in/out: `docker cp ...`
4. Read results: `docker exec chying-agent cat /tmp/out.txt`

## Post-Compact Recovery
If you are unsure about your current task, target, or progress after a compact:
> Use **absolute paths** to read files. Current working directory can be inferred from
> system message or `progress.md` path.

1. **Read `progress.md`** — main recovery file
2. **Read `findings.log`** — key findings and evidence ledger
3. **If present, read `hint.md`** — challenge hints
4. **Only if needed, read `attack_timeline.md`** — trace command results

## Key Behaviors (may be lost after compact)
- Redirect large output to files (`cmd > /tmp/out.txt 2>&1`)
- Always use docker exec for container tools
- Keep solution scripts in `scripts/` directory
