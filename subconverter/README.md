# subconverter

基于 subweb 和 subconverter 前后端加上 myurls 短链接整合容器,支持自定义配置.

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/subconverter
```

进入目录
```bash
cd /mnt/docker-data/subconverter
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/subconverter/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/subconverter/.env.example
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

subconverter

```bash
location / {
    proxy_pass http://127.0.0.1:18980;
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

myurls

```bash
location / {
    proxy_pass http://127.0.0.1:8002;
    proxy_redirect off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-NginX-Proxy ture;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    add_header 'Access-Control-Allow-Origin' '*';

    client_max_body_size        100m;
    client_body_buffer_size     128k;
}
```

## 修正 myurls 订阅转换链接

在 `.env` 文件中设置变量 `HTTP_URL`

```ini
HTTP_URL=https://sub.ops.ci
```

修改模版中的地址

```bash
docker exec -it myurls sed -i "s#https://sub.ops.ci#$(cat .env | grep 'HTTP_URL' | sed 's/\(.*\)=\(.*\)/\2/g')#g" /app/public/index.html
```

重启 myurls 容器

```bash
docker-compose restart myurls
```