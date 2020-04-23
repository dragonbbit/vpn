#!/bin/sh

docker stop v2ray_instance web_instance speedtest_instance dnsmasq_instance
docker rm v2ray_instance web_instance speedtest_instance dnsmasq_instance
docker rmi v2ray adolfintel/speedtest dnsmasq

