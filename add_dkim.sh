#!/bin/bash                                                                                                                      
####### get variables
if ! ( [ "$1" ] ); then
        read -p "Please enter domainname with tld:" DOMAIN
else
        DOMAIN=$1
fi

###### add domainkeys
mkdir -p /etc/opendkim/keys/$DOMAIN
opendkim-genkey -r -D /etc/opendkim/keys/$DOMAIN -d $DOMAIN
echo "default._domainkey.$DOMAIN $DOMAIN:default:/etc/opendkim/keys/$DOMAIN/default.private" >> /etc/opendkim/KeyTable
echo "*@$DOMAIN default._domainkey.$DOMAIN" >> /etc/opendkim/SigningTable
echo "*.$DOMAIN" >> /etc/opendkim/TrustedHosts
chown -R opendkim:opendkim /etc/opendkim
chmod -R 700 /etc/opendkim
service opendkim reload

##### and this domainkeys record to the zone:
ZONEFILE="/etc/bind/zones/$DOMAIN"
echo "add this to the zonefile:"
echo $(cat /etc/opendkim/keys/$DOMAIN/default.txt);

