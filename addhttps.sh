#!/bin/bash

logfilename="/var/log/addhttps.log"
wwwconfdir="/etc/apache2/sites-available"
certdir="/etc/dehydrated/certs"
serverIP="1.1.1.1"

echo "$(date '+%Y.%m.%d %H:%M:%S') $1 adding https started" >>$logfilename

if ! [ -f $wwwconfdir/$1.conf  ] ; then
    echo "$(date '+%Y.%m.%d %H:%M:%S') $1 domain not found!" >>$logfilename
    exit 0
fi

if grep -q "dehydrated/certs" $wwwconfdir/$1.conf; then
    echo "$(date '+%Y.%m.%d %H:%M:%S') $1 HTTPS already enabled!" >>$logfilename
    exit 0
fi

if grep -q "www.$1" /etc/dehydrated/domains.txt; then
    echo "$(date '+%Y.%m.%d %H:%M:%S') $1 already in domains.txt!" >>$logfilename
    exit 0
fi

echo $1 www.$1 >>/etc/dehydrated/domains.txt
dehydrated --cron

if ! [ -f $certdir/$1/fullchain.pem ] ; then
    echo "$(date '+%Y.%m.%d %H:%M:%S') $1 Cert not generated!" >>$logfilename
    exit 0
fi

if grep -q ":443" $wwwconfdir/$1.conf; then
    sed -i "/SSL/d" $wwwconfdir/$1.conf
    sed -i '/^$/d' $wwwconfdir/$1.conf
    sed -i '$d' $wwwconfdir/$1.conf
else
    cp $wwwconfdir/$1.conf /tmp/$1.conf
    sed -i '/^$/d' /tmp/$1.conf
    sed -i '$d' /tmp/$1.conf
    sed -i 's/$serverIP:80/$serverIP:443/' /tmp/$1.conf
    cat /tmp/$1.conf >> $wwwconfdir/$1.conf
    rm /tmp/$1.conf
fi

echo "SSLEngine on" >> $wwwconfdir/$1.conf
echo "SSLProtocol ALL -SSLv2 -SSLv3" >> $wwwconfdir/$1.conf
echo "SSLHonorCipherOrder on" >> $wwwconfdir/$1.conf
echo "SSLCipherSuite ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL" >> $wwwconfdir/$1.conf
echo "SSLCertificateFile /etc/dehydrated/certs/$1/fullchain.pem" >> $wwwconfdir/$1.conf
echo "SSLCertificateKeyFile /etc/dehydrated/certs/$1/privkey.pem" >> $wwwconfdir/$1.conf
echo "</VirtualHost>" >> $wwwconfdir/$1.conf

if apachectl configtest; then
    service apache2 reload
else
    echo "$(date '+%Y.%m.%d %H:%M:%S') apachectl configtest failed!" >>$logfilename
    exit 0
fi

echo "$(date '+%Y.%m.%d %H:%M:%S') $1 adding https stopped" >>$logfilename
