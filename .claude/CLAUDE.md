# agent-docker-tools 工作说明

Trae 或 IDE 用于查看本地样本分析结果。样本放在宿主机的 `samples/`，容器从 `/root/challenges` 只读访问。已有的本地分析脚本放在 `scripts/` 并在宿主机编辑。容器把报告写到 `/root/ctf-solutions`。

## 本地样本检查

```sh
docker compose up --build --wait --wait-timeout 180
docker compose exec -T agent file /root/challenges/example.txt
```

通过 `docker compose ps` 查看健康状态，使用 `docker compose logs agent` 排查启动问题。

## 相关文件

- [README](../README.md)提供启动、报告写入和调试命令。
- [IDE 配置](../agent-work/.mcp.json)提供 GhidraMCP 和 Chrome DevTools 连接。
- [命令桥](../scripts/rexec.py)在宿主机运行，能返回容器命令的输出与退出码。
- [ctf-wiki](https://github.com/doudou0308/ctf-wiki)由独立仓库维护。
