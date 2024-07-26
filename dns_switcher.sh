#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SHECAN_DNS1="178.22.122.100"
SHECAN_DNS2="185.51.200.2"
ELECTRO_DNS1="78.157.42.100"
ELECTRO_DNS2="78.157.42.101"
BEGZAR_DNS1="185.55.226.26"
BEGZAR_DNS2="185.55.225.25"
DEFALT_DNS1="127.0.0.53"
GOOGLE_DNS1="8.8.8.8"
GOOGLE_DNS2="8.8.4.4"
ONLINE_403_DNS1="10.202.10.202"
ONLINE_403_DNS2="10.202.10.102"
CLOUD_FLARE_DNS1="1.1.1.1"
CLOUD_FLARE_DNS2="1.0.0.1"
RADAR_DNS1="10.202.10.10"
RADAR_DNS2="10.202.10.11"

options=("Shecan" "Electro" "Begzar" "Google" "403" "CloudFlare" "Radar" "Default")
dns1_list=($SHECAN_DNS1 $ELECTRO_DNS1 $BEGZAR_DNS1 $GOOGLE_DNS1 $ONLINE_403_DNS1 $CLOUD_FLARE_DNS1 $RADAR_DNS1 $DEFALT_DNS1)
dns2_list=($SHECAN_DNS2 $ELECTRO_DNS2 $BEGZAR_DNS2 $GOOGLE_DNS2 $ONLINE_403_DNS2 $CLOUD_FLARE_DNS2 $RADAR_DNS2 $DEFALT_DNS1)

print_menu() {
    clear
    echo "Which DNS do you want to use?"
    for i in ${!options[@]}; do
        if [ $i -eq $selected ]; then
            tput setaf 4; tput bold
            echo "-> ${options[$i]}"
            tput sgr0
        else
            echo "   ${options[$i]}"
        fi
    done
}

selected=0

print_menu

while true; do
    read -rsn1 input
    case $input in
        A) 
            ((selected--))
            if [ $selected -lt 0 ]; then
                selected=$((${#options[@]} - 1))
            fi
            ;;
        B) 
            ((selected++))
            if [ $selected -ge ${#options[@]} ]; then
                selected=0
            fi
            ;;
        "") 
            DNS1=${dns1_list[$selected]}
            DNS2=${dns2_list[$selected]}
            break
            ;;
    esac
    print_menu
done

echo "nameserver $DNS1" | sudo tee /etc/resolv.conf > /dev/null
echo "nameserver $DNS2" | sudo tee -a /etc/resolv.conf > /dev/null
cat /etc/resolv.conf

echo -e "${GREEN}Setting DNS to ${options[$selected]} is done successfully${NC}\n"
echo -e "${YELLOW}Developed by MrMeshky.ir with love${NC}"