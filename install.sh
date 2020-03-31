#!/bin/bash

Green_font_prefix="\033[32m" 
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m" 
Font_color_suffix="\033[0m"

Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

### Get dommain name
while :
do
    read -p "请输入域名：" domain_name
    if [[ $(echo -n $domain_name | wc -m) -gt 0 ]]; then        
        break
    fi
    echo -e ${Error} "域名输入错误"
done
while :
do
    read -p "请输入口令：" password
    if [[ $(echo -n $password | wc -m) -gt 0 ]]; then        
        break
    fi
    echo -e ${Error} "口令输入错误"
done

v2ray_client_id=$(cat /proc/sys/kernel/random/uuid)

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

install_docker_on_centos() {
    sudo yum update -y
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo systemctl enable docker
    sudo systemctl start docker
}

install_docker_on_ubuntu() {
    echo 'install docker on ubuntu'    
}

install_docker() {
    if [[ -f /usr/bin/docker ]]; then
        echo -e ${Info} "发现Docker，无需安装！"
        return
    fi    
    check_sys
    if [[ "${release}" == "centos" ]]; then
        install_docker_on_centos
    elif [[ "${release}" == "ubuntu" ]]; then
        echo "install docker on ubuntu"
    else
        echo -e ${Error} "无法在此系统自动安装Docker。请手工安装"
        exit 1
    fi
    
    sudo usermod -aG docker ${USER}
    exec newgrp docker
}

install_docker

echo -e "###################${Green_font_prefix}请记录${Font_color_suffix}###################"
echo 
echo -e ${Green_font_prefix}"域名："${Red_font_prefix}${domain_name}${Font_color_suffix}
echo -e ${Green_font_prefix}"口令："${Red_font_prefix}${password}${Font_color_suffix}
echo -e ${Green_font_prefix}"v2ray用户ID："${Red_font_prefix}${v2ray_client_id}${Font_color_suffix}
echo
echo -e "############################################"