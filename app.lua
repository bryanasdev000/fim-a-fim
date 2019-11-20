#!/usr/bin/lua5.3

twitter_key = assert (os.getenv('TW_KEY'))
twitter_secret = assert (os.getenv('TW_SECRET'))

local https = require("ssl.https")
local b, c, h = https.request(string.format('http://%s:%s@api.twitter.com/oauth2/token', twitter_key, twitter_secret), 'grant_type=client_credentials')
local json = require('cjson')
local token = json.decode(b)

print(token.access_token)

local b, c, h = https.request {
    url = 'https://api.twitter.com/1.1/tweets/search/30day/Prod.json',
    headers = {
        authorization = string.format('Bearer %s', token.access_token),
        content_type = 'application/json',
        body = [[{
                "query":"from:TwitterDev lang:en",
                "maxResults": "100",
                "fromDate":"<YYYYMMDDHHmm>",
                "toDate":"<YYYYMMDDHHmm>"
                }]]
    }
}
print(b, c, h)

os.exit()

local driver = require 'luasql.firebird'
env = assert (driver.firebird())
con = assert (env:connect('localhost:/var/lib/firebird/3.0/data/luafirebird.fdb', 'app', 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'))

cur = assert (con:execute'SELECT hashtag, content FROM twitter')
row = cur:fetch ({}, 'a')
while row do
        print (string.format('%s: %s', row.HASHTAG, row.CONTENT))
        row = cur:fetch ({}, 'a')
end
