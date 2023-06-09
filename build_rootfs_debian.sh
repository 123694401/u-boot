#!/bin/bash
set -eu

# build_rootfs.sh is only for tn3399_v3 dev board
# see https://github.com/lanseyujie/tn3399_v3.git
# Kai <53637670@qq.com>
# 2020.06.24

SCRIPTS_PATH=$(
    cd "$(dirname "$0")"
    pwd
)
PROJECT_PATH=$(dirname "$SCRIPTS_PATH")
PWD_PATH=$(pwd)
OUTPUT_PATH=$PROJECT_PATH/out
OVERLAY_PATH=$PROJECT_PATH/overlay
ROOTFS_PATH=$OUTPUT_PATH/rootfs

TARGET=$1

mount_rootfs() {
    mount -t proc /proc "$ROOTFS_PATH"/proc
    mount -t sysfs /sys "$ROOTFS_PATH"/sys
    mount -o bind /dev "$ROOTFS_PATH"/dev
    mount -o bind /dev/pts "$ROOTFS_PATH"/dev/pts

    echo "ROOTFS: MOUNTED"
}

umount_rootfs() {
    umount "$ROOTFS_PATH"/proc
    umount "$ROOTFS_PATH"/dev/pts
    umount "$ROOTFS_PATH"/dev
    umount "$ROOTFS_PATH"/sys
   
    echo "ROOTFS: UNMOUNTED"
}

custom_rootfs() {
    rm -rf "$ROOTFS_PATH"
    mkdir -p "$ROOTFS_PATH"

    # 安装构建工具
    apt install -y qemu-user-static debootstrap
    # 构建 rootfs
    debootstrap --arch=arm64 --include=systemd-journal-remote,nano,vim,curl,wget,ssh,sudo,snmpd,snmp,apt-transport-https,ca-certificates --components=main,restricted,multiverse,universe --foreign bullseye "$ROOTFS_PATH" http://ftp.cn.debian.org/debian/

    cp /usr/bin/qemu-aarch64-static "$ROOTFS_PATH"/usr/bin/
    cp -rf "$OVERLAY_PATH"/* "$ROOTFS_PATH"/

    # 挂载路径
    mount_rootfs

    # 执行出错时自动卸载路径
    trap umount_rootfs ERR
    # trap umount_rootfs EXIT

    # 执行自定义修改
    chroot <"$SCRIPTS_PATH"/custom_rootfs_debian.sh "$ROOTFS_PATH"

    # 安装内核模块
    # cd $(dirname "$PROJECT_PATH")/linux && make modules_install INSTALL_MOD_PATH="$ROOTFS_PATH"
    # cd $(dirname "$PROJECT_PATH")/linux && make modules_install ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc) INSTALL_MOD_PATH="$ROOTFS_PATH"

    # 卸载路径
    umount_rootfs

    echo "ROOTFS: BUILD SUCCEED"
}

if [ "$(id -u)" -ne 0 ]; then
    echo "THIS SCRIPT MUST BE RUN AS ROOT"
    exit 1
fi

if [ "$TARGET" == "custom" ] || [ "$TARGET" == "c" ]; then
    custom_rootfs
elif [ "$TARGET" == "mount" ] || [ "$TARGET" == "m" ]; then
    mount_rootfs
elif [ "$TARGET" == "umount" ] || [ "$TARGET" == "u" ]; then
    umount_rootfs
else
    echo
    echo "usage:"
    echo "build_rootfs.sh <custom | c>"
    echo "build_rootfs.sh <mount | m>"
    echo "build_rootfs.sh <umount | u>"
    echo
fi
