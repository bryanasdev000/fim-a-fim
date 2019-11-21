#!/usr/bin/lua5.1

local json = require('cjson')
local ltn12 = require("ltn12")
local https = require("ssl.https")
local driver = require('luasql.firebird')
local inspect = require('inspect')

twitter_key = assert (os.getenv('TW_KEY'))
twitter_secret = assert (os.getenv('TW_SECRET'))

local b, c, h = https.request(string.format('http://%s:%s@api.twitter.com/oauth2/token', twitter_key, twitter_secret), 'grant_type=client_credentials')
local token = json.decode(b)

local res = {}
local b, c, h = https.request {
    url = 'https://api.twitter.com/1.1/search/tweets.json?q=%23devops&count=100',
    sink = ltn12.sink.table(res),
    headers = {
        authorization = string.format('Bearer %s', token.access_token)
    }
}
local data = json.decode(table.concat(res))
print(inspect(data.statuses[1].entities))
print(table.getn(data.statuses))

os.exit()

env = assert (driver.firebird())
con = assert (env:connect('localhost:/var/lib/firebird/3.0/data/luafirebird.fdb', 'app', 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'))

cur = assert (con:execute'SELECT hashtag, content FROM twitter')
row = cur:fetch ({}, 'a')
while row do
        print (string.format('%s: %s', row.HASHTAG, row.CONTENT))
        row = cur:fetch ({}, 'a')
end
