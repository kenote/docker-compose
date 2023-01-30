# YOURLS

YOURLS是一款使用PHP + Mysql开发的短链接程序，相比公共短网址好处是数据掌握在自己手中，可控性更高。

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/yourls
```

进入目录
```bash
cd /mnt/docker-data/yourls
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/yourls/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/yourls/.env.example
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
}
```

## 初始化数据

进入 http://example.com/admin , 点击 `Install YOURLS` 进行初始化操作。

## 添加中文语言包

下载中文语言包
```bash
wget https://github.com/ZvonimirSun/YOURLS-zh_CN/archive/refs/tags/v1.7.3.zip
```

解压语言包
```
unzip v1.7.3.zip
```

移动文件到 `/mnt/docker-data/yourls/html/user/languages` 目录下
```
mv YOURLS-zh_CN-1.7.3/* /mnt/docker-data/yourls/html/user/languages
```

编辑 `/mnt/docker-data/yourls/html/user/config.php`
```php
define( 'YOURLS_LANG', getenv('YOURLS_LANG') ?: 'zh_CN' );
```

## 同一条链接对应多个短链接

编辑 `/mnt/docker-data/yourls/html/user/config.php`
```php
define( 'YOURLS_UNIQUE_URLS', getenv('YOURLS_UNIQUE_URLS') === true ?: filter_var(getenv('YOURLS_UNIQUE_URLS'), FILTER_VALIDATE_BOOLEAN) );
```

重启容器
```bash
cd /mnt/docker-data/yourls
docker-compose restart
```