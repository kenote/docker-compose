# Cloudreve

Cloudreve 可助你即刻构建出兼备自用或公用的网盘服务，通过多种存储策略的支持、虚拟文件系统等特性实现灵活的文件管理体验。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/cloudreve
```

进入目录
```bash
cd /mnt/docker-data/cloudreve
```

创建数据目录
```bash
mkdir {cloudreve,data}
```

进入数据目录
```bash
cd cloudreve
```

创建上传文件目录
```bash
mkdir {avatar,uploads}
```

创建配置/数据文件
```bash
touch {conf.ini,cloudreve.db}
```

返回主目录
```bash
cd /mnt/docker-data/cloudreve
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/cloudreve/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/cloudreve/.env.example
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

获取初始密码
```bash
docker-compose logs
```

##  反向代理

```bash
location / {
    proxy_pass http://127.0.0.1:5212;
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