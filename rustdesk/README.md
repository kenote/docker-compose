# RustDesk

开源虚拟与远程桌面基础架构

## 安装部署

创建目录
```bash
mkdir -p /mnt/docker-data/rustdesk
```

进入目录
```bash
cd /mnt/docker-data/rustdesk
```

拉取 `docker-compose.yml`
```bash
wget --no-check-certificate -qO docker-compose.yml https://raw.githubusercontent.com/kenote/docker-compose/main/rustdesk/compose.yml
```

拉取 `.env`
```bash
wget --no-check-certificate -qO .env https://raw.githubusercontent.com/kenote/docker-compose/main/rustdesk/.env.example
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

## 开放端口

```
TCP - 21115-21119
UDP - 21116
```

## 获取连接的 key

```bash
cat /mnt/docker-data/rustdesk/data/id_ed25519.pub && echo
```