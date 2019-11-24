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

local cmd = io.popen('hostname -f')
local hostname = string.gsub(cmd:read("*a"), "%s+", "")

app:before_filter(function(self)
    push_graylog('INFO', 'Acceso ao endpoint ' .. self.req.parsed_url.path, 6)
end)

app:get("index", "/", function()
    return { render = true }
end)

app:get('/top_users', function()

    local users = {}
    local cur = assert (conn:execute"SELECT FIRST 5 id, name, followers_count FROM users ORDER BY followers_count DESC")
    local row = cur:fetch ({}, "n")
    while row do
        table.insert(users, {id=row[1], name=row[2], followers_count=row[3]})
        row = cur:fetch (row, "n")
    end
    return { json = users }
end)

app:get('/tweets_by_hour', function()
    
    local tweets = {}
    local cur = assert (conn:execute"SELECT EXTRACT(HOUR FROM created_at) AS created_hour, COUNT(*) AS qtd FROM tweets GROUP BY created_hour")
    local row = cur:fetch ({}, "n")
    while row do
        table.insert(tweets, {hour=string.format('%02u:00', row[1]), count=row[2]})
        row = cur:fetch (row, "n")
    end
    return { json = tweets }
end)

app:get('/tweets_by_tag_and_location', function()
    
    local tweets = {}
    local cur = assert (conn:execute"SELECT location, hashtag_id, COUNT(*) qtd FROM tweets_hashtags th JOIN tweets t ON th.tweet_id = t.id JOIN users u ON t.user_id = u.id WHERE th.hashtag_id IN ('openbanking', 'apifirst', 'devops', 'cloudfirst', 'microservices', 'apigateway', 'oauth', 'swagger', 'raml', 'openapis') GROUP BY hashtag_id, location ORDER BY hashtag_id, location")
    local row = cur:fetch ({}, "n")
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
    
    local url = 'https://%s:%s@api.twitter.com/oauth2/token'
    local b, c, h = https.request(string.format(url, twitter_key, twitter_secret), 'grant_type=client_credentials')
    if b == nil then
        push_graylog('ERROR', string.format('%s - %s', url, c), 3)
        return { status = 500, json = {message=c}}
    end
    local token = json.decode(b)
   
    conn:execute('DELETE FROM tweets_hashtags')
    conn:execute('DELETE FROM hashtags')
    conn:execute('DELETE FROM tweets')
    conn:execute('DELETE FROM users')
    
    local hashtags = {'openbanking', 'apifirst', 'devops', 'cloudfirst', 'microservices', 'apigateway', 'oauth', 'swagger', 'raml', 'openapis'}
   
    for y, hashtag in pairs(hashtags) do
        url = 'https://api.twitter.com/1.1/search/tweets.json?q=%23' .. hashtag .. '&count=100&tweet_mode=extended'
        local res = {}
        local b, c, h = https.request {
            url = url,
            sink = ltn12.sink.table(res),
            headers = {
                authorization = string.format('Bearer %s', token.access_token)
            }
        }
        if b == nil then
            push_graylog('ERROR', string.format('%s - %s', url, c), 3)
            return { status = 500, json = {message=c}}
        end
        
        local data = json.decode(table.concat(res))
        
        for i, tweet in pairs(data.statuses) do
            local user = tweet.user
            local query = string.format("INSERT INTO users (id, name, screen_name, followers_count, location) VALUES (%u, '%s', '%s', %u, '%s')",
                user.id, conn:escape(user.name), conn:escape(user.screen_name), user.followers_count, conn:escape(user.location))
            insert(query, 105)

            local created_at = date(tweet.created_at)
            query = string.format("INSERT INTO tweets (id, created_at, user_id, text) VALUES (%u, '%s', %u, '%s')", tweet.id, created_at:fmt('%Y-%m-%d %H:%M:%S'), user.id, conn:escape(tweet.full_text))
            insert(query, 109)
            
            local tags = tweet.entities.hashtags
            for x, tag in pairs(tags) do
                local tag_text = conn:escape(string.lower(tag.text))
                query = string.format("INSERT INTO hashtags (id) VALUES ('%s')", tag_text)
                insert(query, 115)
                query = string.format("INSERT INTO tweets_hashtags (tweet_id, hashtag_id) VALUES (%u, '%s')", tweet.id, tag_text)
                insert(query, 117)
            end
        end
    end
end)

function insert(query, line)
    
    local http = require('socket.http')
    
    local status, msg = pcall(function()
        local res = assert (conn:execute(query))
    end)

    if not status then
        local level = 4
        if string.find(msg, 'PRIMARY or UNIQUE KEY') == nil and string.find(msg, 'attempt to store duplicate value') == nil then
            level = 3
        end
        local payload = json.encode({version='1.1', host=hostname, level=level, short_message='QUERY ERROR', full_message=msg, _line=line, _file='app.lua', _query=query})
        
        local b, c, h, s = http.request {
            url = 'http://localhost:12201/gelf',
            method = 'POST',
            source = ltn12.source.string(payload),
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = payload:len()
            }       
        }
    end
end

function push_graylog(short_message, full_message, level)
    
    local payload = json.encode({version='1.1', host=hostname, level=level, short_message=short_message, full_message=full_message, _file='app.lua'})
    local http = require('socket.http')
    local b, c, h, s = http.request {
        url = 'http://localhost:12201/gelf',
        method = 'POST',
        source = ltn12.source.string(payload),
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = payload:len()
        }       
    }
end

return app
