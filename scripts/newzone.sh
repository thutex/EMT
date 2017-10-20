#!/bin/bash

if [ $# -ne 1 ]
then
        printf "Syntax: $(basename $0) domainname"
        exit 1
fi

DOMAIN=$1
WWWIP=127.0.0.1
ZONEDIR="/etc/bind/zones/"
KEYDIR="/etc/bind/keys/"
LECERTS="/etc/letsencrypt/live/$DOMAIN"
CHAINGENDIR="/root/automation/"
opendkim="/etc/opendkim"
location="$opendkim/keys/$DOMAIN"
BIND="/etc/init.d/bind9"
APACHE="/etc/init.d/apache2"

SERIAL=$(date +"%Y%m%d")01                     # Serial yyyymmddnn
echo "setting up $DOMAIN" 
 
cat <<EOT >> $ZONEDIR$DOMAIN
\$ORIGIN $DOMAIN.
\$TTL 3H
@	IN	SOA	host.example.org.	tech.peeters.io. (
		$SERIAL		; serial yyyymmddnn
		3H		; Refresh After 3 hours
		1H		; Retry Retry after 1 hour
		1W		; Expire after 1 week
		1H )		; Minimum negative caching of 1 hour
; Name servers 
@			3600	IN	NS	host.example.org.
; MX Records 
@			3600	IN 	MX	10	host.example.org.
; A Records
@ 			3600	IN 	A	$WWWIP
; CNAME Records
www			3600	IN	CNAME	@
webmail			3600	IN	CNAME	@
; OTHER
@     		        IN TXT  "v=spf1 +a +mx -all +a:host.example.org"
_dmarc          	IN TXT  "v=DMARC1; p=reject"
_domainkey              IN TXT  "o=-"


EOT

DATE=$(date +%Y%m%d)
serial="${DATE}01"
NOW=$(date)
/bin/sed -i -e "s/^\(\s*\)[0-9]\{0,\}\(\s*;\s*Serial\)$/\1${serial}\2/Ig" $ZONEDIR/$DOMAIN
echo "; adding sshfp records" >> $ZONEDIR/$DOMAIN
ssh-keygen -r $DOMAIN >> $ZONEDIR/$DOMAIN
echo "; adding dkim records" >> $ZONEDIR/$DOMAIN
mkdir -p "$location"
cd "$location"
opendkim-genkey -d $1 -s mail
chown opendkim:opendkim *
chown opendkim:opendkim "$location"
chmod u=rw,go-rwx *
echo "$DOMAIN $DOMAIN:mail:$location/mail.private" >> "$opendkim/KeyTable"
echo "*@$DOMAIN $DOMAIN" >> "$opendkim/SigningTable"
echo "$DOMAIN" >> "$opendkim/TrustedHosts"
echo "mail.$DOMAIN" >> "$opendkim/TrustedHosts"
cat "$location/mail.txt" >> $ZONEDIR/$DOMAIN
cd /root
echo "finished file creation"
dnssec-keygen -K $KEYDIR -a RSASHA256 -b 2048 -f KSK $DOMAIN
dnssec-keygen -K $KEYDIR -a RSASHA256 -b 1024 $DOMAIN
chmod 640 $KEYDIR/*.private
echo "Adding zone for $DOMAIN to named.conf.local"
cat <<EOT >> /etc/bind/named.conf.local
#Zone for $DOMAIN
zone "$DOMAIN" {
     type master;
     file "/etc/bind/zones/$DOMAIN";
     auto-dnssec maintain;
     inline-signing yes;
};
EOT
$BIND reload
$APACHE restart
