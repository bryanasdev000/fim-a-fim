#!/bin/bash

echo > /dev/tcp/$FIREBIRD_HOST/3050
while [ "$?" != 0 ]; do
	echo 'Esperando o banco...'
	sleep 5
	echo > /dev/tcp/localhost/3050
done

lua /opt/app/migration.lua
exec openresty
