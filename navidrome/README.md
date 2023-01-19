# Navidrome

**Navidrome** 是一款开源音乐服务器，它可以把你硬盘里的音乐文件以流媒体的方式展示出来，就可以在任何浏览器里收听了，也支持不少第三方客户端，最终在全平台播放收听。类似自家的 Spotify、Apple Music、网易云音乐、QQ音乐的意思。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/navidrome
```

进入目录
```bash
cd /mnt/docker-data/navidrome
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/navidrome/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/navidrome/.env.example
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
    proxy_pass http://127.0.0.1:4533;
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