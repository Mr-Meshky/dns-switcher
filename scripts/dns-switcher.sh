#!/usr/bin/env bash

# ==============================================================================
# DNS Switcher - Fast, Interactive & CLI DNS Manager for Linux & macOS
# Author: MrMeshky (https://mrmeshky.ir)
# Repository: https://github.com/Mr-Meshky/dns-switcher
# ==============================================================================

VERSION="3.0.1"

# --- Colors & Styles ---
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# --- Configuration paths ---
CONFIG_DIR="$HOME/.config/dns-switcher"
CUSTOM_DNS_FILE="$CONFIG_DIR/custom_dns.conf"

mkdir -p "$CONFIG_DIR" 2>/dev/null
touch "$CUSTOM_DNS_FILE" 2>/dev/null

# --- Predefined DNS Database ---
# Format: KEY|NAME|DNS1|DNS2|CATEGORY|DESCRIPTION
DNS_DATABASE=(
    # Anti-Sanction & Developer
    "shecan|Shecan|178.22.122.100|185.51.200.2|Anti-Sanction|Popular Iranian anti-sanction DNS"
    "403|403 Online|10.202.10.202|10.202.10.102|Anti-Sanction|Anti-sanction service for developers & IT"
    "electro|Electro|78.157.42.100|78.157.42.101|Anti-Sanction|Anti-sanction for gaming & dev tools"
    "radar|Radar Game|10.202.10.10|10.202.10.11|Anti-Sanction|Low latency gaming & anti-sanction"
    "begzar|Begzar|185.55.226.26|185.55.225.25|Anti-Sanction|Anti-sanction DNS for websites & apps"
    "shelter|Shelter|185.86.136.241|185.86.136.242|Anti-Sanction|Anti-sanction DNS for developers"
    "level15|Level 15|185.105.238.167|185.105.239.167|Anti-Sanction|Gaming & anti-sanction DNS"
    "hostiran|Hostiran|172.29.0.100|172.29.2.100|Anti-Sanction|Hostiran developer DNS"
    "vanilla|Vanilla DNS|10.202.10.100|10.202.10.101|Anti-Sanction|Iranian anti-sanction DNS"
    "pishrun|Pishrun|5.202.100.100|5.202.100.101|Anti-Sanction|Fast anti-sanction DNS for AI & dev"

    # Global & High Speed
    "cloudflare|Cloudflare|1.1.1.1|1.0.0.1|Global|Fastest global privacy-focused DNS"
    "google|Google Public DNS|8.8.8.8|8.8.4.4|Global|Reliable & fast global DNS"
    "quad9|Quad9|9.9.9.9|149.112.112.112|Global|Security & malware blocking DNS"
    "controld|Control D|76.76.2.0|76.76.10.0|Global|Next-gen high performance DNS"
    "opendns|OpenDNS (Cisco)|208.67.222.222|208.67.220.220|Global|Cisco high-availability DNS"

    # AdBlock & Family Safety
    "adguard|AdGuard DNS|94.140.14.14|94.140.15.15|AdBlock|Blocks ads, trackers & phishing"
    "adguard-family|AdGuard Family|94.140.14.15|94.140.15.16|AdBlock|Blocks ads & adult content"
)

# Benchmark test domains for sanction bypassing
BENCHMARK_DOMAINS=(
    "registry-1.docker.io:Docker Hub"
    "api.openai.com:OpenAI"
    "developer.android.com:Android Dev"
    "figma.com:Figma"
    "plugins.gradle.org:Gradle"
    "dl.google.com:Google Dev"
)

# ==============================================================================
# Helper Functions: OS & Network
# ==============================================================================

detect_os() {
    local os_name
    os_name=$(uname -s)
    case "$os_name" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

get_active_mac_service() {
    # 1. Get default routing interface (e.g. en0)
    local default_dev
    default_dev=$(route -n get default 2>/dev/null | grep 'interface:' | awk '{print $2}')
    
    # If default device is virtual/tunnel (utun, ppp, ipsec, etc.) or empty, find active physical interface
    if [[ -z "$default_dev" || "$default_dev" =~ ^(utun|ppp|ipsec|gif|stf) ]]; then
        local candidate
        for candidate in $(scutil --nwi 2>/dev/null | awk '{print $1}' | grep -E '^en[0-9]+'); do
            if ifconfig "$candidate" 2>/dev/null | grep -q "status: active"; then
                default_dev="$candidate"
                break
            fi
        done
    fi

    if [ -z "$default_dev" ]; then
        default_dev="en0"
    fi

    # 2. Map hardware port/device to Network Service name
    local service_name=""
    local current_service=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^(\(\*?[0-9*]+\)[[:space:]]*)+(.*)$ ]]; then
            current_service="${BASH_REMATCH[2]}"
            current_service="$(echo "$current_service" | sed -e 's/[[:space:]]*$//')"
        elif [[ "$line" =~ ^\(Hardware\ Port:[[:space:]]*(.*),[[:space:]]*Device:[[:space:]]*(.*)\)$ ]]; then
            local dev="${BASH_REMATCH[2]}"
            dev="$(echo "$dev" | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            if [ -n "$dev" ] && [ "$dev" == "$default_dev" ]; then
                service_name="$current_service"
                break
            fi
        fi
    done < <(networksetup -listnetworkserviceorder 2>/dev/null)

    # Fallback if not found
    if [ -z "$service_name" ]; then
        if networksetup -listallnetworkservices 2>/dev/null | grep -qx "Wi-Fi"; then
            service_name="Wi-Fi"
        elif networksetup -listallnetworkservices 2>/dev/null | grep -qx "Ethernet"; then
            service_name="Ethernet"
        else
            service_name=$(networksetup -listallnetworkservices 2>/dev/null | grep -v '^\*' | grep -v 'An asterisk' | head -n 1)
        fi
    fi

    if [ -z "$service_name" ]; then
        service_name="Wi-Fi"
    fi
    echo "$service_name"
}

