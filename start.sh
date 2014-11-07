#!/bin/sh

# Sample nabbed from apachectl and init.d/apache2
APACHE_CONFDIR=/etc/apache2
APACHE_ENVVARS=$APACHE_CONFDIR/envvars

# Load the environmentals
. $APACHE_ENVVARS

# persist the env user:password into the mod_perl session by writing files
echo $MYSQL_USER > /etc/myofficeuser.conf
echo $MYSQL_PASSWORD > /etc/myofficepassword.conf

exec /usr/sbin/apache2 -d /etc/apache2 -k start -DFOREGROUND