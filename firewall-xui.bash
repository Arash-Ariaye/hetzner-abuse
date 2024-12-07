#!/bin/bash

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
    echo -e "\033[1;34mChecking firewall prerequisites...\033[0m"
    
    # Check if firewall is installed
    if ! command -v ufw &> /dev/null; then
        echo -e "\033[1;31mFirewall (ufw) is not installed. Installing...\033[0m"
        sudo apt update && sudo apt install ufw -y
    else
        echo -e "\033[1;32mFirewall (ufw) is installed.\033[0m"
    fi
    
    # Check if firewall is active
    if ! sudo ufw status | grep -q "Status: active"; then
        echo -e "\033[1;31mFirewall is not active. Enabling...\033[0m"
        sudo ufw enable
    else
        echo -e "\033[1;32mFirewall is active.\033[0m"
    fi
    
    read -p "Press Enter to return to the menu..."
}

# Function to start port checking in the background
start_port_checking() {
    clear
    echo -e "\033[1;34mPorts currently in use:\033[0m"
    
    # Display ports opened by x-ui
    echo -e "\033[1;34mPorts opened by x-ui:\033[0m"
    sudo lsof -i -P -n | grep x-ui | awk '{print $9}' | cut -d: -f2 | cut -d'>' -f1 | grep -Eo '^[0-9]+$'
    
    # Display ports opened by xray-linu
    echo -e "\033[1;34mPorts opened by xray-linu:\033[0m"
    sudo lsof -i -P -n | grep xray-linu | awk '{print $9}' | cut -d: -f2 | cut -d'>' -f1 | grep -Eo '^[0-9]+$'
    
    sleep 5
    
    check_ports &
    echo $! > /tmp/port_checking.pid
    echo -ne "\033]0;3X-UI Port Checking - \033[32mActive\033[0m\007"
    echo -e "\033[1;32mPort checking started in the background.\033[0m"
    sleep 2
}

# Function to stop port checking
stop_port_checking() {
    if [ -f /tmp/port_checking.pid ]; then
        kill $(cat /tmp/port_checking.pid)
        rm /tmp/port_checking.pid
        echo -ne "\033]0;3X-UI Port Checking - \033[31mDisabled\033[0m\007"
    fi
}

# Main menu
while true; do
    clear
    echo -e "=============================="
    echo -e "      \033[1;34m3X-UI Port Checking\033[0m      "
    echo -e "=============================="
    echo -e "      \033[1;33mDev by Arash\033[0m"
    echo -e "      \033[1;33mTelegram: Arash_Ariaye\033[0m"
    echo -e "=============================="
    if [ -f /tmp/port_checking.pid ]; then
        echo -e "      \033[1;32mActive\033[0m"
    else
        echo -e "      \033[1;31mDisabled\033[0m"
    fi
    echo -e "=============================="
    echo -e "\033[1;32m0. Prerequisites\033[0m"
    echo -e "\033[1;32m1. Enable Port Checking\033[0m"
    echo -e "\033[1;31m2. Disable Port Checking\033[0m"
    echo -e "\033[1;33m3. Exit\033[0m"
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
                echo -e "\033[1;32mPort checking is currently active.\033[0m"
            else
                echo -e "\033[1;31mPort checking is currently inactive.\033[0m"
            fi
            exit 0
            ;;
        *)
            echo -e "\033[1;31mInvalid choice. Please try again.\033[0m"
            sleep 2
            ;;
    esac
done
