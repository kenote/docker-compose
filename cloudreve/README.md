# Cloudreve

Cloudreve 可助你即刻构建出兼备自用或公用的网盘服务，通过多种存储策略的支持、虚拟文件系统等特性实现灵活的文件管理体验。

## 安装部署

Github

```bash
mkdir -p $HOME/.compose/cloudreve \
&& wget --no-check-certificate -qO $HOME/.compose/cloudreve/help.sh https://raw.githubusercontent.com/kenote/docker-compose/main/cloudreve/help.sh \
&& chmod +x $HOME/.compose/cloudreve/help.sh \
&& $HOME/.compose/cloudreve/help.sh
```

Gitee

```bash
mkdir -p $HOME/.compose/cloudreve \
&& wget --no-check-certificate -qO $HOME/.compose/cloudreve/help.sh https://gitee.com/kenote/docker-compose/raw/main/cloudreve/help.sh \
&& chmod +x $HOME/.compose/cloudreve/help.sh \
&& $HOME/.compose/cloudreve/help.sh
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