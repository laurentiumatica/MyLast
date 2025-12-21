#!/bin/bash
#mylast project
#autor:Bratan Alexandra-Maria
#descriere:am creat scheletul pentru fisierul-proiect 
echo "MyLast started!"
#extragem momentan doar timestamp-ul din fisier
parse() {
    while read -r linie; do
        timestamp=$(echo "$linie" | awk '{print $1}')
        echo "$timestamp"
    done < "$1"
}
parse /var/log/auth.log
