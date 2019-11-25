#!/bin/bash

curl \
	-X POST \
	-H 'Content-Type: application/json' \
	-d "{version='1.1', host='example.com', level=6, short_message='Mensagem curta', full_message='Uma grande mensagem qualquer, apenas para ser maior que a outra', _file='app.lua', _app='twitter_harvester'}" \
	'http://localhost:12201/gelf'
