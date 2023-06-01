#!/bin/bash
set -eu

# custom_rootfs.sh is only for tn3399_v3 dev board
# see https://github.com/lanseyujie/tn3399_v3.git
# Wildlife <admin@lanseyujie.com>
# 2020.07.10

if [ "$(id -u)" -ne 0 ]; then
    echo "THIS SCRIPT MUST BE RUN AS ROOT"
    exit 1
fi

# 继续构建第二阶段
/debootstrap/debootstrap --second-stage

# 修改主机名
echo debian >/etc/hostname

# 修改 hosts
cat >/etc/hosts <<EOF
127.0.0.1       localhost
127.0.1.1       debian
127.0.1.2       localhost.localdomain

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# 修改时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 更改镜像源
cat >/etc/apt/sources.list <<EOF
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb http://ftp.cn.debian.org/debian/ bullseye main contrib non-free
#deb-src http://ftp.cn.debian.org/debian/ bullseye main contrib non-free
deb http://ftp.cn.debian.org/debian/ bullseye-updates main contrib non-free
#deb-src http://ftp.cn.debian.org/debian/ bullseye-updates main contrib non-free
deb http://ftp.cn.debian.org/debian/ bullseye-backports main contrib non-free
#deb-src http://ftp.cn.debian.org/debian/ bullseye-backports main contrib non-free
deb http://ftp.cn.debian.org/debian/ bullseye/updates main contrib non-free
#deb-src http://ftp.cn.debian.org/debian/ bullseye/updates main contrib non-free
EOF

# 更新软件包
apt-get update && apt-get dist-upgrade -y

#安装软件
apt-get install libglib2.0-bin -y

# 允许 root 远程登录
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# 修改默认密码
echo 'root:1234' | chpasswd
# 设置密码过期
chage -d 0 root

# ttyS2
# 使能串口，如果只是为了制作根文件系统，可以不用运行这个命令
#ln -s /lib/systemd/system/serial-getty\@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyAMA0.service
ln -s /lib/systemd/system/serial-getty\@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyS1.service

#ttl ttys1 115200自动root登陆
exec /sbin/getty -8 -a root 115200 tty1

# 问题报告
cat >/etc/update-motd.d/60-issue-report<<EOF
#!/bin/sh
#
# 60-issue-report is only for sl339am dev board
# see https://github.com/lanseyujie/tn3399_v3.git
# Kai <53637670@qq.com>
# 2023.05.23

printf "\n"
printf " * Issue: https://github.com/lanseyujie/tn3399_v3/issues"
EOF
chmod +x /etc/update-motd.d/60-issue-report

# 清理
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f ~/.bash_history
rm -f /usr/bin/qemu-aarch64-static
