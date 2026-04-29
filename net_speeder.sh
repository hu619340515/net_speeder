#!/bin/bash

# NetSpeeder 一键编译安装脚本 (整合版)
# 适用于 CentOS 6/7 和 Debian/Ubuntu (KVM/VPS)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 1. 检查是否为 Root 用户
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}错误: 请使用 root 用户运行此脚本！${NC}"
  exit 1
fi

# 2. 自动安装依赖环境
install_deps() {
    echo -e "${GREEN}>>> 正在检测并安装编译依赖 (gcc, make, libpcap)...${NC}"
    
    if [ -f /etc/redhat-release ]; then
        # CentOS/RedHat 系统
        yum install -y wget gcc gcc-c++ libpcap-devel make > /dev/null 2>&1
    elif [ -f /etc/debian_version ]; then
        # Debian/Ubuntu 系统
        apt-get update > /dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y wget gcc g++ libpcap0.8-dev make > /dev/null 2>&1
    else
        echo -e "${RED}不支持的操作系统，请手动安装 gcc, make, libpcap-dev${NC}"
        exit 1
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}依赖安装失败，请检查网络连接或系统源${NC}"
        exit 1
    fi
    echo -e "${GREEN}>>> 依赖安装完成${NC}"
}

# 3. 下载源码
download_source() {
    echo -e "${GREEN}>>> 正在下载 NetSpeeder 源码...${NC}"
    # 使用修正后的文件名 net_speeder.sh (双 e) 和 main 分支
    wget --no-check-certificate -O net_speeder.sh https://raw.githubusercontent.com/hu619340515/net_speeder/main/net_speeder.sh
    
    if [ ! -f "net_speeder.sh" ]; then
        echo -e "${RED}源码下载失败！${NC}"
        exit 1
    fi
    
    # 赋予执行权限并运行下载下来的安装逻辑
    chmod +x net_speeder.sh
}

# 4. 执行安装
main() {
    install_deps
    download_source
    
    echo -e "${GREEN}>>> 开始执行 NetSpeeder 安装...${NC}"
    # 执行刚才下载的脚本
    # 注意：这里直接调用下载的脚本，它内部会进行编译
    ./net_speeder.sh
}

main
