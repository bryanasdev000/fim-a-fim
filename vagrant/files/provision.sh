#!/bin/bash

mkdir -p /opt/app
mkdir -p /etc/firebird/3.0

cat > /etc/firebird/3.0/SYSDBA.password <<'EOF'
# Password for firebird SYSDBA user
#
# You may want to use the following command for changing it:
#   dpkg-reconfigure firebird3.0
#
# If you change the password manually with isql-fb or gsec, please update it
# here too. Keeping this file in sync with the security database is useful for
# any database maintenance scripts that need to connect as SYSDBA.

ISC_USER=sysdba
ISC_PASSWORD="firebird"
EOF

apt-get update
apt-get install -y vim git lua5.3 luarocks firebird-dev liblua5.3-dev firebird3.0-server
luarocks install luasql-firebird
