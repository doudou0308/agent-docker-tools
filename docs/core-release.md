# agent-docker-tools 核心版

在 Linux amd64 上运行的本地文件分析环境，包含 Ghidra、GhidraMCP、`file`、`gdb` 和常用二进制检查工具。需要 Docker Engine 和 Docker Compose。

## 构建和运行

解压后进入 `agent-docker-tools-core` 目录。在其中运行以下命令，检查一个文本样本并将报告写回宿主机。

~~~sh
printf 'agent-docker-tools example\n' > samples/adt-example.txt
docker compose up --build --wait --wait-timeout 180
docker compose exec -T agent sh -c 'file /root/challenges/adt-example.txt > /root/ctf-solutions/adt-example.txt'
cat ctf-solutions/adt-example.txt
~~~

| 宿主机目录 | 容器目录 | 权限 |
| --- | --- | --- |
| `samples/` | `/root/challenges` | 只读 |
| `scripts/` | `/root/scripts` | 只读 |
| `ctf-solutions/` | `/root/ctf-solutions` | 可写 |

使用 `docker compose ps` 查看健康状态，通过 `docker compose logs agent` 查看日志。使用 `docker compose down` 停止服务。

在宿主机可用 `python3 scripts/rexec.py sh 'file /root/challenges/adt-example.txt'` 调用容器中的命令。

## IDE 和调试

将 [MCP 配置](agent-work/.mcp.json)载入 IDE。GhidraMCP 的 SSE 地址为 `http://127.0.0.1:8766/sse`，只在 Docker 宿主机回环地址发布。若 IDE 与 Docker 不在同一台机器，可在 IDE 所在机器建立 SSH 转发。

~~~sh
ssh -N -L 127.0.0.1:8766:127.0.0.1:8766 user@docker-host
~~~

本地进程需要调试时，使用覆盖文件增加 `SYS_PTRACE`。

~~~sh
docker compose -f compose.yml -f docker-compose.debug.yml up --wait --wait-timeout 180
~~~

## 下载源和代理

可在解压目录的 `.env` 中指定 `ADT_BUILD_HTTP_PROXY`、`ADT_BUILD_HTTPS_PROXY` 和 `ADT_PIP_INDEX_URL`。容器运行时使用 `ADT_HTTP_PROXY` 和 `ADT_HTTPS_PROXY`。置空代理变量可以显式禁用相应代理。

## 许可证和依赖来源

本项目源码按 [MIT](LICENSE) 授权。这个 ZIP 提供构建源码。构建过程中另行安装以下依赖。

| 组件 | 来源和许可信息 |
| --- | --- |
| Debian 13、OpenJDK 和系统工具 | 基础镜像的摘要与安装包名见 [Dockerfile](Dockerfile)。系统包随镜像保留 `/usr/share/doc` 下的版权文件。 [Debian 官方镜像源码](https://github.com/debuerreotype/docker-debian-artifacts) |
| Ghidra 12.1.4 | 发行包里的 `LICENSE` 和 `licenses/` 随安装目录保留。 [官方发行页](https://github.com/NationalSecurityAgency/ghidra/releases/tag/Ghidra_12.1.4_build) |
| GhidraMCP 7.0.0 | Apache 2.0。源包附有对应版本的 [LICENSE](docker/licenses/ghidra-mcp.LICENSE) 和 [NOTICE](docker/licenses/ghidra-mcp.NOTICE)，构建时放入镜像。 [官方发行页](https://github.com/bethington/ghidra-mcp/releases/tag/v7.0.0) |
| MCP Python SDK 和传递依赖 | SDK 版本固定为 `1.28.1`。包安装元数据和随包提供的许可文件保留在虚拟环境中。 [SDK 源码](https://github.com/modelcontextprotocol/python-sdk) |
