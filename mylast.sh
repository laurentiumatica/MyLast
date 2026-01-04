#!/bin/bash

BOLD_BLUE="\033[1;34m"
BOLD_RED="\033[1;31m"
NC="\033[0m"
SINCE=0
UNTIL=9999999999
PRESENT=""

while getopts "s:t:p:" opt; do
  case $opt in
    s) 
      SINCE=$(date -d "$OPTARG" +%s 2>/dev/null)
      if [[ -z "$SINCE" ]]; then echo -e "${BOLD_RED}Invalid date format for -s: $SINCE${NC}"; exit 1; fi
      ;;
    t) 
      UNTIL=$(date -d "$OPTARG" +%s 2>/dev/null)
      if [[ -z "$UNTIL" ]]; then echo -e "${BOLD_RED}Invalid date format for -t: $UNTIL${NC}"; exit 1; fi
      ;;
    p) 
      PRESENT=$(date -d "$OPTARG" +%s 2>/dev/null)
      if [[ -z "$PRESENT" ]]; then echo -e "${BOLD_RED}Invalid date format for -p: $PRESENT${NC}"; exit 1; fi
      ;;
    *) echo "Usage: $0 [-s since_date] [-t until_date] [-p at_date]"; exit 1 ;;
  esac
done
shift $((OPTIND-1))
parse() {
    local file="$1"
    local pid timestamp ip user
    
    while read -r line; do
        [[ ! "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]] && continue
        [[ ! "$line" =~ sshd\[ ]] && continue
        
        if [[ "$line" =~ \[([0-9]+)\] ]]; then
            pid="${BASH_REMATCH[1]}"
        else
            continue
        fi
        
        timestamp=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="from") {print $(i+1); exit}}')
        
        if [[ "$line" =~ "Accepted" ]]; then
            user=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="for") {print $(i+1); exit}}')
            echo "$timestamp|$user|ACCEPTED|$ip|$pid"
        elif [[ "$line" =~ "session opened" ]]; then
            user=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); exit}}')
            echo "$timestamp|$user|LOGIN|$ip|$pid"
        elif [[ "$line" =~ "session closed"|"Disconnected from" ]]; then
            user=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); exit}}')
            echo "$timestamp|$user|LOGOUT|$ip|$pid"
        fi
    done < "$file"
}

format() {
    local timestamp="$1"
    local type="$2"
    local datetime=$(echo "$timestamp" | sed 's/\([0-9T:.-]\+\).*/\1/')
    local date=$(echo "$datetime" | cut -d'T' -f1)
    local time=$(echo "$datetime" | cut -d'T' -f2 | cut -d'.' -f1)
    
    if [[ "$type" == "full" ]]; then
        date -d "$date $time" "+%a %b %_d %H:%M" 2>/dev/null || echo "???"
    else
        echo "$time" | cut -d':' -f1,2
    fi
}

duration() {
    local start="$1"
    local end="$2"
    local sepoch=$(date -d "$start" +%s 2>/dev/null)
    local eepoch=$(date -d "$end" +%s 2>/dev/null)
    
    [[ -z "$sepoch" || -z "$eepoch" ]] && echo "(??:??)" && return
    
    local duration=$((eepoch - sepoch))
    local days=$((duration / 86400))
    local hours=$(((duration % 86400) / 3600))
    local minutes=$(((duration % 3600) / 60))
    
    if [[ $days -gt 0 ]]; then
        printf "(%d+%02d:%02d)" "$days" "$hours" "$minutes"
    else
        printf "(%02d:%02d)" "$hours" "$minutes"
    fi
}

print() {
    local user="$1"
    local tty="$2"
    local ip="$3"
    local start="$4"
    local end="$5"
    local active="$6"
    
    local startf=$(format "$start" "full")
    
    if [[ "$active" == "yes" ]]; then
        printf "%-8.8s %-12.12s %-16.16s %-16s   still logged in\n" "$user" "$tty" "$ip" "$startf"
    else
        local endf=$(format "$end" "short")
        local duration=$(duration "$start" "$end")
        
        printf "%-8.8s %-12.12s %-16.16s %-16s - %-5.5s  %s\n" "$user" "$tty" "$ip" "$startf" "$endf" "$duration"
    fi
}

