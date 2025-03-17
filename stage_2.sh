#!/bin/bash
set -e

if [[ -z "${USER_PASS}" || -z "${TIMEZONE}" || -z "${USER_NAME}" || -z "${USER_GROUPS}" ]]
then
    echo "Переменные окружения не экспортированы корректно"
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