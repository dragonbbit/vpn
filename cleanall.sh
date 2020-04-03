#!/bin/sh

docker stop trojan_instance v2ray_instance cert_instance web_instance speedtest_instance
docker rm trojan_instance v2ray_instance cert_instance web_instance certweb_instance speedtest_instance
docker rmi trojan v2ray cert web certweb  adolfintel/speedtest

