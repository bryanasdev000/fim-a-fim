#!/usr/bin/lua5.1

local json = require('cjson')
local ltn12 = require("ltn12")
local https = require("ssl.https")
local inspect = require('inspect')

twitter_key = assert (os.getenv('TW_KEY'))
twitter_secret = assert (os.getenv('TW_SECRET'))

local b, c, h = https.request(string.format('http://%s:%s@api.twitter.com/oauth2/token', twitter_key, twitter_secret), 'grant_type=client_credentials')
local token = json.decode(b)

local res = {}
local b, c, h = https.request {
    url = 'https://api.twitter.com/1.1/search/tweets.json?q=%23devops&count=100&tweet_mode=extended',
    sink = ltn12.sink.table(res),
    headers = {
        authorization = string.format('Bearer %s', token.access_token)
    }
}

local data = json.decode(table.concat(res))
print(inspect(data))
