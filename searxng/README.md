# SearXNG

SearXNG 是一个免费的互联网元搜索引擎，它汇总了来自 70 多个搜索服务的结果。用户既不被跟踪也不被分析。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/searxng
```

进入目录
```bash
cd /mnt/docker-data/searxng
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/searxng/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/searxng/.env.example
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
    proxy_pass http://127.0.0.1:8180;
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