#!/bin/bash
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$
MYSQL=`which mysql`
BTICK='`'                                                                                                                                              
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM
function main_menu() {
source /opt/EMT/EMT.sh
}
function display_options() {
dialog --clear \
        --backtitle "Exiro Management Tools" \
        --title "[ SQL ]" \
        --cancel-label "Return" \
        --menu "" 20 60 40 \
        'List databases' "List current databases" \
        'Add database' "Add a new database" \
        'Delete database' "Delete a database" \
        'List users' "List users and rights" \
        'Add user' "Add user" \
        'Modify user' "Modify permissions (manual query)" \
        'Delete user' "Delete user" 2>"${INPUT}"
    menuitem=$(<"${INPUT}")
    retval=$?
    case $retval in
        0)
            case $menuitem in
                'List databases') list_database;;
                'Add database') add_database;;
                'Delete database') del_database;;
                'List users') list_user;;
                'Add user') add_user;;
                'Modify user') mod_user;;
                'Delete user') del_user;;
            esac;;
        1)
            main_menu
           break;;
    esac
}

function list_database() {
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - LIST DATABASES ]" --passwordbox "Enter the mysql root pass:" 8 40 2>/tmp/emt-sql.$$
    rootpass=$(< /tmp/emt-sql.$$)
    export MYSQL_PWD=$rootpass
    rm -f /tmp/emt-sql.$$
    SQL="SHOW DATABASES"
    listthis=`$MYSQL -sN -uroot -e "$SQL"`
    dialog --backtitle "Exiro Management Tools" --msgbox "$listthis" 25 50 2>"${INPUT}"
    retval=$?
    case $retval in
        0) display_options;;
    esac
}

function list_user() {
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - LIST USERS ]" --passwordbox "Enter the mysql root pass:" 8 40 2>/tmp/emt-sql.$$
    rootpass=$(< /tmp/emt-sql.$$)
    export MYSQL_PWD=$rootpass
    rm -f /tmp/emt-sql.$$
    listthis=` mysql -uroot -sNe"$(mysql -uroot -se"SELECT CONCAT('SHOW GRANTS FOR \'',user,'\'@\'',host,'\';') FROM mysql.user  WHERE user != 'root' AND user != 'mysql.sys' AND user != 'mysql.session' AND user != 'debian-sys-maint';")"`
    dialog --backtitle "Exiro Management Tools" --msgbox "$listthis" 25 50 2>"${INPUT}"
    retval=$?
    case $retval in
        0) display_options;;
    esac
}

function add_database() {
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - NEW DATABASE ]" --inputbox "Enter the database name:" 8 40 2>/tmp/emt-sql.$$
    dbname=`cat /tmp/emt-sql.$$`
    rm -f /tmp/emt-sql.$$
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - NEW DATABASE ]" --passwordbox "Enter the mysql root pass:" 8 40 2>/tmp/emt-sql.$$
    rootpass=`cat /tmp/emt-sql.$$`
    export MYSQL_PWD=$rootpass
    rm -f /tmp/emt-sql.$$
    SQL="CREATE DATABASE IF NOT EXISTS ${BTICK}$1${BTICK};"
    $MYSQL -uroot -p$rootpass -e "$SQL"
    dialog --backtitle "Exiro Management Tools" \
           --title "[ SQL - DATABASE ADDED ]" \
           --msgbox \
           "Database $dbname added, don't forget to add a user" 10 50 2>"${INPUT}"
    retval=$?
    case $retval in
    0) display_options;;
    esac
}  
function del_database() {
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - REMOVE DATABASE ]" --inputbox "Enter the database name:" 8 40 2>/tmp/emt-sql.$$
    dbname=`cat /tmp/emt-sql.$$`
    rm -f /tmp/emt-sql.$$
    dialog --backtitle "Exiro Management Tools" --title "[ SQL -REMOVE DATABASE ]" --passwordbox "Enter the mysql root pass:" 8 40 2>/tmp/emt-sql.$$
    rootpass=`cat /tmp/emt-sql.$$`
    export MYSQL_PWD=$rootpass
    rm -f /tmp/emt-sql.$$
    SQL="DROP DATABASE IF EXISTS ${BTICK}$1${BTICK};"
    $MYSQL -uroot -p$rootpass -e "$SQL"
    dialog --backtitle "Exiro Management Tools" \
           --title "[ SQL - DATABASE REMOVED ]" \
           --msgbox \
           "Database $dbname has been removed" 10 50 2>"${INPUT}"
    retval=$?
    case $retval in
    0) display_options;;
    esac
}

function add_user() {
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - NEW USER ]" --passwordbox "Enter the mysql root pass:" 8 40 2>/tmp/emt-sql.$$
    rootpass=`cat /tmp/emt-sql.$$`
    export MYSQL_PWD=$rootpass
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - NEW USER ]" --inputbox "Enter the username:" 8 40 2>/tmp/emt-sql.$$
    uname=`cat /tmp/emt-sql.$$`
    rm -f /tmp/emt-sql.$$
	newpass=`date +%s | sha256sum | base64 | head -c 16`
    SQL="CREATE USER IF NOT EXISTS '$uname'@'localhost' IDENTIFIED by '$newpass';"
    $MYSQL -uroot -p$rootpass -e "$SQL"
    dialog --backtitle "Exiro Management Tools" \
           --title "[ SQL - USER ADDED ]" \
           --msgbox \
           "User $uname added, generated password: $newpass" 10 50 2>"${INPUT}"
    retval=$?
    case $retval in
    0) display_options;;
    esac
}
function mod_user() {
    display_options
}
function del_user() {
    dialog --backtitle "Exiro Management Tools" --title "[ SQL - REMOVE USER ]" --passwordbox "Enter the mysql root pass:" 8 40 2>/tmp/emt-sql.$$
    rootpass=`cat /tmp/emt-sql.$$`                                                                                                                         
    export MYSQL_PWD=$rootpass
    rm -f /tmp/emt-sql.$$
	listthis=` mysql -uroot -sNe "SELECT User FROM mysql.user WHERE user != 'root' AND user != 'mysql.sys' AND user != 'mysql.session' AND user != 'debian-sys-maint';"`
OLDIFS="$IFS"
IFS=' '
show=''
readarray -t items <<<"$listthis"
for element in "${items[@]}"
do
    show="$show $element $element"
done
	IFS="$OLDIFS"
    dialog --clear \
        --backtitle "Exiro Management Tools" \
        --title "[ SQL - REMOVE USER ]" \
        --cancel-label "Return" \
        --menu "" 20 60 40 \
        $show 2>"${INPUT}"
	uname=$(<"${INPUT}")
    retval=$?
    case $retval in
    0)
    SQL="DROP USER IF EXISTS '$uname'@'localhost';"
    $MYSQL -uroot -e "$SQL"
    dialog --backtitle "Exiro Management Tools" \
           --title "[ SQL - USER REMOVED ]" \
           --msgbox \
           "User $uname removed" 10 50 2>"${INPUT}"
    retval=$?
    case $retval in
    0) display_options;;
    esac;;
    1)
        break;;
    esac

}
display_options

