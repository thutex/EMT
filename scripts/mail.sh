#!/bin/bash
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM
function main_menu() {
source /opt/EMT/EMT.sh
}
function display_options() {
    dialog --clear \
        --backtitle "Exiro Management Tools" \
        --title "[ EMAIL ]" \
        --cancel-label "Return" \
        --menu "" 20 60 40 \
        'List domains' "List current email domains" \
        'Add domain' "Add email domain" \
	'Delete domain' "Delete domain" \
        'List mailboxes' "List current mailboxes" \
        'Add mailbox' "Add mailbox to existing domain" \
	'Delete mailbox' "Delete mailbox" \
        'List alias' "List current alias" \
        'Add alias' "Add alias for email (same domain)" \
	'Delete alias' "Delete alias"  2>"${INPUT}"
    menuitem=$(<"${INPUT}")
    retval=$?
    case $retval in
        0)
            case $menuitem in
                'List domains') listitems domain domain;;
                'Add domain') add_domain;;
		'Delete domain') del_domain;;
                'List mailboxes') listitems username mailbox;;
                'Add mailbox') add_mailbox;;
		'Delete mailbox') del_mailbox;;
                'List alias') listitems address,goto alias;;
                'Add alias') add_alias;;
		'Delete alias') del_alias;;
            esac;;
        1) main_menu
            break;;
    esac
}

function listitems() {
    query=$(sqlite3 /etc/postfix/conf/postfix.sqlite "SELECT $1 from $2")
    listthis=${query//[|]/ -> }
    dialog --backtitle "Exiro Management Tools" --msgbox "$listthis" 25 50 2>"${INPUT}"
    retval=$?
    case $retval in
        0) display_options;;
    esac
}

function add_domain() {
 dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - DOMAIN ]" --inputbox "Enter the domain name:" 8 40 2>/tmp/emt-mail.$$
 retval=$?
 case $retval in
     1)
         display_options;;
 esac
   domain=`cat /tmp/emt-mail.$$`
    dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - DOMAIN ]" --inputbox "Enter the description:" 8 40 2>/tmp/emt-mail.$$
    desc=`cat /tmp/emt-mail.$$`
    rm -f /tmp/emt-mail.$$
   echo "INSERT INTO domain ( domain, description, transport ) VALUES ( '$domain', '$desc', 'virtual' );" |sqlite3 /etc/postfix/conf/postfix.sqlite
    dialog --backtitle "Exiro Management Tools" \
        --title "[ EMAIL - DOMAIN ADDED ]" \
        --msgbox \
        "Domain $domain ($desc) added to database" 10 50 2>"${INPUT}"
retval=$?
case $retval in
        0) display_options;;
esac
}

function add_mailbox() {
    dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - MAILBOX ]" --inputbox "Enter the email address:" 8 40 2>/tmp/emt-mail.$$
    address=`cat /tmp/emt-mail.$$`
    dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - MAILBOX ]" --passwordbox "Enter the password:" 8 40 2>/tmp/emt-mail.$$
    plainpassword=`cat /tmp/emt-mail.$$`
    rm -f /tmp/emt-mail.$$
    password=`doveadm pw -s SHA512-CRYPT -p $plainpassword`
    domain=${address##*@}
    name=${address%@*}
	echo "INSERT INTO mailbox ( username, password, name, maildir, domain, local_part ) VALUES ( '$address', '$password', '$name', '$domain/$name', '$domain', '$name' );" |sqlite3 /etc/postfix/conf/postfix.sqlite
    dialog --backtitle "Exiro Management Tools" \
           --title "[ EMAIL - MAILBOX ADDED ]" \
           --msgbox \
           "Mailbox $address added to database" 10 50 2>"${INPUT}"
retval=$?
case $retval in
    0) display_options;;
esac
}

function add_alias() {
   dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - ALIAS ]" --inputbox "Enter the alias:" 8 40 2>/tmp/emt-mail.$$
   alias=`cat /tmp/emt-mail.$$`
   rm -f /tmp/emt-mail.$$
   dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - ALIAS ]" --inputbox "Enter the final email address:" 8 40 2>/tmp/emt-mail.$$
   goto=`cat /tmp/emt-mail.$$`
   rm -f /tmp/emt-mail.$$
   domain=${goto##*@}
		echo "INSERT INTO alias ( address, goto, domain ) VALUES ( '$alias', '$goto', '$domain' );" |sqlite3 /etc/postfix/conf/postfix.sqlite

    dialog --backtitle "Exiro Management Tools" \
        --title "[ EMAIL - ALIAS ADDED ]" \
        --msgbox \
        "Alias $alias added, redirects to $goto" 10 50 2>"${INPUT}"
retval=$?
case $retval in
        0) display_options;;
esac

}

function del_domain() {
 dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - DOMAIN ]" --inputbox "Enter the domain name:" 8 40 2>/tmp/emt-mail.$$
 domain=`cat /tmp/emt-mail.$$`
 rm -f /tmp/emt-mail.$$
 echo "DELETE FROM domain WHERE domain = '$domain';" |sqlite3 /etc/postfix/conf/postfix.sqlite
 echo "DELETE FROM mailbox WHERE domain = '$domain';" |sqlite3 /etc/postfix/conf/postfix.sqlite
 echo "DELETE FROM alias WHERE domain = '$domain';" |sqlite3 /etc/postfix/conf/postfix.sqlite

    dialog --backtitle "Exiro Management Tools" \
        --title "[ EMAIL - DOMAIN REMOVED ]" \
        --msgbox \
        "Domain $domain removed from database" 10 50 2>"${INPUT}"
retval=$?
case $retval in
    0) display_options;;
esac
}

function del_mailbox() {
    dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - MAILBOX ]" --inputbox "Enter the email address:" 8 40 2>/tmp/emt-mail.$$
    address=`cat /tmp/emt-mail.$$`
    rm -f /tmp/emt-mail.$$    
    echo "DELETE FROM mailbox WHERE username = '$address';" |sqlite3 /etc/postfix/conf/postfix.sqlite
    echo "DELETE FROM alias WHERE goto = '$address';" |sqlite3 /etc/postfix/conf/postfix.sqlite
    dialog --backtitle "Exiro Management Tools" \
           --title "[ EMAIL - MAILBOX REMOVED ]" \
           --msgbox \
           "Mailbox $address removed from database" 10 50 2>"${INPUT}"
retval=$?
case $retval in
    0) display_options;;
esac
}

function del_alias() { 
   dialog --backtitle "Exiro Management Tools" --title "[ EMAIL - ALIAS ]" --inputbox "Enter the alias:" 8 40 2>/tmp/emt-mail.$$
   alias=`cat /tmp/emt-mail.$$`
   domain=${alias##*@}
   echo "DELETE FROM alias WHERE address = $alias AND domain = $domain;" |sqlite3 /etc/postfix/conf/postfix.sqlite
    dialog --backtitle "Exiro Management Tools" \
        --title "[ EMAIL - ALIAS REMOVED ]" \
        --msgbox \
        "Alias $alias (on $domain) removed from database" 10 50 2>"${INPUT}"
retval=$?
case $retval in
    0) display_options;;
esac
}

display_options
