# Portainer

`Portainer` 是 `Docker` 的图形化管理工具，提供状态显示面板、应用模板快速部署、容器镜像网络数据卷的基本操作（包括上传下载镜像，创建容器等操作）、事件日志显示、容器控制台操作、`Swarm` 集群和服务等集中管理和操作、登录用户管理和控制等功能。功能十分全面，基本能满足中小型单位对容器管理的全部需求。

## 安装宿主机

Github

```bash
mkdir -p $HOME/.compose/portainer \
&& wget --no-check-certificate -qO $HOME/.compose/portainer/help.sh https://raw.githubusercontent.com/kenote/docker-compose/main/portainer/help.sh \
&& chmod +x $HOME/.compose/portainer/help.sh \
&& $HOME/.compose/portainer/help.sh
```

Gitee

```bash
mkdir -p $HOME/.compose/portainer \
&& wget --no-check-certificate -qO $HOME/.compose/portainer/help.sh https://gitee.com/kenote/docker-compose/raw/main/portainer/help.sh \
&& chmod +x $HOME/.compose/portainer/help.sh \
&& $HOME/.compose/portainer/help.sh
```

## 安装客户机

Github

```bash
mkdir -p $HOME/.compose/portainer \
&& wget --no-check-certificate -qO $HOME/.compose/portainer/agent.sh https://raw.githubusercontent.com/kenote/docker-compose/main/portainer/agent.sh \
&& chmod +x $HOME/.compose/portainer/agent.sh \
&& $HOME/.compose/portainer/agent.sh
```

Gitee

```bash
mkdir -p $HOME/.compose/portainer \
&& wget --no-check-certificate -qO $HOME/.compose/portainer/agent.sh https://gitee.com/kenote/docker-compose/raw/main/portainer/agent.sh \
&& chmod +x $HOME/.compose/portainer/agent.sh \
&& $HOME/.compose/portainer/agent.sh
```

##  反向代理

```bash
location / {
    proxy_pass https://127.0.0.1:9443;
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