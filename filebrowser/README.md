# Filebrowser

Filebrowser 是一个使用go语言编写的软件，功能是可以通过浏览器对服务器上的文件进行管理。可以是修改文件，或者是添加删除文件，甚至可以分享文件，是一个很棒的文件管理器，你甚至可以当成一个网盘来使用。总之使用非常简单方便，功能很强大。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/filebrowser
```

进入目录
```bash
cd /mnt/docker-data/filebrowser
```

创建数据目录
```bash
mkdir -p data
```

拉取 `settings.json`
```bash
wget --no-check-certificate -qO ./data/settings.json https://raw.githubusercontent.com/kenote/docker-compose/main/filebrowser/settings.json
```

创建数据库文件
```bash
touch ./data/filebrowser.db
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/filebrowser/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/filebrowser/.env.example
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

    # 设定上传文件最大大小
    client_max_body_size 1000m;
}
```

## 默认账号/密码

```yaml
username: admin
password: admin
```