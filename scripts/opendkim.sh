#!/bin/bash
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required, $# provided, domain required, ex: ./script example.com"

cwd=`pwd`
opendkim="/etc/opendkim"
location="$opendkim/keys/$1"
[ -d "$location" ] && die "There is already a directory in the folder, delete the folder if you want to create a new one"

mkdir -p "$location"
cd "$location"
opendkim-genkey -d $1 -s mail
chown opendkim:opendkim *
chown opendkim:opendkim "$location"
chmod u=rw,go-rwx *
echo "$1 $1:mail:$location/mail.private" >> "$opendkim/KeyTable"
echo "*@$1 $1" >> "$opendkim/SigningTable"
echo "$1" >> "$opendkim/TrustedHosts"
echo "mail.$1" >> "$opendkim/TrustedHosts"
echo
echo "Put this in the DNS ZONE for domain: $1"
echo
cat "$location/mail.txt"
echo
cd "$cwd"

