FROM debian:buster-slim

RUN mkdir -p /etc/firebird/3.0 && \
echo -n "ISC_USER=sysdba\nISC_PASSWORD=firebird\n" > /etc/firebird/3.0/SYSDBA.password && \
chown 666 /etc/firebird/3.0/SYSDBA.password

RUN apt-get update && \
apt-get install -y git lua5.1 luarocks lua-inspect firebird3.0-server liblua5.1-dev firebird-dev libssl-dev && \
luarocks install luasql-firebird && \
luarocks install date && \
luarocks install lapis

RUN apt-get install -y build-essential && \
cd /usr/src && \
git clone -b OpenSSL_1_1_1-stable https://github.com/openssl/openssl.git && \
cd openssl && \
./config && make -j 6 && make install

RUN apt-get install -y curl gnupg && \
curl https://openresty.org/package/pubkey.gpg | apt-key add -

FROM debian:buster-slim

COPY --from=0 /etc/apt/trusted.gpg /usr/local/lib/lua/5.1/luasql/firebird.so /usr/src/openssl/libcrypto.so.1.1 /usr/src/openssl/libssl.so.1.1 /tmp/

RUN mv /tmp/trusted.gpg /etc/apt/trusted.gpg && \
echo "deb http://openresty.org/package/debian buster openresty" > /etc/apt/sources.list.d/openresty.list && \
apt-get update && apt-get install -y git lua5.1 luarocks lua-inspect libssl-dev libfbclient2 openresty && \
mkdir -p /usr/local/lib/lua/5.1/luasql/ && \
mv /tmp/firebird.so /usr/local/lib/lua/5.1/luasql/firebird.so && \
luarocks install date && \
luarocks install lapis && \
mv /tmp/libcrypto.so.1.1 /usr/local/openresty/openssl/lib/libcrypto.so.1.1 && \
mv /tmp/libssl.so.1.1 /usr/local/openresty/openssl/lib/libssl.so.1.1

WORKDIR /opt/app

CMD cd /opt/app/server && lapis server
