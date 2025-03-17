# Yet Another Arch Linux Installer

## Что делает этот скрипт?
1. Форматирует и разбивает необходимое хранилище для использования EFI и btrfs
2. Устанавливает пакеты из списка и настраивает конфигурационные файлы
3. Устанавливает Wayland и Sway WM
4. Создаёт пользователя

## Что нужно редактировать?
1. Перед выполнением скрипта нужно экспортировать `USER_PASS`:

    ```bash
    export USER_PASS="mySuperSecretPass"
    ```

2. Если будет использоваться wlan, перед выполнением скрипта нужно экспортировать `NETWORK_PASS`:

    ```bash
    export NETWORK_PASS="mySuperSecretNetworkPass"
    ```

3. Если будет использоваться wlan, изменить `NETWORK_NAME` на своё
4. Изменить `USER_NAME` на своё
5. Изменить `HOST_NAME` на своё
6. Если будет использоваться SSD, убрать `autodefrag` из `BTRFS_PARAMS`
