#!/bin/bash
#mylast project
#autor:Bratan Alexandra-Maria
#descriere:am creat scheletul pentru fisierul-proiect 
echo "MyLast started!"
#extragem momentan doar timestamp-ul din fisier
parse() {
    while read -r linie; do
        timestamp=$(echo "$linie" | awk '{print $1}')
#extragem si userul, adresam problema pe mai multe cazuri
     user=""
     action=""
case "$linie" in
*"session opened"*)
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") print $(i+1)}' <<< "$linie")
            action="LOGIN"
	    ;;
        *"session closed"*)
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") print $(i+1)}' <<< "$linie")
            action="LOGOUT"
            ;;
        *"Accepted"*)
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="for") print $(i+1)}' <<< "$linie")
            action="LOGIN"
            ;;
        *"Failed"*)
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="for") print $(i+1)}' <<< "$linie")
            ;;
        *"Disconnected from"*)
            user=$(awk '{for(i=1;i<=NF;i++) if($i=="user") print $(i+1)}' <<< "$linie")
            action="LOGOUT"
            ;;
    esac

   echo "timestamp=$timestamp user=$user action=$action"
    done < "$1"
}
parse tests/auth.log.sample
