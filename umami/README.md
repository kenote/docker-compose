# Umami

Umami 是一款简单易用、自托管的开源网站访问流量统计分析工具，Umami 不使用 Cookie，不跟踪用户，且所有收集的数据都会匿名化处理，符合 GDPR 政策，资源占用很低，虽然功能简单，但分析的数据内容很丰富。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/umami
```

进入目录
```bash
cd /mnt/docker-data/umami
```

拉取数据表
```bash
mkdir -p sql && wget --no-check-certificate -qO sql/schema.postgresql.sql https://raw.githubusercontent.com/umami-software/umami/master/sql/schema.mysql.sql
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/umami/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/umami/.env.example
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
    proxy_pass http://127.0.0.1:3000;
    proxy_redirect off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-NginX-Proxy ture;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```