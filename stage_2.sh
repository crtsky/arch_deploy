#!/bin/bash
set -e

USER_NAME="coritsky"
USER_GROUPS="users,wheel,audio,video"
TIMEZONE="Europe/Moscow"

if [[ -z "${USER_PASS}" ]]
then
    echo "Не задана переменная окружения USER_PASS"
    exit 1
fi

ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
timedatectl set-timezone ${TIMEZONE}
timedatectl set-ntp true
hwclock --systohc

locale-gen

mkinitcpio -P

grub-install
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G ${USER_GROUPS} -s /bin/bash ${USER_NAME}
echo "${USER_NAME}:${USER_PASS}" | chpasswd

exit 0