#!/bin/sh

docker stop trojan_instance v2ray_instance certweb_instance speedtest_instance
docker rm trojan_instance v2ray_instance certweb_instance speedtest_instance
docker rmi trojan v2ray certweb adolfintel/speedtest

