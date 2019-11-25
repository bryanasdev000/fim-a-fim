local json = require('cjson')
local lapis = require("lapis")
local https = require("ssl.https")
local inspect = require("inspect")
local http = require('socket.http')
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
    return { render = true, layout=false }
end)

app:get("/metrics", function()

    local socket = require('socket')
    local total_latency = socket.gettime()

    local start = socket.gettime()
    local b, c, h, s = http.request('http://admin:admin@localhost:9000/api/dashboards/5ddad80d58bdb33ff3c81d0d/widgets/e6bfa5b4-4229-4439-a45d-d8df73b532ca/value')
    local graylog = json.decode(b)
    if graylog.result.terms["3"] == nil then
        graylog.result.terms["3"] = 0
    end
    local finish = socket.gettime()
    local graylog_latency = finish - start

    local twitter_key = assert (config.tw_key)
    local twitter_secret = assert (config.tw_secret)

    start = socket.gettime()
    local url = 'https://%s:%s@api.twitter.com/oauth2/token'
    local b, c, h = https.request(string.format(url, twitter_key, twitter_secret), 'grant_type=client_credentials')
    if b == nil or c ~= 200 then
        push_graylog('ERROR', string.format('%s - %s', url, c), 3)
    end
    finish = socket.gettime()
    local twitter_token_latency = finish - start
    local token = json.decode(b)

    start = socket.gettime()
    local url = 'https://api.twitter.com/1.1/search/tweets.json?q=%23devops&count=1&tweet_mode=extended'
    local res = {}
    local b, c, h = https.request {
        url = url,
        sink = ltn12.sink.table(res),
        headers = {
            authorization = string.format('Bearer %s', token.access_token)
        }
    }
    finish = socket.gettime()
    local twitter_search_latency = finish - start
    if b == nil or c ~= 200 then
        push_graylog('ERROR', string.format('%s - %s', url, c), 3)
    end

    total_latency = socket.gettime() - total_latency
    local metrics = [[# HELP twitter_harverster_stats by type
# TYPE twitter_harvester_stats counter
twitter_harvester_stats{type="error"} %s
twitter_harvester_stats{type="warning"} %s
twitter_harvester_stats{type="access"} %s
# HELP twitter_harvester_latency shows latency of various internal calls
# TYPE twitter_harvester_latency gauge
twitter_harvester_latency{name="graylog"} %.3f
twitter_harvester_latency{name="twitter_token"} %.3f
twitter_harvester_latency{name="twitter_search"} %.3f
twitter_harvester_latency{name="api"} %.3f]]
    return { string.format(metrics,
        graylog.result.terms["3"],
        graylog.result.terms["4"],
        graylog.result.terms["6"],
        graylog_latency,
        twitter_token_latency,
        twitter_search_latency,
        total_latency),
        content_type='text',
        layout=false

    }
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
    
    local twitter_key = assert (config.tw_key)
    local twitter_secret = assert (config.tw_secret)
    
    local url = 'https://%s:%s@api.twitter.com/oauth2/token'
    local b, c, h = https.request(string.format(url, twitter_key, twitter_secret), 'grant_type=client_credentials')
    if b == nil or c ~= 200 then
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
        if b == nil or c ~= 200 then
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
    
    local status, msg = pcall(function()
        local res = assert (conn:execute(query))
    end)

    if not status then
        local level = 4
        if string.find(msg, 'PRIMARY or UNIQUE KEY') == nil and string.find(msg, 'attempt to store duplicate value') == nil then
            level = 3
        end
        local payload = json.encode({version='1.1', host=hostname, level=level, short_message='QUERY ERROR', full_message=msg, _line=line, _file='app.lua', _query=query, _app='twitter_harvester'})
        
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
    
    local payload = json.encode({version='1.1', host=hostname, level=level, short_message=short_message, full_message=full_message, _file='app.lua', _app='twitter_harvester'})
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
