#/bin/bash

INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM
function main_menu() {
source /opt/EMT/EMT.sh
}
function display_options() {
dialog --clear \
        --backtitle "Exiro Management Tools" \
        --title "[ HTTPS/SSL ]" \
        --cancel-label "Return" \
        --menu "" 20 60 40 \
        'Add/Renew' "Add or renew a certificate" 2>"${INPUT}"
    menuitem=$(<"${INPUT}")
    retval=$?
    case $retval in
        0)
            case $menuitem in
                'Add/Renew') get_cert;;
            esac;;
        1)
            main_menu
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

function get_cert() {
  dialog --backtitle "Exiro Management Tools" --title "[ HTTPS/SSL ]" --inputbox "Enter the domain name:" 8 40 2>/tmp/emt-dom.$$
    dname=`cat /tmp/emt-dom.$$`
    rm -f /tmp/emt-dom.$$
letsencrypt certonly --webroot --webroot-path /var/www/ -d $dname --email mail@example.org #2>/dev/null &
log=$(tail -100 /var/log/letsencrypt/letsencrypt.log > /tmp/journallog.$$)
dialog --backtitle "Exiro Management Tools" --title "[ HTTPS/SSL ]" \
       --textbox /tmp/journallog.$$ 30 100 2>"${INPUT}"
rm /tmp/journallog.$$
retval=$?
case $retval in
    0)
      main_menu
esac
}
display_options
