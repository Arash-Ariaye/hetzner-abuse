#!/bin/bash

Red="\033[1;31m"
Green="\033[1;32m"
Yellow="\033[1;33m"
Blue="\033[1;34m"
Plain="\033[0m"

# Function to check firewall status and open ports
check_ports() {
    while true; do
        # Check ports opened by x-ui
        xui_ports=$(sudo lsof -i -P -n | grep x-ui | awk '{print $9}' | cut -d: -f2 | cut -d'>' -f1 | grep -Eo '^[0-9]+$')
        for port in $xui_ports; do
            if ! sudo ufw status | grep -q "$port"; then
                sudo ufw allow in "$port" &> /dev/null
                sudo ufw allow out "$port" &> /dev/null
            fi
        done

        # Check ports opened by xray-linu
        xray_ports=$(sudo lsof -i -P -n | grep xray-linu | awk '{print $9}' | cut -d: -f2 | cut -d'>' -f1 | grep -Eo '^[0-9]+$')
        for port in $xray_ports; do
            if ! sudo ufw status | grep -q "$port"; then
                sudo ufw allow in "$port" &> /dev/null
                sudo ufw allow out "$port" &> /dev/null
            fi
        done
        
        sleep 30
    done
}

# Function to check and install firewall
check_firewall() {
    clear
    echo -e "${Blue}Checking firewall prerequisites...${Plain}"
    
    # Check if firewall is installed
    if ! command -v ufw &> /dev/null; then
        echo -e "${Red}Firewall (ufw) is not installed. Installing...${Plain}"
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            release=$ID
        elif [[ -f /usr/lib/os-release ]]; then
            source /usr/lib/os-release
            release=$ID
        else
            echo "Failed to check the system OS, please contact the author!" >&2
            exit 1
        fi
        echo "The OS release is: $release"
        case "${release}" in
        centos | fedora | almalinux)
            yum upgrade && yum install -y -q ufw
            ;;
        arch | manjaro)
            pacman -Sy --noconfirm ufw
            ;;
        *)
            apt update && apt install -y -q ufw
            ;;
        esac
    else
        echo -e "${Green}Firewall (ufw) is installed.${Plain}"
    fi
    
    # Check if firewall is active
    if ! sudo ufw status | grep -q "Status: active"; then
        echo -e "${Red}Firewall is not active. Enabling...${Plain}"
        sudo ufw enable
    else
        echo -e "${Green}Firewall is active.${Plain}"
    fi
    
    read -r -p "Press Enter to return to the menu..."
}

# Function to start port checking in the background
start_port_checking() {
    clear
    echo -e "${Blue}Ports currently in use:${Plain}"
    
    # Display ports opened by x-ui
    echo -e "${Blue}Ports opened by x-ui:${Plain}"
    sudo lsof -i -P -n | grep x-ui | awk '{print $9}' | cut -d: -f2 | cut -d'>' -f1 | grep -Eo '^[0-9]+$'
    
    # Display ports opened by xray-linu
    echo -e "${Blue}Ports opened by xray-linu:${Plain}"
    sudo lsof -i -P -n | grep xray-linu | awk '{print $9}' | cut -d: -f2 | cut -d'>' -f1 | grep -Eo '^[0-9]+$'
    
    sleep 5
    
    check_ports &
    echo $! > /tmp/port_checking.pid
    echo -ne "${Plain}3X-UI Port Checking - ${Green}Active${Plain}"
    echo -e "${Green}Port checking started in the background.${Plain}"
    sleep 2
}

# Function to stop port checking
stop_port_checking() {
    if [ -f /tmp/port_checking.pid ]; then
        kill "$(cat /tmp/port_checking.pid)"
        rm /tmp/port_checking.pid
        echo -ne "${Plain}3X-UI Port Checking - ${Red}Disabled${Plain}"
    fi
}

# Main menu
while true; do
    clear
    echo -e "=============================="
    echo -e "      ${Blue}3X-UI Port Checking${Plain}      "
    echo -e "=============================="
    echo -e "      ${Yellow}Dev by Arash${Plain}"
    echo -e "      ${Yellow}Telegram: Arash_Ariaye${Plain}"
    echo -e "=============================="
    if [ -f /tmp/port_checking.pid ]; then
        echo -e "      ${Green}Active${Plain}"
    else
        echo -e "      ${Red}Disabled${Plain}"
    fi
    echo -e "=============================="
    echo -e "${Green}0. Prerequisites${Plain}"
    echo -e "${Green}1. Enable Port Checking${Plain}"
    echo -e "${Red}2. Disable Port Checking${Plain}"
    echo -e "${Yellow}3. Exit${Plain}"
    echo -e "=============================="
    read -p "Enter your choice: " choice
    
    case $choice in
        0)
            check_firewall
            ;;
        1)
            start_port_checking
            ;;
        2)
            stop_port_checking
            ;;
        3)
            clear
            if [ -f /tmp/port_checking.pid ]; then
                echo -e "${Green}Port checking is currently active.${Plain}"
            else
                echo -e "${Red}Port checking is currently inactive.${Plain}"
            fi
            exit 0
            ;;
        *)
            echo -e "${Red}Invalid choice. Please try again.${Plain}"
            sleep 2
            ;;
    esac
done
