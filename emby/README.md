# Emby

Emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/emby
```

进入目录
```bash
cd /mnt/docker-data/emby
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/emby/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/emby/.env.example
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
    proxy_pass http://127.0.0.1:8096;
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