# Poste.io

Poste.io 邮件服务器是一个小而精的邮件服务器，其功能丰富，收发信可靠，非常适合个人、团体以及企业使用。此外poste邮件服务器安装简单，因为官方提供了docker版的一键安装。

## 安装部署

先卸载系统默认 `postfix` 服务，避免 `25` 端口冲突
```bash
yum remove postfix
```

创建目录
```bash
mkdir -p /mnt/docker-data/poste.io
```

进入目录
```bash
cd /mnt/docker-data/poste.io
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/poste.io/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/poste.io/.env.example
```

编辑 `.env`
```bash
vim .env
```

启动
```bash
docker-compose up -d
```

卸载
```bash
docker-compose down
```

##  反向代理

```bash
location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_redirect off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-NginX-Proxy ture;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 43200000;
    proxy_buffering off;
}
```

## 域名解析

| 类型 | 主机记录 | 记录值 |
| --- |---|---|
| A | mail | `127.0.0.1` |
| MX | @ | `mail.example.com` |
| TXT | @ | `v=spf1 mx ~all` |
| TXT | _dmarc | `v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com` |
| CNAME | smtp | `mail.example.com` |
| CNAME | imap | `mail.example.com` |
| CNAME | pop | `mail.example.com` |

此外还需要添加 `DKIM` 记录；登录后台 -> `Virtual domains` -> `点击对应域名` -> `DKIM key` -> `create new key` 获取