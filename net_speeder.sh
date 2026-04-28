cat << 'EOF' > /root/netspeeder.sh
#!/bin/bash
echo "--- 正在开始一键安装与配置 (修复路径兼容版) ---"

# 1. 更新并安装基础环境
apt-get update
apt-get install -y build-essential libnet1-dev libpcap0.8-dev wget unzip ethtool

# 2. 确定 ethtool 的绝对路径 (防止 systemd 找不到)
ETHTOOL_PATH=$(which ethtool)
if [ -z "$ETHTOOL_PATH" ]; then
    echo "错误: 未能安装 ethtool，请检查网络。"
    exit 1
fi
echo "ethtool 路径: $ETHTOOL_PATH"

# 3. 下载并解压
cd /root
rm -rf net-speeder-master*
wget --no-check-certificate https://github.com/snooda/net-speeder/archive/master.zip -O net-speeder-master.zip
unzip -o net-speeder-master.zip
cd net-speeder-master

# 4. 编译
if [ -d "/proc/vz" ]; then
    echo "检测到 OpenVZ 环境，使用 COOKED 模式编译..."
    sh build.sh -DCOOKED
else
    echo "检测到 KVM/物理机环境，使用普通模式编译..."
    sh build.sh
fi

# 检查编译结果
if [ ! -f "/root/net-speeder-master/net_speeder" ]; then
    echo "编译失败，文件未生成！"
    exit 1
fi

# 5. 获取网卡名称
INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
[ -z "$INTERFACE" ] && INTERFACE="eth0"
echo "加速网卡: $INTERFACE"

# 6. 写入 Systemd 服务 (使用绝对路径和自动检测的 ethtool)
cat << SERVICE > /etc/systemd/system/net-speeder.service
[Unit]
Description=net-speeder Optimization Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/net-speeder-master
# 核心修复：动态使用 ethtool 路径并关闭 TSO
ExecStartPre=$ETHTOOL_PATH -K $INTERFACE tso off
ExecStart=/root/net-speeder-master/net_speeder $INTERFACE "ip"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# 7. 启动服务
systemctl daemon-reload
systemctl enable net-speeder
systemctl restart net-speeder

echo "------------------------------------------------"
echo "安装并修复完成！"
echo "服务状态: \$(systemctl is-active net-speeder)"
echo "------------------------------------------------"
systemctl status net-speeder --no-pager
EOF

# 授权并立刻执行
chmod +x /root/netspeeder.sh
/root/netspeeder.sh