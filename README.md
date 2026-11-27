# agent-docker-tools

用于本地样本检查的 Docker Compose 环境。可以在终端识别文件、保存分析报告，也可以在 IDE 中连接 GhidraMCP。发布验证面向 Linux amd64。

## 从一个文本样本开始

在仓库根目录执行以下命令。核心镜像包含 Ghidra、GhidraMCP 和 `file`、`gdb` 等本地分析工具。Compose 会构建镜像、启动服务并等待健康检查通过。

~~~sh
mkdir -p samples
printf 'hello from agent-docker-tools\n' > samples/hello.txt
docker compose up --build --wait --wait-timeout 180
docker compose exec -T agent sh -c 'file /root/challenges/hello.txt > /root/ctf-solutions/hello-report.txt'
cat ctf-solutions/hello-report.txt
~~~

已有当前镜像时，可以省略 `--build`。要查看运行状态或诊断启动失败，执行 `docker compose ps` 和 `docker compose logs --tail=100 agent`。容器显示 `healthy` 时，Ghidra 的 REST 请求和 MCP 的 SSE 初始化都已通过。用 `docker compose down` 停止服务。

| 宿主机目录 | 容器路径 | 权限 |
| --- | --- | --- |
| `samples/` | `/root/challenges` | 只读 |
| `scripts/` | `/root/scripts` | 只读 |
| `ctf-solutions/` | `/root/ctf-solutions` | 可写 |

从宿主机编辑脚本，在容器内把报告写入输出目录。样本和报告都排除在镜像构建上下文之外。

## 连接 IDE

把 [工作区 MCP 配置](agent-work/.mcp.json)加载到支持 MCP 的 IDE。GhidraMCP 连接指向 Docker 宿主机的 `http://127.0.0.1:8766/sse`。容器内的 Ghidra REST 使用 `127.0.0.1:8089`。Chrome DevTools 连接由 IDE 在宿主机通过 `npx` 启动，使用独立的无头浏览器会话。

如果 Docker 在另一台机器或虚拟机上运行，在 IDE 所在机器打开 SSH 本地转发，并在使用 MCP 时保持该会话。

~~~sh
ssh -N -L 127.0.0.1:8766:127.0.0.1:8766 user@docker-host
~~~

从 Trae 使用时，可以同时打开 [工作区说明](agent-work/CLAUDE.md)和独立维护的 [ctf-wiki](https://github.com/doudou0308/ctf-wiki)。

## 按需调试和调用脚本

需要将调试器附加到容器进程时，加载调试覆盖文件。它只增加 `SYS_PTRACE`。默认配置使用 Docker 的 seccomp 策略、移除 `NET_RAW` 并启用 `no-new-privileges`。

~~~sh
docker compose -f docker-compose.yml -f docker-compose.debug.yml up --wait --wait-timeout 180
~~~

宿主机上导入 `scripts.rexec` 后，`sh(command)` 返回合并后的文本。需要分别读取输出和退出码时，使用 `run(command)` 返回值里的 `stdout`、`stderr` 和 `returncode`。`run()` 超时会抛出 `subprocess.TimeoutExpired`。

通过命令行调用 `cp_to` 或 `cp_from` 时，复制失败会向标准错误输出原因并返回非零退出码。Python 接口继续返回文本。

## 配置下载源与代理

需要时在仓库根目录的 `.env` 中配置以下变量。使用能从相应构建环境或运行容器访问的地址。

| 变量 | 用途 |
| --- | --- |
| `ADT_BUILD_HTTP_PROXY`、`ADT_BUILD_HTTPS_PROXY` | 镜像构建时使用的代理 |
| `ADT_HTTP_PROXY`、`ADT_HTTPS_PROXY` | 容器运行时使用的代理 |
| `ADT_PIP_INDEX_URL` | 构建时使用的 Python 软件源，默认为官方 PyPI |

代理变量可设为空。Python 软件源为空时使用官方 PyPI。

## 许可证和依赖

项目源码按 [MIT](LICENSE) 授权。

镜像使用按内容摘要固定的 [Debian 13 官方基础镜像](https://github.com/debuerreotype/docker-debian-artifacts)、[Ghidra 12.1.4](https://github.com/NationalSecurityAgency/ghidra/releases/tag/Ghidra_12.1.4_build)和 [GhidraMCP 7.0.0](https://github.com/bethington/ghidra-mcp/releases/tag/v7.0.0)。发行包中的许可证和声明随镜像保留，系统包和 Python 包的许可信息随各自安装目录提供。镜像通过 `Dockerfile` 构建，构建上下文的允许文件见 `.dockerignore`。

## 打包核心版源码

运行 `python3 scripts/package_core.py dist/agent-docker-tools-core.zip` 生成核心版源码 ZIP 和校验值。解压后可直接在包内使用 `docker compose`。构建说明和依赖许可清单见 [核心版说明](docs/core-release.md)。
