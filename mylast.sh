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
        
        if [[ "$line" =~ "Accepted" ]]; then
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="for") {print $(i+1); exit}}' <<< "$line")
            ip=$(awk '{for(i=1;i<=NF;i++) if($i=="from") {print $(i+1); exit}}' <<< "$line")
            echo "$timestamp|$user|ACCEPTED|$ip|$pid"
        elif [[ "$line" =~ "session opened" ]]; then
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); exit}}' <<< "$line")
            ip=$(awk '{for(i=1;i<=NF;i++) if($i=="from") {print $(i+1); exit}}' <<< "$line")
            echo "$timestamp|$user|LOGIN|$ip|$pid"
        elif [[ "$line" =~ "session closed"|"Disconnected from" ]]; then
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); exit}}' <<< "$line")
            echo "$timestamp|$user|LOGOUT||$pid"
        fi
    done < "$1"
}

format() {
    local datetime=$(echo "$1" | sed 's/\([0-9T:.-]\+\).*/\1/')
    local date=$(echo "$datetime" | cut -d'T' -f1)
    local time=$(echo "$datetime" | cut -d'T' -f2 | cut -d'.' -f1)
    [[ "$2" == "full" ]] && { date -d "$date $time" "+%a %b %_d %H:%M" 2>/dev/null || echo "???"; } || { echo "$time" | cut -d':' -f1,2; }
}

duration() {
    local sepoch=$(date -d "$1" +%s 2>/dev/null)
    local eepoch=$(date -d "$2" +%s 2>/dev/null)
    [[ -z "$sepoch" || -z "$eepoch" ]] && echo "(??:??)" && return
    
    local duration=$((eepoch - sepoch))
    local days=$((duration / 86400))
    local hours=$(((duration % 86400) / 3600))
    local minutes=$(((duration % 3600) / 60))
    
    [[ $days -gt 0 ]] && { printf "(%d+%02d:%02d)" "$days" "$hours" "$minutes"; } || { printf "(%02d:%02d)" "$hours" "$minutes"; }
}

print() {
    local startf=$(format "$4" "full")
    [[ "$6" == "yes" ]] && { printf "%-8.8s %-12.12s %-16.16s %-16s   still logged in\n" "$1" "$2" "$3" "$startf"; } || { local endf=$(format "$5" "short"); local duration=$(duration "$4" "$5"); printf "%-8.8s %-12.12s %-16.16s %-16s - %-5.5s  %s\n" "$1" "$2" "$3" "$startf" "$endf" "$duration"; }
}

process() {
    declare -A sessions accepted cnt
    local timestamp user action ip pid completed="" sepoch eepoch show active=""
    
    while IFS='|' read -r timestamp user action ip pid; do
        [[ -z "$pid" ]] && continue
        
        case "$action" in
            ACCEPTED)
                accepted["${pid}_acc"]="$timestamp|$user|$ip"
                ;;
            LOGIN)
                [[ -n "${accepted[${pid}_acc]}" ]] && { IFS='|' read -r timestamp user ip <<< "${accepted[${pid}_acc]}"; unset 'accepted[${pid}_acc]'; }
                [[ -z "${cnt[$user]}" ]] && cnt["$user"]=0
                
                local tty="pts/${cnt[$user]}"
                cnt["$user"]=$((cnt[$user] + 1))
                sessions["$pid"]="$timestamp|$user|$ip|$tty"
                ;;
            LOGOUT)
                if [[ -n "${sessions[$pid]}" ]]; then
                    local timestamp_out
                    IFS='|' read -r timestamp_out user ip tty <<< "${sessions[$pid]}"
                    sepoch=$(date -d "$timestamp_out" +%s 2>/dev/null)
                    eepoch=$(date -d "$timestamp" +%s 2>/dev/null)
                    show=1
                    
                    [[ $sepoch -lt $SINCE ]] && show=0
                    [[ $sepoch -gt $UNTIL ]] && show=0
                    [[ -n "$PRESENT" ]] && (( sepoch <= PRESENT && eepoch >= PRESENT ? (show=1) : (show=0) ))
                    [[ $show -eq 1 ]] && { completed+="$timestamp_out|$user|$tty|$ip|$timestamp|no"$'\n'; }
                    
                    unset 'sessions[$pid]'
                fi
                ;;
        esac
    done < <(parse "$1")
    
    for pid in "${!sessions[@]}"; do
        [[ "$pid" == *"_acc" ]] && continue
        IFS='|' read -r timestamp user ip tty <<< "${sessions[$pid]}"
        sepoch=$(date -d "$timestamp" +%s 2>/dev/null)
        show=1

        [[ $sepoch -lt $SINCE ]] && show=0
        [[ $sepoch -gt $UNTIL ]] && show=0
        [[ -n "$PRESENT" ]] && (( sepoch <= PRESENT && PRESENT <= $(date +%s) ? (show=1) : (show=0) ))
        [[ $show -eq 1 ]] && { active+="$timestamp|$user|$tty|$ip||yes"$'\n'; }
    done
    
    local all_sessions="${completed}${active}"
    
    if [[ -z "$all_sessions" ]]; then
        echo "Nothing to be printed..."
    else
        local limit="cat"
        [[ $NUM -ne -1 ]] && limit="head -n $NUM"
        
        echo "$all_sessions" | sort -t'|' -k1 -r | $limit | while IFS='|' read -r timestamp user tty ip end_time is_active; do
            [[ -z "$timestamp" ]] && continue
            [[ "$is_active" == "yes" ]] && { print "$user" "$tty" "$ip" "$timestamp" "" "yes"; } || { print "$user" "$tty" "$ip" "$timestamp" "$end_time" "no"; }
        done
    fi
    
    echo ""
    timestamp=$(head -1 "$1" | awk '{print $1}')
    [[ -n "$timestamp" ]] && { echo "wtmp begins $(format "$timestamp" "full")"; }
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
