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

# Lua, Firebird, Vim e outros
apt-get update
apt-get install -y vim git lua5.1 luarocks lua-inspect liblua5.1-dev firebird-dev firebird3.0-server libssh-dev wget gnupg ca-certificates software-properties-common apt-transport-https openjdk-11-jre
apt-get clean

# OpenResty
wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -
add-apt-repository -y "deb http://openresty.org/package/debian $(lsb_release -sc) openresty"
apt-get update && apt-get -y install openresty
cp /opt/app/server/nginx.conf.vagrant /etc/openresty/nginx.conf
systemctl enable openresty

# MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" > /etc/apt/sources.list.d/mongodb-org-4.2.list
apt-get update && apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod
tar -xf /opt/app/dumps/mongo-graylog.tar.gz -C /tmp
cd /tmp
mongorestore
rm -rf /tmp/dump

# Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" > /etc/apt/sources.list.d/elastic-6.x.list
apt-get update && apt-get install -y elasticsearch
systemctl start elasticsearch
systemctl enable elasticsearch

# Graylog
echo '127.0.0.1 graylog' >> /etc/hosts
wget https://packages.graylog2.org/repo/packages/graylog-3.1-repository_latest.deb
dpkg -i graylog-3.1-repository_latest.deb
apt-get update
apt-get install -y graylog-server
sed -i 's/password_secret =/password_secret = wNJfMeW3ykAmLV8dMqp4Bkpzm444dsn7/' /etc/graylog/server/server.conf
GRAYLOG_PWD="$(echo -n admin | sha256sum | cut -d' ' -f1)"
sed -i "s/root_password_sha2 =/root_password_sha2  = $GRAYLOG_PWD/" /etc/graylog/server/server.conf
sed -i 's/#http_bind_address = 127.0.0.1:9000/http_bind_address = 0.0.0.0:9000/' /etc/graylog/server/server.conf
systemctl start graylog-server
systemctl enable graylog-server

# Prometheus
apt-get install -y prometheus
# Adiciona o target ao Prometheus
cat >> /etc/prometheus/prometheus.yml <<'EOF'
  - job_name: twitter_harvester
    static_configs:
      - targets: ['localhost:8080']
EOF
systemctl restart prometheus
systemctl enable prometheus

# Grafana
echo '127.0.0.1 prometheus' >> /etc/hosts
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
apt-get update && apt-get install grafana
cp /opt/app/dumps/grafana.db.gz /var/lib/grafana
cd /var/lib/grafana
rm -rf grafana.db
gunzip grafana.db.gz
chown grafana: /var/lib/grafana/grafana.db
systemctl start grafana-server
systemctl enable grafana-server

apt-get clean

# Dependências da aplicação
echo '127.0.0.1 firebird' >> /etc/hosts
luarocks install luasql-firebird
luarocks install lua-cjson 2.1.0-1
luarocks install date
luarocks install lapis

#  OpenSSL 1.1.1
apt-get install -y build-essential
cd /usr/src
git clone -b OpenSSL_1_1_1-stable https://github.com/openssl/openssl.git
cd openssl
./config
make -j 6
make install
rm /usr/local/openresty/openssl/lib/libcrypto.so.1.1 /usr/local/openresty/openssl/lib/libssl.so.1.1
cp /usr/src/openssl/libcrypto.so.1.1 /usr/local/openresty/openssl/lib/libcrypto.so.1.1
cp /usr/src/openssl/libssl.so.1.1 /usr/local/openresty/openssl/lib/libssl.so.1.1

# Firebird
sed -i 's/RemoteBindAddress = localhost//' /etc/firebird/3.0/firebird.conf
sed -i 's,# DatabaseAccess = Full,DatabaseAccess = Restrict /var/lib/firebird/3.0/data/,' /etc/firebird/3.0/firebird.conf
systemctl stop firebird3.0

echo "CREATE USER app PASSWORD '$APP_PASSWORD';" | isql-fb -u sysdba -p "$SYSDBA_PASSWORD" /var/lib/firebird/3.0/system/security3.fdb
echo "CREATE DATABASE '/var/lib/firebird/3.0/data/luafirebird.fdb';" | isql-fb -u app -p "$APP_PASSWORD" /var/lib/firebird/3.0/system/security3.fdb
chown firebird: /var/lib/firebird/3.0/data/luafirebird.fdb
systemctl start firebird3.0

eval $(head -n12 /opt/app/server/nginx.conf.vagrant | sed 's/env /export /' | sed "s/=/='/" | sed "s/;/';/")
lua /opt/app/migration.lua

systemctl enable firebird3.0
systemctl restart openresty
