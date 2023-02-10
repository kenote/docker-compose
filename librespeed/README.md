# LibreSpeed

Librespeed 是一个非常轻量级的测速工具，基于 Javascript ，使用 XMLHttpRequest 和 Web Workers 。没有Flash，没有Java，没有Websocket。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/librespeed
```

进入目录
```bash
cd /mnt/docker-data/librespeed
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/librespeed/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/librespeed/.env.example
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
    proxy_pass http://127.0.0.1:8086;
    proxy_redirect off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-NginX-Proxy ture;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    # 设定上传文件最大大小，用于测试上传
    client_max_body_size 100m;
}
```