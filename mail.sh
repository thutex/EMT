#!/bin/bash
################################
#     script for the mailhost
#     purpose: add/remove/list
#     domains/mailboxes/aliases
##################################
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/writelog.sh"
log "Mailhost script started"

## ----------------------------------
# Step #1: Define variables
# ----------------------------------
POSTFIXDB="/etc/postfix/conf/postfix.sqlite"
#POSTFIXDB="/root/postfix.sqlite"

MAINOPTIONS=("" "-------------NEW-------------"
         1 "Add Domain"
         2 "Add Mailbox"
         3 "Add Alias"
         "" "-------------CURRENT-------------"
         4 "...Domains"
         5 "...Mailboxes"
         6 "...Aliases"
         )

TITLE="[ M A I L - M E N U ]"
# ----------------------------------
# Step #2: define functions
# ----------------------------------

display_options(){
    CHOICE=$(dialog --clear --backtitle "Exiro Management Tools" \
    --title "$TITLE" \
    --cancel-label "Exit"  \
    --menu "" 20 60 40 \
    "${MAINOPTIONS[@]}" \
    2>&1 >/dev/tty)

    ### THESE OPTIONS HAVE TO BE MODIFIED ACCORDING TO THE MAINOPTIONS VAR ABOVE
case $CHOICE in
        1) add_domain;;
        2) add_mailbox;;
        3) add_alias;;
        4) mail_list "List domains" domain domain domain;;
        5) mail_list "List mailboxes" mailbox username mailbox;;
        6) mail_list "List aliases (alias -> real mailbox)" alias address,goto alias;;
        Exit) exit;;
        *) exit;;
esac
}
display_output(){
        dialog --clear --backtitle "Exiro Management Tools" --title "Query: $1"  --msgbox "$2" 40 80

}


mail_list(){

query=($(sqlite3 $POSTFIXDB "SELECT $3 from $4"))

arr=()
for i in "${query[@]}"; do
first=${i%|*}
second=${i#*|}

arr+=("$first" "$second")
done

CHOICE=$(dialog --clear --backtitle "Exiro Management Tools" \
    --title "Query: $1" \
    --ok-label "Delete" \
    --cancel-label "Cancel" \
    --defaultno \
    --menu "" 20 60 40 \
    "${arr[@]}" \
    2>&1 >/dev/tty )
ret=$?
case $ret in
0) del_$2 $CHOICE ;; # ok button (set as delete)
#  1) ;; # cancel  button
#  *) echo 'unexpected '; exit ;;
esac
}

function add_domain() {
local DIALOG=$(dialog --clear --backtitle "Exiro Management Tools" \
 --title "[ EMAIL - DOMAIN ]" \
 --inputbox "Enter the domain name:" 8 40 2>&1 >/dev/tty )
 domain=$DIALOG
local DIALOG=$(dialog --clear --backtitle "Exiro Management Tools" \
 --title "[ EMAIL - DOMAIN ]" \
 --inputbox "Enter the description:" 8 40 2>&1 >/dev/tty )
    desc=$DIALOG
   $(sqlite3 $POSTFIXDB "INSERT INTO domain ( domain, description, transport ) VALUES ( '$domain', '$desc', 'virtual' );")
        display_output "Domain added" "Domain $domain ($desc) added to database"
}

function del_domain() {
$(sqlite3 $POSTFIXDB "DELETE FROM alias WHERE domain = '$1';")
$(sqlite3 $POSTFIXDB "DELETE FROM mailbox WHERE domain = '$1'")
$(sqlite3 $POSTFIXDB "DELETE FROM domain WHERE domain = '$1'")
display_output "Domain deleted" "Domain $1 and all related mailboxes and aliases have been removed"

}

function add_mailbox() {
local DIALOG=$(dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - MAILBOX ]" --inputbox "Enter the email address:" 8 40 2>&1 >/dev/tty )
    address=$DIALOG
    local DIALOG=$(dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - MAILBOX ]" --passwordbox "Enter the password:" 8 40 2>&1 >/dev/tty )
    plainpassword=$DIALOG
    password=`doveadm pw -s SHA512-CRYPT -p $plainpassword`
    domain=${address##*@}
    name=${address%@*}
$(sqlite3 $POSTFIXDB "INSERT INTO mailbox ( username, password, name, maildir, domain, local_part ) VALUES ( '$address', '$password', '$name', '$domain/$name', '$domain', '$name' );")
        display_output "Mailbox added" "Mailbox $address added to database"
}

function del_mailbox() {
    address=$1
$(sqlite3 $POSTFIXDB "DELETE FROM mailbox WHERE username = '$address';")
$(sqlite3 $POSTFIXDB "DELETE FROM alias WHERE goto = '$address';")
display_output "Mailbox removed" "Mailbox $1 and related aliases removed from database"
}

function add_alias() {
local DIALOG=$(dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - ALIAS ]" --inputbox "Enter the alias:" 8 40 2>&1 >/dev/tty )
    alias=$DIALOG
local DIALOG=$(dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - ALIAS ]" --inputbox "Enter the final email address:" 8 40 2>&1 >/dev/tty )
    goto=$DIALOG
   domain=${alias##*@}
$(sqlite3 $POSTFIXDB "INSERT INTO alias ( address, goto, domain ) VALUES ( '$alias', '$goto', '$domain' );")
        display_output "Alias added" "Alias $alias now redirects to $goto"
}

function del_alias() {
    alias=$1
   domain=${alias##*@}
$(sqlite3 $POSTFIXDB "DELETE FROM alias WHERE address = '$alias' AND domain = '$domain';")
$(sqlite3 $POSTFIXDB "DELETE FROM alias WHERE goto = '$address';")
display_output "Alias removed" "Alias $alias (on $domain) removed from database"
}


# ----------------------------------------------
# Step #3: Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP

# -----------------------------------
# Step #4: Main logic - infinite loop
# ------------------------------------

while true
do
        display_options

done

