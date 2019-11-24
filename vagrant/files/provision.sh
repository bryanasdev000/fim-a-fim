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
apt-get install -y vim git lua5.1 luarocks lua-inspect liblua5.1-dev firebird-dev firebird3.0-server libssh-dev wget gnupg ca-certificates software-properties-common apt-transport-https
apt-get clean

# OpenResty
wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
sudo add-apt-repository -y "deb http://openresty.org/package/debian $(lsb_release -sc) openresty"
sudo apt-get update
sudo apt-get -y install openresty

luarocks install luasql-firebird
luarocks install lua-cjson 2.1.0-1
luarocks install date
luarocks install lapis

# MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" > /etc/apt/sources.list.d/mongodb-org-4.2.list
apt-get update && apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod

# Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" > /etc/apt/sources.list.d/elastic-6.x.list
apt-get update && apt-get install -y elasticsearch
systemctl start elasticsearch
systemctl enable elasticsearch

# Graylog
wget https://packages.graylog2.org/repo/packages/graylog-3.1-repository_latest.deb
dpkg -i graylog-3.1-repository_latest.deb
apt-get update
apt-get install -y graylog-server openjdk-11-jre
sed -i 's/password_secret =/password_secret = /wNJfMeW3ykAmLV8dMqp4Bkpzm444dsn7/' /etc/graylog/server/server.conf
GRAYLOG_PWD="$(echo -n admin | sha256sum | cut -d' ' -f1)"
sed -i "s/root_password_sha2 =/root_password_sha2  = $GRAYLOG_PWD/" /etc/graylog/server/server.conf
sed -i 's/#http_bind_address = 127.0.0.1:9000/http_bind_address = 0.0.0.0:9000/' /etc/graylog/server/server.conf
systemctl start graylog-server
systemctl enable graylog-server

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

systemctl stop firebird3.0

echo "CREATE USER app PASSWORD '$APP_PASSWORD';" | isql-fb -u sysdba -p "$SYSDBA_PASSWORD" /var/lib/firebird/3.0/system/security3.fdb
echo "CREATE DATABASE '/var/lib/firebird/3.0/data/luafirebird.fdb';" | isql-fb -u app -p "$APP_PASSWORD" /var/lib/firebird/3.0/system/security3.fdb
chown firebird: /var/lib/firebird/3.0/data/luafirebird.fdb

systemctl start firebird3.0

echo "CREATE TABLE tweets (id BIGINT NOT NULL PRIMARY KEY, created_at TIMESTAMP NOT NULL, user_id BIGINT NOT NULL, text VARCHAR(500) NOT NULL);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "CREATE TABLE users (id BIGINT NOT NULL PRIMARY KEY, name VARCHAR(100) NOT NULL, followers_count INT NOT NULL, screen_name VARCHAR(50) NOT NULL, location VARCHAR(100) NOT NULL);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "CREATE TABLE hashtags (id VARCHAR(50) NOT NULL PRIMARY KEY);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "CREATE TABLE tweets_hashtags (tweet_id BIGINT NOT NULL, hashtag_id VARCHAR(50) NOT NULL);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "ALTER TABLE tweets ADD CONSTRAINT fk_tweet_user FOREIGN KEY (user_id) REFERENCES users(id);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_tweet FOREIGN KEY (tweet_id) REFERENCES tweets(id);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_hashtag FOREIGN KEY (hashtag_id) REFERENCES hashtags(id);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "CREATE UNIQUE INDEX idx_tweet_hashtag ON tweets_hashtags (tweet_id, hashtag_id);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb

# Adiciona filtro ao Graylog
mongo graylog --eval 'db.inputs.insert({ "_id" : ObjectId("5dd9ae7a4d7ac153481a7bd5"), "creator_user_id" : "admin", "configuration" : { "idle_writer_timeout" : 60, "recv_buffer_size" : 1048576, "max_chunk_size" : 65536, "tcp_keepalive" : false, "number_worker_threads" : 4, "enable_cors" : true, "tls_client_auth_cert_file" : "", "bind_address" : "0.0.0.0", "tls_cert_file" : "", "decompress_size_limit" : 8388608, "port" : 12201, "tls_key_file" : "", "tls_enable" : false, "tls_key_password" : "", "tls_client_auth" : "disabled", "override_source" : null }, "name" : "GELF HTTP", "created_at" : ISODate("2019-11-24T01:55:08.037Z"), "global" : true, "type" : "org.graylog2.inputs.gelf.http.GELFHttpInput", "title" : "gelf", "content_pack" : null })'

cat > /lib/systemd/system/twitter-harvester.service <<EOF
[Unit]
Description = Inicia o servidor Openresty para o Twitter Harvester
Wants=network-online.target
After=network-online.target

[Service]
WorkingDirectory = /opt/app
ExecStart = lapis server

[Install]
WantedBy = multi-user.target
EOF

systemctl start twitter-harvester
systemctl enable twitter-harvester
