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

options=("Shecan" "Electro" "Begzar" "Google" "403" "CloudFlare" "Radar" "Add Custom DNS" "Default" "About")
dns1_list=($SHECAN_DNS1 $ELECTRO_DNS1 $BEGZAR_DNS1 $GOOGLE_DNS1 $ONLINE_403_DNS1 $CLOUD_FLARE_DNS1 $RADAR_DNS1 "" $DEFALT_DNS1 "")
dns2_list=($SHECAN_DNS2 $ELECTRO_DNS2 $BEGZAR_DNS2 $GOOGLE_DNS2 $ONLINE_403_DNS2 $CLOUD_FLARE_DNS2 $RADAR_DNS2 "" $DEFALT_DNS1 "")

get_current_dns_name() {
    current_dns1=$(grep -m 1 "nameserver" /etc/resolv.conf | awk '{print $2}')
    current_dns2=$(grep -m 2 "nameserver" /etc/resolv.conf | tail -n1 | awk '{print $2}')
    for i in ${!dns1_list[@]}; do
        if [ "$current_dns1" == "${dns1_list[$i]}" ] && [ "$current_dns2" == "${dns2_list[$i]}" ]; then
            echo "${options[$i]}"
            return
        fi
    done
    echo "Unknown"
}

print_menu() {
    clear
    current_dns_name=$(get_current_dns_name)
    echo -e "Current DNS Configuration: ${RED}$current_dns_name${NC}"
    echo -e "\nWhich DNS or option do you want to use?"
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

show_about() {
    clear
    echo -e "${BLUE}About This Script${NC}"
    echo -e "This script allows you to change your DNS settings quickly and easily."
    echo -e "You can choose from several predefined DNS servers or add your own."
    echo -e "For more information and to access other scripts, visit:"
    echo -e "${YELLOW}https://github.com/Mr-Meshky/dns-switcher${NC}"
    echo -e "\nPress any key to return to the menu..."
    read -n1
}

add_custom_dns() {
    clear
    echo -e "${BLUE}Add Custom DNS${NC}"
    read -p "Enter primary DNS: " custom_dns1
    read -p "Enter secondary DNS: " custom_dns2
    dns1_list+=("$custom_dns1")
    dns2_list+=("$custom_dns2")
    options+=("Custom DNS")
    DNS1="$custom_dns1"
    DNS2="$custom_dns2"
    if [ -n "$DNS1" ]; then
        echo -e "\nnameserver $DNS1" | sudo tee /etc/resolv.conf > /dev/null
        echo "nameserver $DNS2" | sudo tee -a /etc/resolv.conf > /dev/null
        cat /etc/resolv.conf
        echo -e "${GREEN}Setting DNS to Custom DNS is done successfully${NC}"
        echo -e "${BLUE}To add your DNS to the tool, you can submit a pull request to the repository or create a new one at:${NC}"
        echo -e "${YELLOW}https://github.com/Mr-Meshky/dns-switcher/issues/new${NC}"
        exit 0
    fi
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
            if [ "${options[$selected]}" == "About" ]; then
                show_about
                print_menu
            elif [ "${options[$selected]}" == "Add Custom DNS" ]; then
                add_custom_dns
            else
                DNS1=${dns1_list[$selected]}
                DNS2=${dns2_list[$selected]}
                break
            fi
            ;;
    esac
    print_menu
done

if [ -n "$DNS1" ]; then
    echo -e "\nnameserver $DNS1" | sudo tee /etc/resolv.conf > /dev/null
    echo "nameserver $DNS2" | sudo tee -a /etc/resolv.conf > /dev/null
    cat /etc/resolv.conf
    echo -e "${GREEN}Setting DNS to ${options[$selected]} is done successfully${NC}"
fi
