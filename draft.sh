#!/bin/sh

### Get dommain name
read -p "请输入域名：" DOMAIN_NAME
read -p "请输入口令：" PASSWORD

echo $DOMAIN_NAME
uuid=$(cat /proc/sys/kernel/random/uuid)

### Install Docker (on CentOS)
# 检查系统
check_sys(){
        if [[ -f /etc/redhat-release ]]; then
                release="centos"
        elif cat /etc/issue | grep -q -E -i "debian"; then
                release="debian"
        elif cat /etc/issue | grep -q -E -i "ubuntu"; then
                release="ubuntu"
        elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
                release="centos"
        elif cat /proc/version | grep -q -E -i "debian"; then
                release="debian"
        elif cat /proc/version | grep -q -E -i "ubuntu"; then
                release="ubuntu"
        elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
                release="centos"
    fi
}

install_docker() {
    if [[ -f /usr/bin/docker]]; then
        echo "Found Docker"
    fi

    }

}

sudo yum update -y
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce

sudo usermod -aG docker ${USER}
sudo systemctl enable docker
sudo systemctl start docker
exec newgrp docker

####Build Cert Web
mkdir -p ~/.cert
v2ray_client_id=$(cat /proc/sys/kernel/random/uuid)
docker build -t certweb --rm --build-arg DOMAIN_NAME=jigg.xyz --build-arg V2RAY_CLIENT_ID=${v2ray_client_id} -f Dockerfile.certweb .
docker run -d --name certweb_instance --restart=always -v ~/.cert:/etc/nginx/cert -p 80:80 -p 443:443 certweb

#test
#docker run -it --rm  -v ~/.cert:/etc/nginx/cert -p 80:80 -p 443:443 --entrypoint=/bin/sh certweb

####Build Trojan 
certweb_addr=$(docker exec certweb_instance sh -c "/sbin/ip a" | grep -o "inet.*eth" | grep -o "[[:digit:]]\+.*\/")
certweb_addr=${certweb_addr:0:-1}
docker build -t trojan --build-arg PASSWORD="VPN302=01" --build-arg DOMAIN_NAME=jigg.xyz --build-arg PORT=4443 --build-arg REMOTE_ADDR=${certweb_addr} --rm -f Dockerfile.trojan .
docker run -d -v ~/.cert:/etc/trojan/cert -p 4443:4443 --restart=always --name trojan_instance trojan

# test
#docker run -it --rm -v ~/.cert:/etc/trojan/cert -p 4443:4443 --name trojan_instance --entrypoint=/bin/sh trojan

####Build v2ray
v2ray_client_id=$(docker exec v2ray_instance sh -c "cat /etc/v2ray/config.json" | egrep '"id"' | egrep -o '[0-9a-fA-F]{8}.*[0-9a-fA-F]{12}')
docker build -t v2ray --rm --build-arg V2RAY_CLIENT_ID=${v2ray_client_id} -f Dockerfile.v2ray .
docker run -d --name v2ray_instance --restart=always v2ray

# test
#docker run -it --rm --name v2ray_instance --entrypoint=/bin/sh v2ray

# Update web proxy address
v2ray_addr=$(docker exec v2ray_instance sh -c "/sbin/ip a" | grep -o "inet.*eth" | grep -o "[[:digit:]]\+.*\/")
v2ray_addr=${v2ray_addr:0:-1}
docker exec -t certweb_instance sh -c "sed -i \"s~//.*:10000;~//${v2ray_addr}:10000;~\" /etc/nginx/conf.d/*.ssl.conf&&nginx -s reload"

## Centos 
docker build -t centos_v2ray --rm --build-arg V2RAY_CLIENT_ID=${v2ray_client_id} -f Dockerfile.centos.v2ray .
docker run -d --name centos_v2ray_instance --restart=always centos_v2ray

centos_v2ray_addr=$(docker exec centos_v2ray_instance sh -c "/sbin/ip a" | grep -o "inet.*eth" | grep -o "[[:digit:]]\+.*\/")
centos_v2ray_addr=${centos_v2ray_addr:0:-1}

docker exec -t certweb_instance sh -c "sed -i \"s~//.*:10000;~//${centos_v2ray_addr}:10000;~\" /etc/nginx/conf.d/*.ssl.conf&&nginx -s reload"


#e88de3a0-cad0-4837-b741-240afd2e0269

docker exec v2ray_instance sh -c "cat /etc/v2ray/config.json" | grep -o '"id":.*'

### For trojan on alpine 
wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-bin-2.30-r0.apk
apk add glibc-2.30-r0.apk
apk add glibc-bin-2.30-r0.apk
apk add  libstdc++

### Remove all
docker stop trojan_instance v2ray_instance certweb_instance
docker rm trojan_instance v2ray_instance certweb_instance
docker rmi trojan v2ray certweb


### SpeedTest Server
docker pull adolfintel/speedtest
docker run -d --name speedtest_instance -e MODE=standalone -e TELEMETRY=true -e ENABLE_ID_OBFUSCATION=true -e PASSWORD="VPN302=01" -p 8080:80  adolfintel/speedtest

ENTRYPOINT ["tail", "-f", "/dev/null"]
CMD tail -f /dev/null