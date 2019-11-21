#!/usr/bin/lua5.1

local json = require('cjson')
local ltn12 = require("ltn12")
local https = require("ssl.https")
local driver = require('luasql.firebird')
local inspect = require('inspect')
local date = require('date')

twitter_key = assert (os.getenv('TW_KEY'))
twitter_secret = assert (os.getenv('TW_SECRET'))

env = assert (driver.firebird())
firebird = assert (env:connect('localhost:/var/lib/firebird/3.0/data/luafirebird.fdb', 'app', 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'))
firebird:setautocommit(true)

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

for i, tweet in pairs(data.statuses) do
	local user = tweet.user
	local status, msg = pcall(function()
		res = assert (firebird:execute(string.format([[
			INSERT INTO users (id, name, screen_name, location) VALUES (%u, '%s', '%s', '%s')]], user.id, firebird:escape(user.name), firebird:escape(user.screen_name), firebird:escape(user.location))
		))
	end)
	local created_at = date(tweet.created_at)
	status, msg = pcall(function()
		res = assert (firebird:execute(string.format([[
			INSERT INTO tweets (id, created_at, user_id, text) VALUES (%u, '%s', %u, '%s')]], tweet.id, created_at:fmt('%Y-%m-%d %H:%M:%S'), user.id, firebird:escape(tweet.full_text))
		))
	end)
end

os.exit()

env = assert (driver.firebird())
con = assert (env:connect('localhost:/var/lib/firebird/3.0/data/luafirebird.fdb', 'app', 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'))

cur = assert (con:execute'SELECT hashtag, content FROM twitter')
row = cur:fetch ({}, 'a')
while row do
        print (string.format('%s: %s', row.HASHTAG, row.CONTENT))
        row = cur:fetch ({}, 'a')
end
