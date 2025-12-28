#!/bin/bash

rosu='\033[0;31m'
rosu_bold='\033[1;31m'
verde='\033[0;32m'
verde_bold='\033[1;32m'
albastru='\033[0;34m'
albastru_bold='\033[1;34m'
nc='\033[0m'
bold='\033[1m'

echo -e "${albastru_bold}__MyLast started!__${nc}"
echo ""

parse() {
    local fisier="$1"
    
    while read -r linie; do
        
        timestamp=$(echo "$linie" | awk '{print $1}')
        user=""
        action=""
        ip=""
        pid=""

        pid=$(echo "$linie" | grep -oP 'sshd\[\K[0-9]+')
        ip=$(echo "$linie" | awk '{
            for(i=1; i<=NF; i++){
                if($i=="from") print $(i+1)
            }
        }')

        case "$linie" in
            *"session opened"*)
                user=$(awk '{
                    for(i=1; i<=NF; i++) {
                        if($i=="user") print $(i+1)
                    }
                }' <<< "$linie")
                action="LOGIN"
                ;;
            *"session closed"*)
                user=$(awk '{
                    for(i=1; i<=NF; i++) {
                        if($i=="user") print $(i+1)
                    }
                }' <<< "$linie")
                action="LOGOUT"
                ;;
            *"Accepted"*)
                user=$(awk '{
                    for(i=1; i<=NF; i++) {
                        if($i=="for") print $(i+1)
                    }
                }' <<< "$linie")
                action="LOGIN"
                ;;
            *"Failed"*)
                user=$(awk '{
                    for(i=1; i<=NF; i++) {
                        if($i=="for") print $(i+1)
                    }
                }' <<< "$linie")
                action="FAILED"
                ;;
            *"Disconnected from"*)
                user=$(awk '{
                    for(i=1; i<=NF; i++) {
                        if($i=="user") print $(i+1)
                    }
                }' <<< "$linie")
                action="LOGOUT"
                ;;
            
        esac

        if [[ -n "$user" && -n "$action" ]]; then
            echo "$timestamp|$user|$action|$ip|$pid"
        fi

    done < "$fisier"
}

formatare_timestamp(){
    local timestamp="$1"
    date -d "$timestamp" "+%a %b %_d %H:%M" 2>/dev/null || echo "???"
}

formatare_timp_final_sesiune()
{
    local timestamp="$1"
    date -d "$timestamp" "+%H:%M" 2>/dev/null || echo "???"
}

durata_sesiune(){
    local start_timestamp="$1"
    local stop_timestamp="$2"
    local start_epoch=$(date -d "$start_timestamp" +%s 2>/dev/null)
    local stop_epoch=$(date -d "$stop_timestamp" +%s 2>/dev/null)

    if [[ -z "$start_epoch" || -z "$stop_epoch" ]]; then
        echo "(??:??)"
        return
    fi

    local durata=$((stop_epoch - start_epoch))
    local zile=$((durata / 86400))
    local ore=$(((durata%86400)/3600))
    local minute=$(((durata%3600)/60))

    if [[ $zile -gt 0 ]]; then
        printf "(%d+%02d:%02d)" "$zile" "$ore" "$minute"
    else
        printf "(%02d:%02d)" "$ore" "$minute"
    fi
}

formatare_info_sesiune(){
    local user="$1"
    local tty="$2"
    local ip="$3"
    local start_timestamp="$4"
    local stop_timestamp="$5"
    local logged_in="$6"
    local start_formatat=$(formatare_timestamp "$start_timestamp")

    if [[ "$logged_in" == "yes" ]]; then
        printf "%-8.8s %-12.12s %-16.16s %-16s   still logged in\n" "$user" "$tty" "$ip" "$start_formatat"
    else
        local stop_formatat=$(formatare_timp_final_sesiune "$stop_timestamp")
        local durata=$(durata_sesiune "$start_timestamp" "$stop_timestamp")
        printf "%-8.8s %-12.12s %-16.16s %-16s - %-5.5s  %s\n" "$user" "$tty" "$ip" "$start_formatat" "$stop_formatat" "$durata"
    fi
}

print(){
    local fisier="$1"
    declare -A sesiuni_active
    local contor_tty=0

    while IFS='|' read -r action_timestamp user action ip pid; do
        case "$action" in
        LOGIN)
            if [[ -z "${sesiuni_active[$pid]}" ]]; then
                local tty="pts/$contor_tty"
                contor_tty=$((contor_tty+1))
                sesiuni_active["$pid"]="$action_timestamp|$user|$ip|$tty"
            fi
            ;;

        LOGOUT)
            if [[ -n "${sesiuni_active[$pid]}" ]]; then
                IFS='|' read -r login_timestamp login_user login_ip login_tty <<< "${sesiuni_active[$pid]}"
                formatare_info_sesiune "$login_user" "$login_tty" "$login_ip" "$login_timestamp" "$action_timestamp" "no"
                unset sesiuni_active["$pid"]
            fi
            ;;

        esac
    done < <(parse "$fisier")

    for pid in "${!sesiuni_active[@]}"; do    
        IFS='|' read -r login_timestamp login_user login_ip login_tty <<< "${sesiuni_active[$pid]}"
        formatare_info_sesiune "$login_user" "$login_tty" "$login_ip" "$action_timestamp" "" "yes"
    done

    echo ""
    local prima_linie=$(head -1 "$fisier")
    local primul_timestamp=$(echo "$prima_linie" | awk '{print $1}')
    local primul_formatat=$(formatare_timestamp "$primul_timestamp")
    echo "wtmp begins $primul_formatat"
    echo ""
}

print tests/auth.log.sample