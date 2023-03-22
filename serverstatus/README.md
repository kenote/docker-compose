# ServerStatus

ServerStatus 是一个酷炫高逼格的云探针、云监控、服务器云监控、多服务器探针~。

## 服务端部署

Github

```bash
mkdir -p $HOME/.compose/serverstatus \
&& wget --no-check-certificate -qO $HOME/.compose/serverstatus/help.sh https://raw.githubusercontent.com/kenote/docker-compose/main/serverstatus/help.sh \
&& chmod +x $HOME/.compose/serverstatus/help.sh \
&& $HOME/.compose/serverstatus/help.sh
```

Gitee

```bash
mkdir -p $HOME/.compose/serverstatus \
&& wget --no-check-certificate -qO $HOME/.compose/serverstatus/help.sh https://gitee.com/kenote/docker-compose/raw/main/serverstatus/help.sh \
&& chmod +x $HOME/.compose/serverstatus/help.sh \
&& $HOME/.compose/serverstatus/help.sh
```

## 客户机卸载

Github

```bash
wget --no-check-certificate -qO sss-agent.sh https://raw.githubusercontent.com/kenote/docker-compose/main/serverstatus/agent.sh \
&& chmod +x sss-agent.sh \
&& sudo ./sss-agent.sh remove
```

Gitee

```bash
wget --no-check-certificate -qO sss-agent.sh https://gitee.com/kenote/docker-compose/raw/main/serverstatus/agent.sh \
&& chmod +x sss-agent.sh \
&& sudo ./sss-agent.sh remove
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