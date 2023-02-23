# qBittorrent

QBittorrent是一个新的轻量级BitTorrent客户端，可运行于Linux、windows及其他可能系统，它简单易用，漂亮的外观，功能强大。现在它可以被视为一个良好的替代其他BitTorrent软件的客户端。软件自带简体中文。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/qbittorrent
```

进入目录
```bash
cd /mnt/docker-data/qbittorrent
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/qbittorrent/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/qbittorrent/.env.example
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

默认账号 `admin`, 默认密码 `adminadmin`

##  反向代理

```bash
location / {
    proxy_pass http://127.0.0.1:8081;
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