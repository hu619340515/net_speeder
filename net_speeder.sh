#!/bin/bash

# NetSpeeder 一键安装脚本 (带实时进度版)
# 全程自动化，并显示详细的安装过程

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
INSTALL_DIR="/usr/local/netspeeder"

# 1. 检查 Root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}错误: 请使用 root 用户运行此脚本！${NC}"
  exit 1
fi

# 2. 自动获取主网卡名称
get_main_nic() {
    NIC=$(ip route | grep default | awk '{print $5}' | head -n 1)
    if [ -z "$NIC" ]; then
        NIC=$(ip link | grep -E "^[0-9]+:" | grep -v "lo:" | awk -F: '{print $2}' | awk '{print $1}' | head -n 1)
    fi
    if [ -z "$NIC" ] && [ -e /dev/net/tun ]; then
        NIC="venet0"
    fi
    echo "$NIC"
}

# 3. 自动安装依赖 (已移除静音参数，显示详细过程)
echo -e "${GREEN}>>> 正在安装编译依赖 (gcc, make, libpcap)...${NC}"
if [ -f /etc/redhat-release ]; then
    echo -e "${YELLOW}[CentOS/RedHat] 正在运行 yum 安装依赖：${NC}"
    yum install -y wget gcc gcc-c++ libpcap-devel make unzip
elif [ -f /etc/debian_version ]; then
    echo -e "${YELLOW}[Debian/Ubuntu] 正在运行 apt-get 更新和安装依赖：${NC}"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget gcc g++ libpcap0.8-dev make unzip
else
    echo -e "${RED}不支持的操作系统！${NC}"
    exit 1
fi

# 4. 下载并编译源码 (显示下载进度)
echo -e "${GREEN}>>> 正在下载并编译 NetSpeeder...${NC}"
wget --no-check-certificate -O /tmp/netspeeder.zip https://github.com/hu619340515/net_speeder/archive/refs/heads/main.zip
if [ ! -f "/tmp/netspeeder.zip" ]; then
    echo -e "${RED}下载失败！请检查网络。${NC}"
    exit 1
fi

echo -e "${YELLOW}正在解压源码并进入编译：${NC}"
unzip -o /tmp/netspeeder.zip -d /tmp/
cd /tmp/net_speeder-main || exit
sh build.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}编译失败！请检查上方报错信息。${NC}"
    exit 1
fi

mkdir -p "$INSTALL_DIR"
cp netspeeder "$INSTALL_DIR/"
echo -e "${GREEN}>>> 编译安装成功！${NC}"

# 5. 配置开机自启与启动服务
NIC=$(get_main_nic)
if [ -z "$NIC" ]; then
    echo -e "${RED}无法自动识别网卡，安装中止！${NC}"
    exit 1
fi
echo -e "${GREEN}>>> 检测到主网卡为: $NIC，正在配置开机自启...${NC}"

if command -v systemctl &> /dev/null; then
    # 现代系统使用 systemd
    cat > /etc/systemd/system/netspeeder.service <<EOF
[Unit]
Description=NetSpeeder Network Accelerator
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/netspeeder $NIC "ip"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${YELLOW}正在重载 systemd 配置并启动服务：${NC}"
    systemctl daemon-reload
    systemctl enable netspeeder.service
    systemctl restart netspeeder.service
else
    # 老旧系统降级使用 rc.local
    killall netspeeder 2>/dev/null
    nohup $INSTALL_DIR/netspeeder $NIC "ip" > /dev/null 2>&1 &
    sed -i '/netspeeder/d' /etc/rc.local
    echo "nohup $INSTALL_DIR/netspeeder $NIC \"ip\" >/dev/null 2>&1 &" >> /etc/rc.local
    chmod +x /etc/rc.local
    echo -e "${YELLOW}检测到老旧系统，已使用 rc.local 配置自启。${NC}"
fi

# 6. 检查并输出最终状态
sleep 2
echo -e "${GREEN}========================================${NC}"
if command -v systemctl &> /dev/null && systemctl is-active --quiet netspeeder; then
    echo -e "${GREEN} NetSpeeder 已成功安装并启动！${NC}"
    echo -e "${GREEN} 运行状态: active (running)${NC}"
else
    echo -e "${YELLOW} NetSpeeder 已安装，正在后台运行。${NC}"
fi
echo -e "${GREEN} 加速网卡: $NIC${NC}"
echo -e "${GREEN}========================================${NC}"