process() {
    local file="$1"
    declare -A sessions accepted cnt
    local timestamp user action ip pid
    local check=0
    
    while IFS='|' read -r timestamp user action ip pid; do
        [[ -z "$pid" ]] && continue
        
        case "$action" in
            ACCEPTED)
                accepted["${pid}_acc"]="$timestamp|$user|$ip"
                ;;
            LOGIN)
                if [[ -n "${accepted[${pid}_acc]}" ]]; then
                    local timestamp_acc user_acc ip_acc
                    IFS='|' read -r timestamp_acc user_acc ip_acc <<< "${accepted[${pid}_acc]}"
                    user="$user_acc"
                    ip="$ip_acc"
                    timestamp="$timestamp_acc"
                    unset 'accepted[${pid}_acc]'
                fi
                [[ -z "${cnt[$user]}" ]] && cnt["$user"]=0
                local tty="pts/${cnt[$user]}"
                cnt["$user"]=$((cnt[$user] + 1))
                sessions["$pid"]="$timestamp|$user|$ip|$tty"
                ;;
            LOGOUT)
                if [[ -n "${sessions[$pid]}" ]]; then
                    local timestamp_out user_out ip_out tty_out
                  s_epoch=$(date -d "$t_start" +%s 2>/dev/null)
                  e_epoch=$(date -d "$timestamp" +%s 2>/dev/null)

                   show=1
                 [[ $s_epoch -lt $SINCE ]] && show=0
                 [[ $s_epoch -gt $UNTIL ]] && show=0
                 if [[ -n "$PRESENT" ]]; then
                    if (( s_epoch <= PRESENT && e_epoch >= PRESENT )); then
                    show=1
else
                    show=0
                    fi
                 fi                   
                    IFS='|' read -r timestamp_out user_out ip_out tty_out <<< "${sessions[$pid]}"
                   [[ $show -eq 1 ]] && print "$user_out" "$tty_out" "$ip_out" "$timestamp_out" "$timestamp" "no"
                    unset 'sessions[$pid]'
                    check=1
                fi
                ;;
        esac
    done < <(parse "$file")
    
    local active=""
    for pid in "${!sessions[@]}"; do
        [[ "$pid" == *"_acc" ]] && continue
        active+="${sessions[$pid]}"$'\n'
    done
    
    if [[ -z "$active" && "$check" -eq 0 ]]; then
        echo "Nothing to be printed..."
    else
        echo "$active" | sort -t'|' -k1 | while IFS='|' read -r timestamp user ip tty; do
            [[ -z "$timestamp" ]] && continue
            s_epoch=$(date -d "$t_start" +%s 2>/dev/null)
            now=$(date +%s)
            show=1
    
            [[ $s_epoch -lt $SINCE ]] && show=0
            [[ $s_epoch -gt $UNTIL ]] && show=0
    
            if [[ -n "$PRESENT" ]]; then
                if (( s_epoch <= PRESENT && PRESENT <= now )); then
                    show=1
                else
                    show=0
                fi
            fi        
            [[ $show -eq 1 ]] && print "$user" "$tty" "$ip" "$timestamp" "" "yes"
        done
    fi
    
    echo ""
    local timestamp1=$(head -1 "$file" | awk '{print $1}')
    if [[ -n "$timestamp1" ]]; then
        echo "wtmp begins $(format "$timestamp1" "full")"
    fi
    echo ""
}

files=()

for pattern in "/var/log/auth.log" "/var/log/auth.log."{1,2,3,4}{,.gz}; do
    if [[ -f "$pattern" ]]; then
        files+=("$pattern")
    fi
done

if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${BOLD_RED}No auth.log files found in /var/log/${NC}"
    exit 1
fi

for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo -e "${BOLD_RED}File '$file' not found${NC}"
        exit 1
    fi
    
    if [[ "$file" == *.gz ]]; then
        temp=$(mktemp)
        if ! gunzip -c "$file" > "$temp" 2>/dev/null; then
            echo -e "${BOLD_RED}Failed to decompress $file${NC}"
            rm -f "$temp"
            exit 1
        fi
        echo -e "${BOLD_BLUE}For file $file${NC}"
        echo ""
        process "$temp"
        rm -f "$temp"
    else
        echo -e "${BOLD_BLUE}For file $file${NC}"
        echo ""
        process "$file"
    fi
done
