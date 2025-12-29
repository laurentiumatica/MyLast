#!/bin/bash
#mylast project
#autor:Bratan Alexandra-Maria
#descriere:am creat scheletul pentru fisierul-proiect 
echo "MyLast started!"
#extragem momentan doar timestamp-ul din fisier
parse() {
login_user=""
login_time=""
logout_time=""

    while read -r linie; do
        timestamp=$(awk '{print $1}' <<< "$linie")
#extragem si userul, adresam problema pe mai multe cazuri
        user=""
        action=""
        case "$linie" in
            *"session opened for user "*)
                user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); break}}' <<< "$linie")
                action="LOGIN"
                ;;
            *"session closed for user "*|*"Disconnected from user "*)
                user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") {print $(i+1); break}}' <<< "$linie")
                action="LOGOUT"
                ;;
            *"Accepted password for "*|*"Accepted publickey for "*)
                user=$(awk '{for(i=1;i<=NF;i++) if($i=="for") {print $(i+1); break}}' <<< "$linie")
                action="LOGIN"
                ;;
            *)
                continue
                ;;
        esac
        
       if [[ "$user" == *root* || "$user" == *gdm* ]]; then
          continue
       fi

       echo "timestamp=$timestamp user=$user action=$action"
        if [[ "$action" == "LOGIN" ]]; then
        login_user="$user"
        login_time="$timestamp"
        logout_time="still running"
    elif [[ "$action" == "LOGOUT" ]]; then
        if [[ "$login_user" == "$user" ]]; then
            logout_time="$timestamp"
            echo "User: $login_user, Login: $login_time, Logout: $logout_time"
      
            login_user=""
            login_time=""
            logout_time=""
        fi
    fi
 done < "$1"

  if [[ -n "$login_user" ]]; then
        echo "User: $login_user, Login: $login_time, Logout: $logout_time"
    fi
}


parse "$1"

