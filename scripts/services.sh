#!/bin/bash                                                                                  
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

function main_menu() {
    dialog --clear --backtitle "Exiro Management Tools" \
    --title "[ SERVICES ]" \
    --cancel-label "Return"  \
    --menu "" 20 60 40 \
Http "Restart http services" \
Mail "Restart mail services" \
Dns "Restart dns services" 2>"${INPUT}"

menuitem=$(<"${INPUT}")
retval=$?
case $retval in
0)

case $menuitem in
    Http) service_restart http;;
    Mail) service_restart mail;;
    Dns) service_restart dns;;
esac;;   
1)
        source /opt/EMT/EMT.sh
        break;;
esac 
}
function wait_for()
{
    pid=$1
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
       i=$(( (i+1) %4 ))
       printf "\r${spin:$i:1}"
       sleep .1
    done
}

function service_restart() {
service=$1
if [ "$1" == "http" ]                                                                        
then
systemctl restart apache2 2>/dev/null &
pid=$!
wait_for $pid
log=$(journalctl --no-pager -r -u apache2 > /tmp/journallog.$$)
dialog --backtitle "Exiro Management Tools" --title "[ SERVICES: $1 - RESTART ]" \
       --textbox /tmp/journallog.$$ 30 100 2>"${INPUT}"
rm /tmp/journallog.$$
retval=$?
case $retval in
    0)
      main_menu
esac

elif [ "$1" == "mail" ]
then
systemctl restart postfix 2>/dev/null &
pid=$!
wait_for $pid
log=$(journalctl --no-pager -r -u postfix > /tmp/journallog.$$)
dialog --backtitle "Exiro Management Tools" --title "[ SERVICES: $1 - RESTART ]" \
       --textbox /tmp/journallog.$$ 30 100 2>"${INPUT}"
rm /tmp/journallog.$$
retval=$?
case $retval in
    0)
systemctl restart dovecot 2>/dev/null &
pid=$!
wait_for $pid
log=$(journalctl --no-pager -r -u dovecot > /tmp/journallog.$$)
dialog --backtitle "Exiro Management Tools" --title "[ SERVICES: $1 - RESTART ]" \
       --textbox /tmp/journallog.$$ 30 100 2>"${INPUT}"
retval=$?
case $retval in
    0) main_menu;;
esac;;
esac

elif [ "$1" == "dns" ]
then 
systemctl restart bind9 2>/dev/null &
pid=$!
wait_for $pid
log=$(journalctl --no-pager -r -u bind9 > /tmp/journallog.$$)
dialog --backtitle "Exiro Management Tools" --title "[ SERVICES: $1 - RESTART ]" \
       --textbox /tmp/journallog.$$ 30 100 2>"${INPUT}"
rm /tmp/journallog.$$
retval=$?
case $retval in
    0)
      main_menu
esac

else 
dialog --backtitle "Exiro Management Tools" --title "[ SERVICES - NONE SELECTED ]" \
       --msgbox  "doing nothing" 10 50 2>"${INPUT}"                            
fi


}
main_menu
