#!/bin/sh

docker stop trojan_instance v2ray_instance cert_instance web_instance
docker rm trojan_instance v2ray_instance cert_instance web_instance
docker rmi trojan v2ray cert web

