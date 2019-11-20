#!/bin/bash
set -x
### Adquire um token ###
BEARER_TOKEN="$(curl -s -u "$1:$2" --data 'grant_type=client_credentials' 'https://api.twitter.com/oauth2/token' | sed -En 's/.*access_token":(".*").*/\1/p' | tr -d '"')"

### Faz uma busca por hashtag no Twitter ###
curl --request POST \
  --url https://api.twitter.com/1.1/tweets/search/30day/Prod.json \
  --header 'authorization: Bearer '$BEARER_TOKEN'' \
  --header 'content-type: application/json' \
  --data '{
                "query":"from:TwitterDev lang:en",
                "maxResults": "100",
                "fromDate":"<YYYYMMDDHHmm>",
                "toDate":"<YYYYMMDDHHmm>"
                }'
