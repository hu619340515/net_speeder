# Net-Speeder 一键安装与管理脚本

[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-orange.svg)](https://www.ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

这是一个为 Linux 服务器（特别是高延迟、丢包严重的 VPS）设计的 `net-speeder` 一键安装与自动配置脚本。

`net-speeder` 通过强制双倍发包，在高丢包的网络环境下（如跨国链路）显著提升单线程下载速度和网页打开效率。

## 🚀 功能特点

- **全自动安装**：自动补齐 `gcc`、`libpcap`、`libnet` 等编译依赖。
- **智能适配**：自动识别 **KVM** 或 **OpenVZ** 架构，并采用对应的编译模式。
- **开机自启**：基于 `Systemd` 实现后台持续运行，服务器重启后无需手动开启。
- **兼容性修复**：自动检测 `ethtool` 路径并关闭 `TSO`，修复 KVM 环境下可能出现的 `Message too long` 错误。

## 🛠️ 一键安装

在终端执行以下命令（需要 root 权限）：

wget --no-check-certificate -O netspeeder.sh [https://raw.githubusercontent.com/hu619340515/net_speeder/main/netspeeder.sh](https://raw.githubusercontent.com/hu619340515/net_speeder/main/netspeeder.sh) && chmod +x netspeeder.sh && ./netspeeder.sh

wget --no-check-certificate -O net_speeder.sh   https://raw.githubusercontent.com/hu619340515/net_speeder/main/net_speeder.sh   && chmod +x net_speeder.sh && ./net_speeder.sh


任务,命令
查看实时日志,journalctl -u net-speeder -f
查看运行状态,systemctl status net-speeder
重启服务,systemctl restart net-speeder
停止服务,systemctl stop net-speeder
禁用开机自启,systemctl disable net-speeder


https://github.com/byJoey/Actions-bbr-v3
bbr加速

https://github.com/XTLS/Xray-core/releases/tag/v26.4.25
客户端

bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
服务端
