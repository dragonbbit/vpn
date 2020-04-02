#!/bin/sh

docker stop trojan_instance v2ray_instance certweb_instance
docker rm trojan_instance v2ray_instance certweb_instance
docker rmi trojan v2ray certweb