get_active_linux_interface() {
    local default_iface
    default_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)
    if [ -z "$default_iface" ]; then
        default_iface=$(route -n 2>/dev/null | grep '^0.0.0.0' | awk '{print $8}' | head -n1)
    fi
    echo "$default_iface"
}

flush_dns_cache() {
    local os
    os=$(detect_os)
    if [ "$os" == "macos" ]; then
        sudo dscacheutil -flushcache 2>/dev/null
        sudo killall -HUP mDNSResponder 2>/dev/null
    elif [ "$os" == "linux" ]; then
        if command -v resolvectl >/dev/null 2>&1; then
            sudo resolvectl flush-caches 2>/dev/null
        elif command -v systemd-resolve >/dev/null 2>&1; then
            sudo systemd-resolve --flush-caches 2>/dev/null
        elif [ -f /etc/init.d/nscd ]; then
            sudo /etc/init.d/nscd restart 2>/dev/null
        fi
    fi
}

get_current_dns_servers() {
    local os
    os=$(detect_os)
    local dns_list=()

    if [ "$os" == "macos" ]; then
        local service
        service=$(get_active_mac_service)
        local mac_dns
        mac_dns=$(networksetup -getdnsservers "$service" 2>/dev/null)
        if [[ "$mac_dns" =~ "There aren't any DNS Servers" || "$mac_dns" =~ "Error" || "$mac_dns" =~ "not a recognized" || -z "$mac_dns" ]]; then
            # Extract from scutil if not set in networksetup
            mac_dns=$(scutil --dns 2>/dev/null | awk '/nameserver\[[0-9]+\]/ {print $3}' | grep -v ':' | head -n2)
        fi
        for ip in $mac_dns; do
            if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                dns_list+=("$ip")
            fi
        done
    elif [ "$os" == "linux" ]; then
        if [ -f /etc/resolv.conf ]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ^nameserver[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
                    dns_list+=("${BASH_REMATCH[1]}")
                fi
            done < /etc/resolv.conf
        fi
    fi

    echo "${dns_list[*]}"
}

get_current_dns_info() {
    local current_servers
    current_servers=$(get_current_dns_servers)
    local ip1
    ip1=$(echo "$current_servers" | awk '{print $1}')
    local ip2
    ip2=$(echo "$current_servers" | awk '{print $2}')

    if [ -z "$ip1" ]; then
        echo "Default / Automatic (DHCP)"
        return
    fi

    # Check built-in DNS
    for entry in "${DNS_DATABASE[@]}"; do
        local name d1 d2
        name=$(echo "$entry" | cut -d'|' -f2)
        d1=$(echo "$entry" | cut -d'|' -f3)
        d2=$(echo "$entry" | cut -d'|' -f4)
        if [ "$ip1" == "$d1" ] || [ "$ip1" == "$d2" ]; then
            echo "$name ($ip1${ip2:+, $ip2})"
            return
        fi
    done

    # Check custom DNS
    if [ -f "$CUSTOM_DNS_FILE" ]; then
        while IFS='|' read -r c_key c_name c_d1 c_d2 c_cat c_desc; do
            if [ "$ip1" == "$c_d1" ] || [ "$ip1" == "$c_d2" ]; then
                echo "$c_name [Custom] ($ip1${ip2:+, $ip2})"
                return
            fi
        done < "$CUSTOM_DNS_FILE"
    fi

    echo "Custom / Unknown ($ip1${ip2:+, $ip2})"
}

# ==============================================================================
# Helper Functions: DNS Operations
# ==============================================================================

apply_dns() {
    local dns1="$1"
    local dns2="$2"
    local display_name="$3"
    local os
    os=$(detect_os)

    echo -e "${CYAN}Applying DNS:${NC} ${BOLD}$display_name${NC} ($dns1${dns2:+, $dns2})"

    if [ "$os" == "macos" ]; then
        local service
        service=$(get_active_mac_service)
        echo -e "${DIM}Configuring macOS Network Service:${NC} ${BOLD}$service${NC}"
        if [ -n "$dns2" ]; then
            sudo networksetup -setdnsservers "$service" "$dns1" "$dns2"
        else
            sudo networksetup -setdnsservers "$service" "$dns1"
        fi
    elif [ "$os" == "linux" ]; then
        local iface
        iface=$(get_active_linux_interface)
        
        # Check systemd-resolved (resolvectl / systemd-resolve)
        local resolved_applied=0
        if command -v resolvectl >/dev/null 2>&1 && [ -n "$iface" ]; then
            if [ -n "$dns2" ]; then
                sudo resolvectl dns "$iface" "$dns1" "$dns2" && resolved_applied=1
            else
                sudo resolvectl dns "$iface" "$dns1" && resolved_applied=1
            fi
        elif command -v systemd-resolve >/dev/null 2>&1 && [ -n "$iface" ]; then
            if [ -n "$dns2" ]; then
                sudo systemd-resolve -i "$iface" --set-dns="$dns1" --set-dns="$dns2" && resolved_applied=1
            else
                sudo systemd-resolve -i "$iface" --set-dns="$dns1" && resolved_applied=1
            fi
        fi

        # Fallback or additional update to /etc/resolv.conf
        {
            echo "# Generated by dns-switcher ($display_name)"
            echo "nameserver $dns1"
            [ -n "$dns2" ] && echo "nameserver $dns2"
        } | sudo tee /etc/resolv.conf > /dev/null
    else
        echo -e "${RED}Unsupported Operating System.${NC}"
        return 1
    fi

    flush_dns_cache
    echo -e "${GREEN}✓ DNS set to ${BOLD}$display_name${NC}${GREEN} successfully & cache flushed.${NC}"
}

clear_dns() {
    local os
    os=$(detect_os)
    echo -e "${YELLOW}Resetting DNS to default (DHCP / Automatic)...${NC}"

    if [ "$os" == "macos" ]; then
        local service
        service=$(get_active_mac_service)
        echo -e "${DIM}Resetting macOS Network Service:${NC} ${BOLD}$service${NC}"
        sudo networksetup -setdnsservers "$service" empty
    elif [ "$os" == "linux" ]; then
        local iface
        iface=$(get_active_linux_interface)
        if command -v resolvectl >/dev/null 2>&1 && [ -n "$iface" ]; then
            sudo resolvectl revert "$iface" 2>/dev/null
        elif command -v systemd-resolve >/dev/null 2>&1 && [ -n "$iface" ]; then
            sudo systemd-resolve --revert --interface="$iface" 2>/dev/null
        fi

        if [ -f /run/systemd/resolve/stub-resolv.conf ]; then
            sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        else
            echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
        fi
    fi

    flush_dns_cache
    echo -e "${GREEN}✓ DNS reset to default successfully.${NC}"
}

# ==============================================================================
# Helper Functions: Ping & Benchmark
# ==============================================================================

test_single_ping() {
    local ip="$1"
    local ping_time=""

    if [ -z "$ip" ]; then
        echo "N/A"
        return
    fi

    local os
    os=$(detect_os)

    if [ "$os" == "macos" ]; then
        ping_time=$(ping -c 1 -W 800 "$ip" 2>/dev/null | awk -F'/' '/avg/{print $5}')
        if [ -z "$ping_time" ]; then
            ping_time=$(ping -c 1 -t 1 "$ip" 2>/dev/null | awk -F'time=' '/time=/{print $2}' | awk '{print $1}')
        fi
    else
        ping_time=$(ping -c 1 -W 1 "$ip" 2>/dev/null | awk -F'/' '/rtt/{print $5}')
        if [ -z "$ping_time" ]; then
            ping_time=$(ping -c 1 -W 1 "$ip" 2>/dev/null | awk -F'time=' '/time=/{print $2}' | awk '{print $1}')
        fi
    fi

    if [ -n "$ping_time" ]; then
        local rounded
        rounded=$(printf "%.0f" "$ping_time" 2>/dev/null || echo "$ping_time")
        echo "${rounded}ms"
    else
        echo "timeout"
    fi
}

format_ping_badge() {
    local ping_val="$1"
    if [ "$ping_val" == "timeout" ] || [ "$ping_val" == "N/A" ] || [ -z "$ping_val" ]; then
        echo -e "${RED}[✗ Timeout]${NC}"
    else
        local num
        num=$(echo "$ping_val" | tr -dc '0-9')
        if [ -n "$num" ] && [ "$num" -le 40 ]; then
            echo -e "${GREEN}[● ${ping_val}]${NC}"
        elif [ -n "$num" ] && [ "$num" -le 100 ]; then
            echo -e "${YELLOW}[● ${ping_val}]${NC}"
        else
            echo -e "${RED}[● ${ping_val}]${NC}"
        fi
    fi
}

run_all_pings() {
    echo -e "\n${BOLD}${CYAN}=== Testing Latency to All DNS Providers ===${NC}\n"
    printf "%-25s %-16s %-16s %-12s\n" "Provider" "Primary IP" "Secondary IP" "Latency"
    echo "----------------------------------------------------------------------"

    for entry in "${DNS_DATABASE[@]}"; do
        local key name d1 d2 cat desc
        name=$(echo "$entry" | cut -d'|' -f2)
        d1=$(echo "$entry" | cut -d'|' -f3)
        d2=$(echo "$entry" | cut -d'|' -f4)
        
        local p
        p=$(test_single_ping "$d1")
        local badge
        badge=$(format_ping_badge "$p")
        printf "%-25s %-16s %-16s " "$name" "$d1" "$d2"
        echo -e "$badge"
    done

    if [ -s "$CUSTOM_DNS_FILE" ]; then
        echo "----------------------------------------------------------------------"
        echo -e "${MAGENTA}Custom DNS:${NC}"
        while IFS='|' read -r c_key c_name c_d1 c_d2 c_cat c_desc; do
            [ -z "$c_key" ] && continue
            local p
            p=$(test_single_ping "$c_d1")
            local badge
            badge=$(format_ping_badge "$p")
            printf "%-25s %-16s %-16s " "$c_name" "$c_d1" "$c_d2"
            echo -e "$badge"
        done < "$CUSTOM_DNS_FILE"
    fi
    echo ""
}

run_benchmark() {
    echo -e "\n${BOLD}${CYAN}=== Anti-Sanction & DNS Resolution Benchmark ===${NC}"
    echo -e "${DIM}Testing resolution for popular blocked/sanctioned domains...${NC}\n"

    local test_providers=(
        "shecan|Shecan|178.22.122.100"
        "403|403 Online|10.202.10.202"
        "electro|Electro|78.157.42.100"
        "radar|Radar Game|10.202.10.10"
        "begzar|Begzar|185.55.226.26"
        "shelter|Shelter|185.86.136.241"
        "cloudflare|Cloudflare|1.1.1.1"
        "google|Google|8.8.8.8"
    )

    for prov in "${test_providers[@]}"; do
        local p_name p_ip
        p_name=$(echo "$prov" | cut -d'|' -f2)
        p_ip=$(echo "$prov" | cut -d'|' -f3)

        echo -e "${BOLD}${BLUE}Testing Provider: $p_name ($p_ip)${NC}"
        local passed=0
        local total=0

        for target in "${BENCHMARK_DOMAINS[@]}"; do
            local domain label
            domain=$(echo "$target" | cut -d':' -f1)
            label=$(echo "$target" | cut -d':' -f2)
            ((total++))

            local res=""
            if command -v dig >/dev/null 2>&1; then
                res=$(dig +short +time=2 +tries=1 "@$p_ip" "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
            elif command -v nslookup >/dev/null 2>&1; then
                res=$(nslookup -timeout=2 "$domain" "$p_ip" 2>/dev/null | grep -A1 'Name:' | grep 'Address:' | awk '{print $2}' | head -n1)
            fi

            if [ -n "$res" ]; then
                ((passed++))
                printf "  %-20s %-28s %b\n" "$label" "($domain)" "${GREEN}✓ Resolved ($res)${NC}"
            else
                printf "  %-20s %-28s %b\n" "$label" "($domain)" "${RED}✗ Failed / Blocked${NC}"
            fi
        done

        local score_color="$GREEN"
        if [ "$passed" -lt "$total" ]; then score_color="$YELLOW"; fi
        if [ "$passed" -eq 0 ]; then score_color="$RED"; fi

        echo -e "  ${BOLD}Score:${NC} ${score_color}$passed/$total domains resolved${NC}\n"
    done
}

# ==============================================================================
# Helper Functions: Custom DNS Management
# ==============================================================================

add_custom_dns_dialog() {
    clear
    echo -e "${BOLD}${CYAN}=== Add Custom DNS ===${NC}\n"
    read -p "Enter DNS Name (e.g. My Company DNS): " c_name
    if [ -z "$c_name" ]; then
        echo -e "${RED}Name cannot be empty.${NC}"
        sleep 1
        return
    fi

    read -p "Enter Primary DNS IP: " c_d1
    if [[ ! "$c_d1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Invalid Primary IP format.${NC}"
        sleep 1.5
        return
    fi

    read -p "Enter Secondary DNS IP (optional): " c_d2
    if [ -n "$c_d2" ] && [[ ! "$c_d2" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Invalid Secondary IP format.${NC}"
        sleep 1.5
        return
    fi

    local c_key
    c_key=$(echo "$c_name" | tr '[:upper:]' '[:lower:]' | tr -dc 'a-z0-9_')
    [ -z "$c_key" ] && c_key="custom_$(date +%s)"

    echo "$c_key|$c_name|$c_d1|$c_d2|Custom|User custom DNS" >> "$CUSTOM_DNS_FILE"
    echo -e "\n${GREEN}✓ Custom DNS '$c_name' added successfully!${NC}"
    
    read -p "Apply this DNS now? (y/N): " apply_choice
    if [[ "$apply_choice" =~ ^[Yy]$ ]]; then
        apply_dns "$c_d1" "$c_d2" "$c_name"
        exit 0
    fi
}

delete_custom_dns_dialog() {
    clear
    echo -e "${BOLD}${CYAN}=== Remove Custom DNS ===${NC}\n"
    if [ ! -s "$CUSTOM_DNS_FILE" ]; then
        echo -e "${YELLOW}No custom DNS configurations found.${NC}"
        read -n1 -r -p "Press any key to return..."
        return
    fi

    local lines=()
    local i=1
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        lines+=("$line")
        local name d1
        name=$(echo "$line" | cut -d'|' -f2)
        d1=$(echo "$line" | cut -d'|' -f3)
        echo "  $i) $name ($d1)"
        ((i++))
    done < "$CUSTOM_DNS_FILE"

    echo ""
    read -p "Enter number to delete (or 0 to cancel): " del_num
    if [[ "$del_num" =~ ^[0-9]+$ ]] && [ "$del_num" -ge 1 ] && [ "$del_num" -le "${#lines[@]}" ]; then
        local idx=$((del_num - 1))
        local target="${lines[$idx]}"
        local t_name
        t_name=$(echo "$target" | cut -d'|' -f2)
        
        # Remove line from file
        local tmp_file
        tmp_file=$(mktemp)
        grep -vF "$target" "$CUSTOM_DNS_FILE" > "$tmp_file" && mv "$tmp_file" "$CUSTOM_DNS_FILE"
        echo -e "${GREEN}✓ Removed '$t_name'.${NC}"
    else
        echo "Cancelled."
    fi
    sleep 1.5
}

# ==============================================================================
# Helper Functions: CLI Commands
# ==============================================================================

find_and_set_by_name() {
    local query="$1"
    local l_query
    l_query=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    # 1. Check direct clear commands
    if [ "$l_query" == "clear" ] || [ "$l_query" == "default" ] || [ "$l_query" == "reset" ] || [ "$l_query" == "dhcp" ] || [ "$l_query" == "0" ]; then
        clear_dns
        return 0
    fi

    # 2. Check numeric index (1 to N)
    if [[ "$query" =~ ^[0-9]+$ ]] && [ "$query" -ge 1 ] && [ "$query" -le "${#DNS_DATABASE[@]}" ]; then
        local idx=$((query - 1))
        local entry="${DNS_DATABASE[$idx]}"
        local name d1 d2
        name=$(echo "$entry" | cut -d'|' -f2)
        d1=$(echo "$entry" | cut -d'|' -f3)
        d2=$(echo "$entry" | cut -d'|' -f4)
        apply_dns "$d1" "$d2" "$name"
        return 0
    fi

    # 3. Check built-in DNS by key or partial name
    for entry in "${DNS_DATABASE[@]}"; do
        local key name d1 d2
        key=$(echo "$entry" | cut -d'|' -f1)
        name=$(echo "$entry" | cut -d'|' -f2)
        d1=$(echo "$entry" | cut -d'|' -f3)
        d2=$(echo "$entry" | cut -d'|' -f4)

        if [[ "$key" == "$l_query" || $(echo "$name" | tr '[:upper:]' '[:lower:]') =~ "$l_query" ]]; then
            apply_dns "$d1" "$d2" "$name"
            return 0
        fi
    done

    # 4. Check custom DNS
    if [ -f "$CUSTOM_DNS_FILE" ]; then
        while IFS='|' read -r c_key c_name c_d1 c_d2 c_cat c_desc; do
            [ -z "$c_key" ] && continue
            if [[ "$c_key" == "$l_query" || $(echo "$c_name" | tr '[:upper:]' '[:lower:]') =~ "$l_query" ]]; then
                apply_dns "$c_d1" "$c_d2" "$c_name"
                return 0
            fi
        done < "$CUSTOM_DNS_FILE"
    fi

    # 5. Check if direct IP provided
    if [[ "$query" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        local ip2="$2"
        apply_dns "$query" "$ip2" "Custom ($query)"
        return 0
    fi

    echo -e "${RED}Error: DNS provider '$query' not found.${NC}"
    echo -e "Use ${CYAN}change-dns list${NC} to see available options."
    return 1
}

list_all_dns() {
    echo -e "\n${BOLD}${CYAN}=== Available DNS Profiles ===${NC}\n"
    
    local current_cat=""
    local idx=1
    for entry in "${DNS_DATABASE[@]}"; do
        local key name d1 d2 cat desc
        key=$(echo "$entry" | cut -d'|' -f1)
        name=$(echo "$entry" | cut -d'|' -f2)
        d1=$(echo "$entry" | cut -d'|' -f3)
        d2=$(echo "$entry" | cut -d'|' -f4)
        cat=$(echo "$entry" | cut -d'|' -f5)
        desc=$(echo "$entry" | cut -d'|' -f6)

        if [ "$cat" != "$current_cat" ]; then
            current_cat="$cat"
            echo -e "\n${BOLD}${MAGENTA}▶ $current_cat:${NC}"
        fi
        printf "  [%2d] ${CYAN}%-14s${NC} %-24s %-16s %-16s\n" "$idx" "$key" "$name" "$d1" "$d2"
        ((idx++))
    done

    if [ -s "$CUSTOM_DNS_FILE" ]; then
        echo -e "\n${BOLD}${MAGENTA}▶ Custom DNS Profiles:${NC}"
        while IFS='|' read -r c_key c_name c_d1 c_d2 c_cat c_desc; do
            [ -z "$c_key" ] && continue
            printf "  [%2d] %-14b %-25s %-16s %-16s\n" "$idx" "${CYAN}$c_key${NC}" "$c_name" "$c_d1" "$c_d2"
            ((idx++))
        done < "$CUSTOM_DNS_FILE"
    fi
    echo ""
}

show_status() {
    local os
    os=$(detect_os)
    echo -e "\n${BOLD}${CYAN}=== Current DNS Status ===${NC}"
    echo -e "  ${BOLD}Operating System:${NC}  $os"
    if [ "$os" == "macos" ]; then
        echo -e "  ${BOLD}Active Service:${NC}    $(get_active_mac_service)"
    else
        echo -e "  ${BOLD}Active Interface:${NC}  $(get_active_linux_interface)"
    fi
    echo -e "  ${BOLD}Current DNS:${NC}       ${GREEN}$(get_current_dns_info)${NC}\n"
}

show_help() {
    echo -e "
${BOLD}${CYAN}DNS Switcher v${VERSION}${NC} - Manage & Switch DNS Profiles with Ease

${BOLD}USAGE:${NC}
  change-dns                     Interactive TUI menu (with hotkeys [1]-[9], [p], [t], [0])
  change-dns <1-9|name>          Instant switch by number or name (e.g. change-dns 2, change-dns 403)
  change-dns set <name|ip> [ip2] Set DNS by name or IP directly
  change-dns clear | 0           Reset DNS to default (DHCP)
  change-dns status              Show current active DNS
  change-dns list                List all available DNS profiles
  change-dns ping                Test latency to all DNS providers
  change-dns test | benchmark    Run anti-sanction resolution test
  change-dns flush               Flush local DNS cache
  change-dns add <name> <ip>     Add a custom DNS profile
  change-dns remove <name>       Remove a custom DNS profile
  change-dns help | -h           Show this help message

${BOLD}EXAMPLES:${NC}
  change-dns 1                   # Switch to Shecan
  change-dns 2                   # Switch to 403 Online
  change-dns 3                   # Switch to Electro
  change-dns 0                   # Reset to default
  change-dns set cloudflare
  change-dns ping
"
}

# ==============================================================================
# Interactive TUI Menu
# ==============================================================================

interactive_menu() {
    # Build list of options
    local menu_items=()
    local menu_keys=()
    local menu_d1=()
    local menu_d2=()
    local menu_hotkeys=()

    local current_servers
    current_servers=$(get_current_dns_servers)
    local active_ip
    active_ip=$(echo "$current_servers" | awk '{print $1}')

    local num=1
    # Predefined
    for entry in "${DNS_DATABASE[@]}"; do
        local key name d1 d2 cat
        key=$(echo "$entry" | cut -d'|' -f1)
        name=$(echo "$entry" | cut -d'|' -f2)
        d1=$(echo "$entry" | cut -d'|' -f3)
        d2=$(echo "$entry" | cut -d'|' -f4)
        cat=$(echo "$entry" | cut -d'|' -f5)
        
        local active_tag=""
        if [ -n "$active_ip" ] && ([ "$active_ip" == "$d1" ] || [ "$active_ip" == "$d2" ]); then
            active_tag=" ${GREEN}${BOLD}[ACTIVE ✓]${NC}"
        fi

        menu_items+=("$(printf "[%2d] %-23s %-16s" "$num" "$name" "$d1")$active_tag")
        menu_keys+=("$key")
        menu_d1+=("$d1")
        menu_d2+=("$d2")
        menu_hotkeys+=("$num")
        ((num++))
    done

    # Custom
    if [ -f "$CUSTOM_DNS_FILE" ]; then
        while IFS='|' read -r c_key c_name c_d1 c_d2 c_cat c_desc; do
            [ -z "$c_key" ] && continue
            local active_tag=""
            if [ -n "$active_ip" ] && ([ "$active_ip" == "$c_d1" ] || [ "$active_ip" == "$c_d2" ]); then
                active_tag=" ${GREEN}${BOLD}[ACTIVE ✓]${NC}"
            fi
            menu_items+=("$(printf "[%2d] %-23s %-16s" "$num" "$c_name (Custom)" "$c_d1")$active_tag")
            menu_keys+=("$c_key")
            menu_d1+=("$c_d1")
            menu_d2+=("$c_d2")
            menu_hotkeys+=("$num")
            ((num++))
        done < "$CUSTOM_DNS_FILE"
    fi

    # Special Action Items
    local idx_default=${#menu_items[@]}
    menu_items+=("[ 0] Reset to Default (DHCP)")
    
    local idx_ping=${#menu_items[@]}
    menu_items+=("[ p] Test Latency (Ping all servers)")

    local idx_bench=${#menu_items[@]}
    menu_items+=("[ t] Anti-Sanction Resolution Benchmark")

    local idx_add_custom=${#menu_items[@]}
    menu_items+=("[ a] Add Custom DNS Profile")

    local idx_del_custom=${#menu_items[@]}
    menu_items+=("[ d] Remove Custom DNS Profile")

    local idx_flush=${#menu_items[@]}
    menu_items+=("[ f] Flush DNS Cache")

    local idx_about=${#menu_items[@]}
    menu_items+=("[ i] About DNS Switcher")

    local idx_exit=${#menu_items[@]}
    menu_items+=("[ q] Exit")

    local selected=0
    local total=${#menu_items[@]}

    # Hide cursor during menu navigation
    tput civis 2>/dev/null
    trap 'tput cnorm 2>/dev/null; exit 0' INT TERM

    draw_menu() {
        clear 2>/dev/null || printf "\033c"
        echo -e "${BOLD}${CYAN}===================================================================${NC}"
        echo -e "${BOLD}${CYAN}                    ⚡ DNS Switcher v${VERSION} ⚡                   ${NC}"
        echo -e "${BOLD}${CYAN}===================================================================${NC}"
        echo -e "Current Active DNS: ${GREEN}${BOLD}$(get_current_dns_info)${NC}"
        echo -e "${DIM}⚡ Quick Keys: Press [1]-[9], [0]=Reset, [p]=Ping, [t]=Test, [q]=Quit${NC}"
        echo -e "${DIM}   Or use [↑/↓]/[j/k] to navigate and [Enter] to select:${NC}\n"

        for i in "${!menu_items[@]}"; do
            if [ "$i" -eq "$selected" ]; then
                echo -e "  ${BOLD}${CYAN}➜ ${menu_items[$i]}${NC}"
            else
                echo -e "    ${menu_items[$i]}"
            fi
        done
        echo ""
    }

    while true; do
        draw_menu
        local action="none"
        
        # Read single key
        IFS= read -rsn1 key
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 1 rest
            case "$rest" in
                "[A"|"OA")
                    action="up"
                    ;;
                "[B"|"OB")
                    action="down"
                    ;;
                "[H"|"[1~")
                    selected=0
                    action="none"
                    ;;
                "[F"|"[4~")
                    selected=$((total - 1))
                    action="none"
                    ;;
                *)
                    action="none"
                    ;;
            esac
        elif [[ "$key" == "k" || "$key" == "K" || "$key" == "w" || "$key" == "W" ]]; then
            action="up"
        elif [[ "$key" == "j" || "$key" == "J" || "$key" == "s" || "$key" == "S" ]]; then
            action="down"
        elif [[ "$key" == "q" || "$key" == "Q" ]]; then
            action="quit"
        elif [[ "$key" == "0" || "$key" == "c" || "$key" == "C" ]]; then
            selected=$idx_default
            action="select"
        elif [[ "$key" == "p" || "$key" == "P" ]]; then
            selected=$idx_ping
            action="select"
        elif [[ "$key" == "t" || "$key" == "T" ]]; then
            selected=$idx_bench
            action="select"
        elif [[ "$key" == "a" || "$key" == "A" ]]; then
            selected=$idx_add_custom
            action="select"
        elif [[ "$key" == "d" || "$key" == "D" ]]; then
            selected=$idx_del_custom
            action="select"
        elif [[ "$key" == "f" || "$key" == "F" ]]; then
            selected=$idx_flush
            action="select"
        elif [[ "$key" == "i" || "$key" == "I" ]]; then
            selected=$idx_about
            action="select"
        elif [[ "$key" =~ ^[1-9]$ ]]; then
            local target_idx=$((key - 1))
            if [ "$target_idx" -lt "$idx_default" ]; then
                selected=$target_idx
                # Apply instantly on hotkey press
                action="select"
            fi
        elif [[ "$key" == "" ]]; then
            action="select"
        fi

        case "$action" in
            up)
                ((selected--))
                [ "$selected" -lt 0 ] && selected=$((total - 1))
                ;;
            down)
                ((selected++))
                [ "$selected" -ge "$total" ] && selected=0
                ;;
            quit)
                tput cnorm 2>/dev/null
                clear 2>/dev/null || true
                echo "Goodbye!"
                exit 0
                ;;
            select)
                tput cnorm 2>/dev/null
                if [ "$selected" -eq "$idx_default" ]; then
                    clear_dns
                    break
                elif [ "$selected" -eq "$idx_ping" ]; then
                    run_all_pings
                    read -n1 -r -p "Press any key to return to menu..."
                    tput civis 2>/dev/null
                elif [ "$selected" -eq "$idx_bench" ]; then
                    run_benchmark
                    read -n1 -r -p "Press any key to return to menu..."
                    tput civis 2>/dev/null
                elif [ "$selected" -eq "$idx_add_custom" ]; then
                    add_custom_dns_dialog
                    interactive_menu
                    return
                elif [ "$selected" -eq "$idx_del_custom" ]; then
                    delete_custom_dns_dialog
                    interactive_menu
                    return
                elif [ "$selected" -eq "$idx_flush" ]; then
                    flush_dns_cache
                    echo -e "\n${GREEN}✓ DNS Cache flushed successfully!${NC}"
                    sleep 1.5
                    tput civis 2>/dev/null
                elif [ "$selected" -eq "$idx_about" ]; then
                    clear 2>/dev/null || true
                    echo -e "${BOLD}${CYAN}About DNS Switcher${NC}"
                    echo -e "Version: ${BOLD}${VERSION}${NC}"
                    echo -e "Developer: MrMeshky (https://mrmeshky.ir)"
                    echo -e "GitHub: https://github.com/Mr-Meshky/dns-switcher"
                    echo -e "\nA tool to switch DNS on macOS and Linux effortlessly."
                    echo ""
                    read -n1 -r -p "Press any key to return..."
                    tput civis 2>/dev/null
                elif [ "$selected" -eq "$idx_exit" ]; then
                    clear 2>/dev/null || true
                    exit 0
                else
                    # Selected a DNS provider
                    local sel_name="${menu_keys[$selected]}"
                    local sel_d1="${menu_d1[$selected]}"
                    local sel_d2="${menu_d2[$selected]}"
                    apply_dns "$sel_d1" "$sel_d2" "$sel_name"
                    break
                fi
                ;;
        esac
    done
    tput cnorm 2>/dev/null
}

# ==============================================================================
# CLI Entrypoint Router
# ==============================================================================

main() {
    local cmd="$1"
    shift 2>/dev/null || true

    case "$cmd" in
        "")
            interactive_menu
            ;;
        set)
            if [ -z "$1" ]; then
                echo -e "${RED}Error: Please specify a DNS name or IP address.${NC}"
                echo "Usage: change-dns set <name|ip> [ip2]"
                exit 1
            fi
            find_and_set_by_name "$1" "$2"
            ;;
        clear|default|reset|dhcp)
            clear_dns
            ;;
        status)
            show_status
            ;;
        list)
            list_all_dns
            ;;
        ping|latency)
            run_all_pings
            ;;
        test|benchmark)
            run_benchmark
            ;;
        flush)
            flush_dns_cache
            echo -e "${GREEN}✓ DNS cache flushed.${NC}"
            ;;
        add)
            if [ -z "$1" ] || [ -z "$2" ]; then
                echo -e "${RED}Usage: change-dns add <name> <dns1> [dns2]${NC}"
                exit 1
            fi
            local a_name="$1"
            local a_d1="$2"
            local a_d2="$3"
            local a_key
            a_key=$(echo "$a_name" | tr '[:upper:]' '[:lower:]' | tr -dc 'a-z0-9_')
            echo "$a_key|$a_name|$a_d1|$a_d2|Custom|CLI added custom DNS" >> "$CUSTOM_DNS_FILE"
            echo -e "${GREEN}✓ Custom DNS '$a_name' added.${NC}"
            ;;
        remove|del)
            if [ -z "$1" ]; then
                echo -e "${RED}Usage: change-dns remove <name>${NC}"
                exit 1
            fi
            local r_query
            r_query=$(echo "$1" | tr '[:upper:]' '[:lower:]')
            local tmp_file
            tmp_file=$(mktemp)
            grep -vi "$r_query" "$CUSTOM_DNS_FILE" > "$tmp_file" && mv "$tmp_file" "$CUSTOM_DNS_FILE"
            echo -e "${GREEN}✓ Removed entries matching '$1'.${NC}"
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            # If the user directly entered e.g. "change-dns 403" or "change-dns shecan"
            find_and_set_by_name "$cmd" "$1"
            ;;
    esac
}

main "$@"