# ZFile

最方便快捷的在线目录展示程序，支持将本地文件、FTP、SFTP、S3、OneDrive 等存储在网站上展示并浏览.

## 安装部署

Github

```bash
mkdir -p $HOME/.compose/zfile \
&& wget --no-check-certificate -qO $HOME/.compose/z file/help.sh https://raw.githubusercontent.com/kenote/docker-compose/main/zfile/help.sh \
&& chmod +x $HOME/.compose/zfile/help.sh \
&& $HOME/.compose/zfile/help.sh
```

Gitee

```bash
mkdir -p $HOME/.compose/zfile \
&& wget --no-check-certificate -qO $HOME/.compose/zfile/help.sh https://gitee.com/kenote/docker-compose/raw/main/zfile/help.sh \
&& chmod +x $HOME/.compose/zfile/help.sh \
&& $HOME/.compose/zfile/help.sh
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