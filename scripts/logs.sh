#!/bin/bash
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

function log_selection() {
    dialog --clear --backtitle "Exiro Management Tools" \
    --title "[ LOGS ]" \
    --cancel-label "Return"  \
    --menu "" 20 60 40 \
Apache "View apache logs" \
Mail "View mail logs" \
Journal "View journal" 2>"${INPUT}"

menuitem=$(<"${INPUT}")
retval=$?
case $retval in
0)

case $menuitem in
    Apache) menu_http;;
    Mail) menu_mail;;
    Journal) menu_journal;;
esac;;
1)
         break;;
255)
         exit;;
esac
}

function menu_http() {
ldir='/var/www/logs/'
listthis=$(ls -1 $ldir)

OLDIFS="$IFS"
IFS='\n'
show=''
readarray -t items <<<"$listthis"
for element in "${items[@]}"
do
    show="$show $element $element"
done
    IFS="$OLDIFS"
    dialog --clear \
        --backtitle "Exiro Management Tools" \
        --title "[ LOGS - APACHE ]" \
        --cancel-label "Return" \
        --menu "" 20 60 40 \
        $show 2>"${INPUT}"
    lname=$(<"${INPUT}")
    retval=$?
    case $retval in
        0) show_log $ldir $lname;;
    esac

}

function menu_mail() {
    dialog --clear \
        --backtitle "Exiro Management Tools" \
        --title "[ LOGS - MAIL ]" \
        --cancel-label "Return" \
        --menu "" 20 60 40 \
        "mail.log" "mail.log" \
		"mail.err" "mail.err" 2>"${INPUT}"
    lname=$(<"${INPUT}")
    retval=$?
    case $retval in
        0) show_log '/var/log/' $lname;;
    esac

}

function show_log() {                                                                        
log="$1$2"
dialog --clear --backtitle "Exiro Management Tools" --title "[ LOG: $log ]" --textbox $log 30 100 2>"${INPUT}"
retval=$?
case $retval in
0) log_selection
esac
}

function menu_journal() {
log=$(journalctl -xe -b --no-pager >> /tmp/journallog.$$)
dialog --clear --backtitle "Exiro Management Tools" --title "[ LOG: journalctl ]" --textbox /tmp/journallog.$$ 30 100 2>"${INPUT}"     
rm /tmp/journallog.$$
retval=$?
case $retval in
    0) log_selection
esac

}


log_selection
