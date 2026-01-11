#!/bin/bash

BOLD_BLUE="\033[1;34m"
BOLD_RED="\033[1;31m"
NC="\033[0m"
SINCE=0
UNTIL=9999999999
PRESENT=""
NUM=-1
files=()

while getopts "s:t:p:n:" opt; do
  case $opt in
    s) SINCE=$(date -d "$OPTARG" +%s 2>/dev/null) || { echo -e "${BOLD_RED}Invalid date: $OPTARG${NC}"; exit 1; } ;;
    t) UNTIL=$(date -d "$OPTARG" +%s 2>/dev/null) || { echo -e "${BOLD_RED}Invalid date: $OPTARG${NC}"; exit 1; } ;;
    p) PRESENT=$(date -d "$OPTARG" +%s 2>/dev/null) || { echo -e "${BOLD_RED}Invalid date: $OPTARG${NC}"; exit 1; } ;;
    n) NUM="$OPTARG"; [[ ! "$NUM" =~ ^[0-9]+$ || "$NUM" -eq 0 ]] && { echo -e "${BOLD_RED}Invalid number${NC}"; exit 1; } ;;
    *) echo "Usage: $0 [-s since_date] [-t until_date] [-p at_date] [-n num_sessions] [file]"; exit 1 ;;
  esac
done
shift $((OPTIND-1))

parse() {
    local pid timestamp ip user
    while read -r line; do
        [[ ! "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T.*sshd\[([0-9]+)\] ]] && continue
        pid="${BASH_REMATCH[1]}"
        timestamp=$(awk '{print $1}' <<< "$line")
        
        if [[ "$line" =~ "Failed password" ]]; then
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="for") {print $(i+1); exit}}' <<< "$line")
            [[ "$user" == "invalid" ]] && user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); exit}}' <<< "$line")
            ip=$(awk '{for(i=1;i<=NF;i++) if($i=="from") {print $(i+1); exit}}' <<< "$line")
            echo "$timestamp|$user|FAILED|$ip|$pid"
        elif [[ "$line" =~ [Ii]"nvalid user" ]]; then
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); exit}}' <<< "$line")
            [[ "$line" =~ "Disconnected from" ]] && ip=$(awk '{for(i=1;i<=NF;i++) if($i=="user" && $(i+2)=="from") {print $(i+3); exit}}' <<< "$line") || ip=$(awk '{for(i=1;i<=NF;i++) if($i=="from") {print $(i+1); exit}}' <<< "$line")
            echo "$timestamp|$user|FAILED|$ip|$pid"
        elif [[ "$line" =~ "authentication failure" ]]; then
            user=$(echo "$line" | grep -oP 'user=\K[^ ]+' || echo "unknown")
            [[ "$user" == "unknown" || -z "$user" ]] && user="unknown"
            ip=$(echo "$line" | grep -oP 'rhost=\K[^ ]+' || echo "unknown")
            [[ "$ip" == "unknown" || -z "$ip" ]] && ip="unknown"
            echo "$timestamp|$user|FAILED|$ip|$pid"
        fi
    done < "$1"
}

format() {
    local datetime=$(echo "$1" | sed 's/\([0-9T:.-]\+\).*/\1/')
    local date=$(echo "$datetime" | cut -d'T' -f1)
    local time=$(echo "$datetime" | cut -d'T' -f2 | cut -d'.' -f1)
    
    [[ "$2" == "full" ]] && { date -d "$date $time" "+%a %b %_d %H:%M" 2>/dev/null || echo "???"; } || { echo "$time" | cut -d':' -f1,2; }
}

process() {
    declare -A failed
    local timestamp user action ip pid sepoch show all_failed=""
    
    while IFS='|' read -r timestamp user action ip pid; do
        [[ -z "$pid" || "$action" != "FAILED" ]] && continue
        
        sepoch=$(date -d "$timestamp" +%s 2>/dev/null)
        show=1
        
        [[ $sepoch -lt $SINCE ]] && show=0
        [[ $sepoch -gt $UNTIL ]] && show=0
        [[ -n "$PRESENT" ]] && (( sepoch <= PRESENT ? (show=1) : (show=0) ))
        [[ $show -eq 1 ]] && { local tty="ssh:notty"; failed["${pid}_${timestamp}"]="$timestamp|$user|$tty|$ip"; }
    done < <(parse "$1")
    
    for key in "${!failed[@]}"; do
        all_failed+="${failed[$key]}"$'\n'
    done
    
    if [[ -z "$all_failed" ]]; then
        echo "Nothing to be printed..."
    else
        local limit="cat"
        [[ $NUM -ne -1 ]] && limit="head -n $NUM"
        
        echo "$all_failed" | sort -t'|' -k1 -r | $limit | while IFS='|' read -r timestamp user tty ip; do
            [[ -z "$timestamp" ]] && continue
            local startf=$(format "$timestamp" "full")
            local endf=$(format "$timestamp" "short")
            printf "%-8.8s %-12.12s %-16.16s %-16s - %-5.5s  (00:00)\n" "$user" "$tty" "$ip" "$startf" "$endf"
        done
    fi
    
    echo ""
    timestamp=$(head -1 "$1" | awk '{print $1}')
    [[ -n "$timestamp" ]] && { echo "btmp begins $(format "$timestamp" "full")"; }
    echo ""
}

if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        [[ -f "$arg" ]] && { files+=("$arg"); } || { echo -e "${BOLD_RED}File '$arg' not found${NC}"; exit 1; }
    done
else
    for pattern in "/var/log/auth.log" "/var/log/auth.log."{1,2,3,4}{,.gz}; do
        [[ -f "$pattern" ]] && { files+=("$pattern"); }
    done
    
    [[ ${#files[@]} -eq 0 ]] && { echo -e "${BOLD_RED}No auth.log files found in /var/log/${NC}"; exit 1; }
fi

for file in "${files[@]}"; do
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
