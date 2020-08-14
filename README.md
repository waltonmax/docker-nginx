### 使用

```bash
#拉取镜像
docker pull waltonmax/nginx:latest      
#编译镜像
docker build -t waltonmax/nginx:1.16.0 . 
```

### 运行
1. 常规运行方法：


```bash
docker run -d -p 80:80 -p 443:443 waltonmax/nginx:latest
```

```bash
#使用模板配置文件
mkdir -p /usr/local/nginx && curl -Lk https://github.com/waltonmax/docker-nginx/raw/master/conf.tar| tar xz -C /usr/local/nginx
#运行容器
docker run -d -v /usr/local/nginx/conf:/usr/local/nginx/conf -p 80:80 -p 443:443 waltonmax/nginx:latest
```

2. 挂载数据目录方法：

```bash
docker run -d -p 80:80 -p 443:443 \
-v /etc/localtime:/etc/localtime:ro \ #将宿主机的时区文件挂载到容器内
-v /data/wwwroot:/data/wwwroot:rw \   #将宿主机的web文件挂载到容器内
-v /data/logs/wwwlogs:/data/wwwlogs:rw \  #将容器内的日志文件挂载到宿主机上
-v /data/conf/nginx/vhost:/usr/local/nginx/conf/vhost:rw \ #将配置文件挂载进容器
waltonmax/nginx:latest
```
3. 和php mysql redis 关联使用的方法
```bash
docker run -d --privileged --restart always \
--name redis-server -p 127.0.0.1:6379:6379 \
-v /etc/localtime:/etc/localtime:ro \
-v /etc/redis.conf:/etc/redis.conf:ro \
-v /data/redis:/data/redis:Z \
waltonmax/redis
```
```bash
docker run -d --name mysql_server --restart always \
-p 3306:3306 -e MYSQL_ROOT_PASSWORD=root \
-v /etc/localtime:/etc/localtime:ro
-v /data/mariadb:/data/mariadb:rw
waltonmax/mariadb
```
```bash
docker run -d --restart always --name php-server \
-e REDIS=Yes -e MEMCACHE=Yes -e SWOOLE=Yes \
--link redis-server:resid-server \
--link mysql-server:mysql-server \
-v /etc/localtime:/etc/localtime:ro
-v /data/wwwroot:/data/wwwroot:rw
waltonmax/php
```
```bash
docker run -d --restart always --name nginx-server \
-p 80:80 -p 443:443 \
-e PHP_FPM=Enable -e PHP_FPM_SERVER=php-server \
-e PHP_FPM_PORT=9000 -e REWRITE=wordpress \
--link php_server:php-server \
--link mysql-server:mysql-server \
-v /etc/localtime:/etc/localtime:ro \
-v /data/wwwroot:/data/wwwroot:rw \
-v /data/logs/wwwlogs:/data/wwwlogs:rw \
-v /data/conf/nginx/vhost:/usr/local/nginx/conf/vhost:rw \
waltonmax/nginx
```
4. docker-compose 
```bash
#编译镜像
docker-compose build
#后台启动容器
docker-compose up -d

```