local json = require('cjson')
local lapis = require("lapis")
local inspect = require("inspect")
local driver = require('luasql.firebird')
local config = require("lapis.config").get()

local app = lapis.Application()
app:enable('etlua')

local env = assert (driver.firebird())
local conn = assert (env:connect('localhost:/var/lib/firebird/3.0/data/luafirebird.fdb', 'app', 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'))
conn:setautocommit(true)

app:get("index", "/", function()
    return { render = true }
end)

app:get('/top_users', function()
    users = {}
    local cur = assert (conn:execute"SELECT FIRST 5 id, name, followers_count FROM users ORDER BY followers_count DESC")
    row = cur:fetch ({}, "n")
    while row do
        table.insert(users, {id=row[1], name=row[2], followers_count=row[3]})
        row = cur:fetch (row, "n")
    end
    return { json = users }
end)

app:get('/tweets_by_hour', function()
    tweets = {}
    local cur = assert (conn:execute"SELECT EXTRACT(HOUR FROM created_at) AS created_hour, COUNT(*) AS qtd FROM tweets GROUP BY created_hour")
    row = cur:fetch ({}, "n")
    while row do
        table.insert(tweets, {hour=row[1], count=row[2]})
        row = cur:fetch (row, "n")
    end
    return { json = tweets }
end)

app:get('/tweets_by_tag_and_location', function()
    tweets = {}
    local cur = assert (conn:execute"SELECT location, hashtag_id, COUNT(*) qtd FROM tweets_hashtags th JOIN tweets t ON th.tweet_id = t.id JOIN users u ON t.user_id = u.id WHERE th.hashtag_id = 'devops' GROUP BY hashtag_id, location ORDER BY hashtag_id, location")
    row = cur:fetch ({}, "n")
    while row do
        table.insert(tweets, {location=row[1], hashtag=row[2], count=row[3]})
        row = cur:fetch (row, "n")
    end
    return { json = tweets }
end)

app:get('/fetch', function()

    local date = require('date')
    local https = require("ssl.https")
    
    local twitter_key = assert (config.tw_key)
    local twitter_secret = assert (config.tw_secret)
    
    local b, c, h = https.request(string.format('http://%s:%s@api.twitter.com/oauth2/token', twitter_key, twitter_secret), 'grant_type=client_credentials')
    local token = json.decode(b)
   
    conn:execute('DELETE FROM tweets_hashtags')
    conn:execute('DELETE FROM hashtags')
    conn:execute('DELETE FROM tweets')
    conn:execute('DELETE FROM users')
    
    local hashtags = {'openbanking', 'apifirst', 'devops', 'cloudfirst', 'microservices', 'apigateway', 'oauth', 'swagger', 'raml', 'openapis'}
   
    for y, hashtag in pairs(hashtags) do
        print('https://api.twitter.com/1.1/search/tweets.json?q=%23' .. hashtag .. '&count=100&tweet_mode=extended')
        local res = {}
        local b, c, h = https.request {
            url = 'https://api.twitter.com/1.1/search/tweets.json?q=%23' .. hashtag .. '&count=100&tweet_mode=extended',
            sink = ltn12.sink.table(res),
            headers = {
                authorization = string.format('Bearer %s', token.access_token)
            }
        }
        
        local data = json.decode(table.concat(res))
        
        for i, tweet in pairs(data.statuses) do
            local user = tweet.user
            local status, msg = pcall(function()
                    res = assert (conn:execute(string.format([[
                            INSERT INTO users (id, name, screen_name, followers_count, location) VALUES (%u, '%s', '%s', %u, '%s')]], user.id, conn:escape(user.name), conn:escape(user.screen_name), user.followers_count, conn:escape(user.location))
                    ))
            end)
            local created_at = date(tweet.created_at)
            status, msg = pcall(function()
                    res = assert (conn:execute(string.format([[
                            INSERT INTO tweets (id, created_at, user_id, text) VALUES (%u, '%s', %u, '%s')]], tweet.id, created_at:fmt('%Y-%m-%d %H:%M:%S'), user.id, conn:escape(tweet.full_text))
                    ))
            end)
            local tags = tweet.entities.hashtags
            for x, tag in pairs(tags) do
                local tag_text = string.lower(tag.text)
                    status, msg = pcall(function()
                            res = assert (conn:execute(string.format([[
                                    INSERT INTO hashtags (id) VALUES ('%s')]], conn:escape(tag_text))
                            ))
                    end)
                status, msg = pcall(function()
                            res = assert (conn:execute(string.format([[
                                    INSERT INTO tweets_hashtags (tweet_id, hashtag_id) VALUES (%u, '%s')]], tweet.id, conn:escape(tag_text))
                            ))
                    end)
            end
        end
    end
end)

return app
