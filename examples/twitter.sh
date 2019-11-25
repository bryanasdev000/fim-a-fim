#!/bin/bash

# Defina TW_KEY e TW_SECRET antes de executar este script.
# Exemplo:
# export TW_KEY='key123'
# export TW_SECRET='secretabc'
# bash search.sh

set -x

### Adquire um token ###
BEARER_TOKEN="$(curl -s -u "$1:$2" --data 'grant_type=client_credentials' 'https://api.twitter.com/oauth2/token' | sed -En 's/.*access_token":(".*").*/\1/p' | tr -d '"')"

curl -v --url 'https://api.twitter.com/1.1/search/tweets.json?q=%23devops&result_type=recent' \
--header 'content-type: application/json' \
--header "authorization: Bearer $BEARER_TOKEN"

