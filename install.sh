#!/bin/sh

Green_font_prefix="\033[32m" 
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m" 
Font_color_suffix="\033[0m"

Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_sys(){
    if test -f "/etc/redhat-release"; then
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

install_docker_on_centos() {
    sudo yum update -y
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo systemctl enable docker
    sudo systemctl start docker
}

install_docker_on_ubuntu() {    
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -y
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    sudo systemctl start docker
}

install_docker() {
    if test -f "/usr/bin/docker"; then
        echo -e ${Info} "发现Docker，无需安装！"
        return
    fi    
    check_sys
    if test "${release}" = "centos"; then
        install_docker_on_centos
    elif test "${release}" = "ubuntu"; then
	install_docker_on_ubuntu
	return
    else
        echo -e ${Error} "无法在此系统自动安装Docker。请手工安装"
        exit 1
    fi
    
    sudo usermod -aG docker ${USER}
    exec newgrp docker
}

get_info(){
    while :
    do
        read -p $1 _info
        if test "$(echo -n $_info | wc -m)" != "0"; then 
            break
        fi
        echo -e ${Error} "输入错误"
    done
}

####################################
### Install Docker               ###
####################################

get_info "请输入域名："
domain_name=${_info}
get_info "请输入口令："
password=${_info}
v2ray_client_id=$(cat /proc/sys/kernel/random/uuid)
trojan_port=4443

install_docker

####################################
### Setup Docker                 ###
####################################

# ### Build Cert
# mkdir -p ~/.cert
# docker build -t cert --rm --build-arg DOMAIN_NAME=${domain_name} --build-arg CERT_PORT=${cert_port} -f Dockerfile.cert .
# docker run -d --name cert_instance --restart=always -v ~/.cert:/etc/acme/cert -p 80:80 cert

# ### Build Web
# docker build -t web --rm --build-arg DOMAIN_NAME=${domain_name} --build-arg V2RAY_CLIENT_ID=${v2ray_client_id} -f Dockerfile.web .
# docker run -d --name web_instance --restart=always -v ~/.cert:/etc/nginx/cert -p 80:80 -p 443:443 cert

### Build Cert request and Web server
mkdir -p ~/.cert
docker build -t certweb --rm --build-arg DOMAIN_NAME=${domain_name} --build-arg V2RAY_CLIENT_ID=${v2ray_client_id} -f Dockerfile.certweb .
docker run -d --name certweb_instance --restart=always -v ~/.cert:/etc/nginx/cert -p 80:80 -p 443:443 certweb

### Build Speed Test Web App
docker pull adolfintel/speedtest
docker run -d --name speedtest_instance --restart=always -e MODE=standalone -e TELEMETRY=true -e ENABLE_ID_OBFUSCATION=true -e PASSWORD=${password} adolfintel/speedtest
speedtest_addr=$(docker exec speedtest_instance sh -c "hostname -i")
docker exec -t certweb_instance sh -c "sed -i \"s~127.127.127.127~${speedtest_addr}~\" /etc/nginx/conf.d/speedtest.conf&&nginx -s reload"

### Build Trojan 
certweb_addr=$(docker exec web_instance sh -c "hostname -i")
docker build -t trojan --build-arg PASSWORD=${password} --build-arg DOMAIN_NAME=${domain_name} --build-arg PORT=${trojan_port} --build-arg REMOTE_ADDR=${certweb_addr} --rm -f Dockerfile.trojan .
docker run -d -v ~/.cert:/etc/trojan/cert -p ${trojan_port}:${trojan_port} --restart=always --name trojan_instance trojan

### Build v2ray
docker build -t v2ray --rm --build-arg V2RAY_CLIENT_ID=${v2ray_client_id} -f Dockerfile.v2ray .
docker run -d --name v2ray_instance --restart=always v2ray

### Update web proxy address
v2ray_addr=$(docker exec v2ray_instance sh -c "hostname -i")
docker exec -t certweb_instance sh -c "sed -i \"s~//.*:10000;~//${v2ray_addr}:10000;~\" /etc/nginx/conf.d/*.ssl.conf&&nginx -s reload"
docker exec -t certweb_instance sh -c "sed -i \"s~//.*:10000;~//${v2ray_addr}:10000;~\" /etc/nginx/conf.d/default.conf&&nginx -s reload"

####################################
### Show Info                    ###
####################################

echo -e "###################${Green_font_prefix}请记录${Font_color_suffix}###################"
echo 
echo -e ${Green_font_prefix}"域名："${Red_font_prefix}${domain_name}${Font_color_suffix}
echo -e ${Green_font_prefix}"口令："${Red_font_prefix}${password}${Font_color_suffix}
echo -e ${Green_font_prefix}"v2ray用户ID："${Red_font_prefix}${v2ray_client_id}${Font_color_suffix}
echo
echo -e "############################################"
