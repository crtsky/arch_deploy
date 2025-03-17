#!/bin/bash

set -e

               USER_NAME="coritsky"
               HOST_NAME="samsung"
             USER_GROUPS="users,wheel,audio,video"

                    KEYS="ru"
                    FONT="cyr-sun16"
               BOOT_MODE=64
       
     # File System Settings
                 STORAGE="/dev/sda"
                EFI_SIZE="1025MiB"
         EFI_MOUNT_POINT="/boot/efi"
        ROOT_MOUNT_POINT="/mnt"
                DIR_LIST=("" "home" "opt" "root" "snapshots" "srv" "tmp" "var")
            BTRFS_PARAMS="compress=zstd:9,commit=120,autodefrag"
       
     # Network Settings
          INTERFACE_LIST=$( ip link show | grep UP | awk -F ': ' '{print $2}')
            NETWORK_NAME="TP-Link_1646"
                TIMEZONE="Europe/Moscow"
       
            PACKAGE_LIST=( "base"
                           "base-devel"
                           "linux"
                           "linux-headers"
                           "linux-firmware"
                           "grub"
                           "nano"
                           "iwd"
                           "btrfs-progs"
                           "wayland"
                           "sway"
                           "foot"
                           "git"
                           "efibootmgr"
                           "sudo"
                         )

     SECOND_STAGE_SCRIPT="stage_2.sh"
SECOND_STAGE_SCRIPT_LINK="https://raw.githubusercontent.com/crtsky/arch_deploy/refs/heads/main/${SECOND_STAGE_SCRIPT}"

loadkeys ${KEYS}
setfont ${FONT}

echo "Проверка режима загрузки"
if [[ $( cat /sys/firmware/efi/fw_platform_size ) != ${BOOT_MODE} ]]
then
    echo "Система не загружена в необходимом режиме"
    exit 1
fi

if [[ -z "${USER_PASS}" ]]
then
    echo "Не задана переменная окружения USER_PASS"
    exit 1
fi

echo "Поиск сетевого интерфейса"
for INTERFACE in ${INTERFACE_LIST}
do
    if [[ ${INTERFACE} == "wlan0" ]]
    then
        if [[ -z "${NETWORK_PASS}" ]]
        then
            echo "Не задана переменная окружения NETWORK_PASS"
            exit 1
        fi

        iwctl --passphrase=${NETWORK_PASS} station ${INTERFACE} connect ${NETWORK_NAME}
        break
    fi
done

echo "Проверка сетевого соединения"
if [[ $(ping -c 1 8.8.8.8 &> /dev/null; echo $?) == 0 ]]
then
    timedatectl set-timezone ${TIMEZONE}
    timedatectl set-ntp true
else
    echo "Сетевое соединение отсутствует"
    exit 1
fi

echo "Разметка диска"
parted -s ${STORAGE} mklabel gpt
parted -s ${STORAGE} mkpart ESP fat32 1MiB ${EFI_SIZE}
parted -s ${STORAGE} set 1 boot on
parted -s ${STORAGE} mkpart primary btrfs ${EFI_SIZE} 100%

echo "Форматрование"
mkfs.fat -F 32 ${STORAGE}1
mkfs.btrfs -L arch_linux ${STORAGE}2

echo "Создание субвольюмов"
mount ${STORAGE}2 ${ROOT_MOUNT_POINT}

for (( i=0; i < ${#DIR_LIST[@]}; i++ ))
do
    btrfs subvolume create ${ROOT_MOUNT_POINT}/@${DIR_LIST[i]}
done

umount ${ROOT_MOUNT_POINT}

echo "Монтирование разделов"
mount -o subvol=@${DIR_LIST[0]},${BTRFS_PARAMS} ${STORAGE}2 ${ROOT_MOUNT_POINT}/
mkdir -p ${ROOT_MOUNT_POINT}${EFI_MOUNT_POINT}
mount ${STORAGE}1 ${ROOT_MOUNT_POINT}${EFI_MOUNT_POINT}

for (( i=1; i < ${#DIR_LIST[@]}; i++ ))
do
    mkdir ${ROOT_MOUNT_POINT}/${DIR_LIST[i]}
    mount -o subvol=@${DIR_LIST[i]},${BTRFS_PARAMS} ${STORAGE}2 $ROOT_MOUNT_POINT/${DIR_LIST[i]}
done

echo "Установка пакетов"
pacstrap ${ROOT_MOUNT_POINT} ${PACKAGE_LIST[@]}

echo "Генерация fstab"
genfstab -U ${ROOT_MOUNT_POINT} >> ${ROOT_MOUNT_POINT}/etc/fstab

echo "Установка hostname"
echo ${HOST_NAME} > ${ROOT_MOUNT_POINT}/etc/hostname

echo "Подготовка файлов конфигурации локалей"
sed -i "s/#\(en_US\.UTF-8\)/\1/" ${ROOT_MOUNT_POINT}/etc/locale.gen
sed -i "s/#\(ru_RU\.UTF-8\)/\1/" ${ROOT_MOUNT_POINT}/etc/locale.gen

echo "LANG=ru_RU.UTF-8" > ${ROOT_MOUNT_POINT}/etc/locale.conf

echo "KEYMAP=ru" > ${ROOT_MOUNT_POINT}/etc/vconsole.conf
echo "FONT=cyr-sun16" >> ${ROOT_MOUNT_POINT}/etc/vconsole.conf

echo "Подготовка конфигурации mkinitcpio"
cp ${ROOT_MOUNT_POINT}/etc/mkinitcpio.conf ${ROOT_MOUNT_POINT}/etc/mkinitcpio.conf.bkp
sed -i 's/\(HOOKS=\(.*\)fsck\(.*\)\)/HOOKS=\2\3/' ${ROOT_MOUNT_POINT}/etc/mkinitcpio.conf

echo "Добавление группы wheel в sudoers"
sed -i '/# %wheel ALL=(ALL:ALL) ALL/s/^# //' ${ROOT_MOUNT_POINT}/etc/sudoers

echo "Загрузка скрипта для второго этапа"
curl -X GET ${SECOND_STAGE_SCRIPT_LINK} -o ${ROOT_MOUNT_POINT}/${SECOND_STAGE_SCRIPT}
chmod +x ${ROOT_MOUNT_POINT}/${SECOND_STAGE_SCRIPT}

echo "Переход в новое окружение"
arch-chroot ${ROOT_MOUNT_POINT}  /bin/bash -c "
    export USER_PASS='${USER_PASS}' &&
    export USER_NAME='${USER_NAME}' &&
    export TIMEZONE='${TIMEZONE}' &&
    export USER_GROUPS='${USER_GROUPS}'
    /'${SECOND_STAGE_SCRIPT}'
"
echo "Завершение..."
rm ${ROOT_MOUNT_POINT}/${SECOND_STAGE_SCRIPT}
reboot