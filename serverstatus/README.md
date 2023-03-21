# ServerStatus

ServerStatus 是一个酷炫高逼格的云探针、云监控、服务器云监控、多服务器探针~。

## 安装部署

Github

```bash
wget --no-check-certificate -qO sss.sh https://raw.githubusercontent.com/kenote/docker-compose/main/serverstatus/help.sh \
&& chmod +x sss.sh \
&& ./sss.sh
```

Gitee

```bash
wget --no-check-certificate -qO sss.sh https://gitee.com/kenote/docker-compose/raw/main/serverstatus/help.sh \
&& chmod +x sss.sh \
&& ./sss.sh
```

##  反向代理

```bash
location / {
    proxy_pass http://127.0.0.1:8081;
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