# Speedtest-X

基于 [LibreSpeed](https://github.com/librespeed/speedtest) 项目，使用文件数据库来保存来自不同用户的测速结果，方便您查看全国不同地域与运营商的测速效果。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/speedtest-x
```

进入目录
```bash
cd /mnt/docker-data/speedtest-x
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/speedtest-x/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/speedtest-x/.env.example
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
    proxy_pass http://127.0.0.1:8087;
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