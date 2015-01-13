docker-haproxy-confd
====================

[![Docker Hub](https://img.shields.io/badge/docker-mkaag%2Fhaproxy-confd-008bb8.svg)](https://registry.hub.docker.com/u/mkaag/haproxy-confd/)

This repository contains the **Dockerfile** and the configuration files to build a Load Balancer based on Haproxy for [Docker](https://www.docker.com/).
The configuration is performed with [confd](https://github.com/kelseyhightower/confd).

### Base Docker Image

* [phusion/baseimage](https://github.com/phusion/baseimage-docker), the *minimal Ubuntu base image modified for Docker-friendliness*...
* ...[including image's enhancement](https://github.com/racker/docker-ubuntu-with-updates) from [Paul Querna](https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/)

### Installation

```bash
docker build -t mkaag/haproxy-confd github.com/mkaag/docker-haproxy-confd
```

### Usage

#### Basic usage

```bash
docker run -d -p 443:443 -p 80:80 -p 1936:1936 \
-v /opt/apps/ssl:/etc/ssl \
mkaag/haproxy-confd /sbin/my_init -- bash /usr/local/bin/confd-watch
```

### etcd structure

```bash
etcdctl set /services/haproxy/frontend/https/cert /etc/ssl/private/server.pem
etcdctl set /services/haproxy/stats/white_list 192.168.0.0/24
etcdctl set /services/haproxy/backend/app1/hostname app1.domain.com
etcdctl set /services/haproxy/backend/app1/endpoints/1 192.168.0.11:8001
etcdctl set /services/haproxy/backend/app1/endpoints/2 192.168.0.11:8002
etcdctl set /services/haproxy/backend/app2/hostname app2.domain.com
etcdctl set /services/haproxy/backend/app2/endpoints/1 192.168.0.12:8001
etcdctl set /services/haproxy/backend/app2/endpoints/2 192.168.0.13:8002
```
