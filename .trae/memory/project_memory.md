# CHYing Agent — Project Memory

## 知识库路径

- **Obsidian Wiki（已搭建，217 页）**: `C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\`
- **已安装 Skills（118 个）**: `C:\Users\ZZH\.trae\skills\`
- **CTF 知识库（云端）**: `C:\Users\ZZH\.trae\ctf-kb\`

## 项目约定

- Docker 工具容器名: `chying-agent`
- 项目管理: `docker compose up -d` 启动
- 解题脚本统一放在 `scripts/` 下
- 解题结果输出到 `ctf-solutions/<题目名>/`

## 常用工作流

```bash
# 启动容器
docker compose up -d

# 执行命令（结果写入文件避免截断）
docker exec chying-agent bash -c "python3 /root/scripts/solve.py > /tmp/out.txt 2>&1"
docker exec chying-agent cat /tmp/out.txt

# 复制文件到容器
docker cp challenge.elf chying-agent:/root/

# 复制结果回宿主机
docker exec chying-agent bash -c "cat /root/flag.txt > /tmp/out.txt 2>&1"
docker exec chying-agent cat /tmp/out.txt
```

## 解题模板

1. 加载对应类别 ctf-* skill
2. 零轮侦察（strings|grep flag + file + binwalk 并行）
3. 按 docs/cheatsheets/ 对应分类的速查表逐步攻击
4. 2 轮卡壳 → 查 Obsidian Wiki 知识库

## 知识库触发规则

仅在以下情况检索知识库：
- 同一方向 2 轮无进展
- 完全陌生的题型/文件格式
- 需要在 `docs/cheatsheets/` 之外的深入技术细节

检索命令：
```
grep -ri "<关键词>" "C:\Users\ZZH\Documents\Obsidian Vault\Wiki\Wiki\"
grep -ri "<关键词>" "C:\Users\ZZH\.trae\skills\<skill名>\"
```
