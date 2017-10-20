#!/bin/bash
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$
trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM
function display_output(){
	local h=${1-10}			# box height default 10
	local w=${2-41} 		# box width default 41
	local t=${3-Output} 	# box title 
	dialog --backtitle "Exiro Management Tools" --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
}

function menu_mail() {
source /opt/EMT/scripts/mail.sh
}
function menu_sql() {
source /opt/EMT/sql.sh
}
function menu_bind() {
dialog --msgbox "not ready yet"
}
function menu_vhosts() {
dialog --msgbox "not ready yet"                                                              
}                   
function menu_ssl() {
source /opt/EMT/scripts/ssl.sh                                                              
}                   
function menu_dkim() {
dialog --msgbox "not ready yet"                                                              
}                   
function menu_services() {
source /opt/EMT/scripts/services.sh
}
function menu_logs() {
source /opt/EMT/scripts/logs.sh
}

while true
do

### display main menu ###
dialog --clear --backtitle "Exiro Management Tools" \
    --title "[ M A I N - M E N U ]" \
    --cancel-label "Exit"  \
    --menu "" 20 60 40 \
Email "Edit email users and mailboxes" \
Mysql "Edit mysql users and databases" \
Bind "Edit DNS zones" \
Vhosts "Edit apache vhosts" \
SSL "Edit SSL certificates" \
DKIM "Edit DKIM options" \
Services "Restart services" \
Logs "View logs" 2>"${INPUT}"

menuitem=$(<"${INPUT}")
retval=$?
case $retval in
0)

case $menuitem in
	Email) menu_mail;;
	Mysql) menu_sql;;
        Bind) menu_bind;;
        Vhosts) menu_vhosts;;
        SSL) menu_ssl;;
        DKIM) menu_dkim;;
        Services) menu_services;;
        Logs) menu_logs;;
	Exit) exit;;
        *) exit;;
esac;;
1)
         exit;;
255)
         exit;;
esac
done
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
