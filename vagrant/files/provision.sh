#!/bin/bash

SYSDBA_PASSWORD='firebird'
APP_PASSWORD='zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'

mkdir -p /opt/app
mkdir -p /etc/firebird/3.0

cat > /etc/firebird/3.0/SYSDBA.password <<EOF
# Password for firebird SYSDBA user
#
# You may want to use the following command for changing it:
#   dpkg-reconfigure firebird3.0
#
# If you change the password manually with isql-fb or gsec, please update it
# here too. Keeping this file in sync with the security database is useful for
# any database maintenance scripts that need to connect as SYSDBA.

ISC_USER=sysdba
ISC_PASSWORD="$SYSDBA_PASSWORD"
EOF

apt-get update
apt-get install -y vim git lua5.3 luarocks firebird-dev liblua5.3-dev firebird3.0-server
apt-get clean
luarocks install luasql-firebird

echo "CREATE USER app PASSWORD '$APP_PASSWORD';" | isql-fb -u sysdba -p "$SYSDBA_PASSWORD" /var/lib/firebird/3.0/system/security3.fdb
echo "CREATE DATABASE '/var/lib/firebird/3.0/data/luafirebird.fdb';" | isql-fb -u app -p "$APP_PASSWORD" /var/lib/firebird/3.0/system/security3.fdb
chown firebird: /var/lib/firebird/3.0/data/luafirebird.fdb
echo "CREATE TABLE twitter (hashtag VARCHAR(50) NOT NULL PRIMARY KEY, content VARCHAR(100));" | isql-fb -u app -p "$APP_PASSWORD" /var/lib/firebird/3.0/data/luafirebird.fdb
