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
apt-get install -y vim git lua5.1 luarocks lua-inspect liblua5.1-dev firebird-dev firebird3.0-server libssh-dev wget gnupg ca-certificates software-properties-common
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
echo "CREATE TABLE users (id BIGINT NOT NULL PRIMARY KEY, name VARCHAR(50) NOT NULL, followers_count INT NOT NULL, screen_name VARCHAR(50) NOT NULL, location VARCHAR(50) NOT NULL);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "CREATE TABLE hashtags (id VARCHAR(20) NOT NULL PRIMARY KEY);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "CREATE TABLE tweets_hashtags (tweet_id BIGINT NOT NULL, hashtag_id VARCHAR(20) NOT NULL);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "ALTER TABLE tweets ADD CONSTRAINT fk_tweet_user FOREIGN KEY (user_id) REFERENCES users(id);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_tweet FOREIGN KEY (tweet_id) REFERENCES tweets(id);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
echo "ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_hashtag FOREIGN KEY (hashtag_id) REFERENCES hashtags(id);" | isql-fb -u app -p "$APP_PASSWORD" localhost:/var/lib/firebird/3.0/data/luafirebird.fdb
