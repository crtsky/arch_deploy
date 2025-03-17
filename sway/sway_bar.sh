       CLOCK=$(date "+%H:%M")
        DATE=$(date "+%F %a")
  AUDIO_MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
AUDIO_VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}')
    WIFI_DEV=$(iwctl device list | awk '{print$2}' | head -5 | tail -1)
    LANGUAGE=$(swaymsg -r -t get_inputs | awk '/1:1:AT_Translated_Set_2_keyboard/;/xkb_active_layout_name/' | grep -A1 '\b1:1:AT_Translated_Set_2_keyboard\b' | grep "xkb_active_layout_name" | awk -F '"' '{print $4}')

if [ $AUDIO_MUTE = "yes" ]
then
    AUDIO_ACTIVE='🔇'
else
    AUDIO_ACTIVE='🔊'
fi

## if [ $wifi_dev != 'wlan0' ] && [[ $(iwctl station $wifi_dev show | awk '{print $2}' | head -6 | tail -1) == "connected" ]];
## then iwctl station wlan0 disconnect
## fi

if [[ $(iwctl station $WIFI_DEV show | awk '{print$1$2}') == "Nostation" ]]
then
    ESSID="Station down ⛔"

elif [[ $(iwctl station $WIFI_DEV show | awk '{print $2}' | head -6 | tail -1) == "disconnected" ]]
then
    ESSID="Disconnected ⛔"
else
    ESSID=$(iwctl station $WIFI_DEV show | awk '{print $3}' | head -7 | tail -1)
fi

#temperature=$(sensors | awk '{print $2}' | head -3 | tail -1 )
#ping=$(ping -c 1 www.google.com | tail -1| awk '{print $4}' | cut -d '/' -f 2 | cut -d '.' -f 1)
#zram_chromium=$(zramctl | awk '{print $6}' | tail -1)
#memory_used=$(free -h | awk '{print $3}' | tail -2 | head -1)

echo "| $AUDIO_ACTIVE $AUDIO_VOLUME | $ESSID | ⌨ $LANGUAGE | $DATE | $CLOCK |"
