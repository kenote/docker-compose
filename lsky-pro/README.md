# Lsky Pro

兰空图床可以帮您保管大量无处安放的图片，数据可以自由选择储存驱动，支持主流第三方储存。

作为一个助手，它不仅可以将您把图片以指定规则存放在指定位置，还有更多强大的功能来帮助您处理这些图片。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/lsky-pro
```

进入目录
```bash
cd /mnt/docker-data/lsky-pro
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/lsky-pro/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/lsky-pro/.env.example
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
    proxy_pass http://127.0.0.1:7791;
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

如果使用了Nginx反代后，如果出现无法加载图片的问题，可以根据原项目 [#317](https://github.com/lsky-org/lsky-pro/issues/317) 执行以下指令来手动修改容器内`AppServiceProvider.php`文件对于HTTPS的支持

```bash
docker exec -it lsky-pro sed -i '32 a \\\Illuminate\\Support\\Facades\\URL::forceScheme('"'"'https'"'"');' /var/www/html/app/Providers/AppServiceProvider.php
```