# Mattermost

Mattermost是一套开放源代码、可自行架设的在线聊天服务，有分享文件、搜索与集成其他服务等功能。它被设计成用于组织与公司的内部沟通，且主要将其作为Slack与Microsoft Teams的开放源代码替代品。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/mattermost
```

进入目录
```bash
cd /mnt/docker-data/mattermost
```

创建数据库目录
```bash
mkdir -p ./postgresql/data
```

创建数据目录
```bash
mkdir -p ./mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
```

附加配置目录权限
```bash
chmod -R 777 ./mattermost/config
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/mattermost/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/mattermost/.env.example
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
    proxy_pass http://127.0.0.1:8065;
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
