local json = require('cjson')
local lapis = require("lapis")
local https = require("ssl.https")
local inspect = require("inspect")
local http = require('socket.http')
local driver = require('luasql.firebird')
local config = require("lapis.config").get()

local functions = require("functions")

local app = lapis.Application()
app:enable('etlua')

local env = nil
local conn = nil

app:before_filter(function(self)
	functions.push_graylog('INFO', 'Acceso ao endpoint ' .. self.req.parsed_url.path, 6)
	local status, msg = pcall(function()
		env = assert (driver.firebird())
		conn = assert (env:connect('localhost:/var/lib/firebird/3.0/data/luafirebird.fdb', 'app', 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'))
		conn:setautocommit(true)
	end)
	if not status then
	    functions.push_graylog('ERROR', msg, 3)
      self:write({ status = 500, json = {message='Impossível se conectar ao banco de dados'}})
	end
end)

app:get("index", "/", function()
    return { render = true, layout=false }
end)

app:get("/metrics", function()

    local socket = require('socket')
    local total_latency = socket.gettime()

    local graylog_dashboard = assert (config.graylog_dashboard)
    local graylog_widget = assert (config.graylog_widget)

    local start = socket.gettime()
    local b, c, h, s = http.request(string.format('http://admin:admin@localhost:9000/api/dashboards/%s/widgets/%s/value', graylog_dashboard, graylog_widget))
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
        functions.push_graylog('ERROR', string.format('%s - %s', url, c), 3)
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
        functions.push_graylog('ERROR', string.format('%s - %s', url, c), 3)
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
        functions.push_graylog('ERROR', string.format('%s - %s', url, c), 3)
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
            functions.push_graylog('ERROR', string.format('%s - %s', url, c), 3)
            return { status = 500, json = {message=c}}
        end
        
        local data = json.decode(table.concat(res))
        
        for i, tweet in pairs(data.statuses) do
            local user = tweet.user
            local query = string.format("INSERT INTO users (id, name, screen_name, followers_count, location) VALUES (%u, '%s', '%s', %u, '%s')",
                user.id, conn:escape(user.name), conn:escape(user.screen_name), user.followers_count, conn:escape(user.location))
            functions.insert(query, 188, conn)

            local created_at = date(tweet.created_at)
            query = string.format("INSERT INTO tweets (id, created_at, user_id, text) VALUES (%u, '%s', %u, '%s')", tweet.id, created_at:fmt('%Y-%m-%d %H:%M:%S'), user.id, conn:escape(tweet.full_text))
            functions.insert(query, 192, conn)
            
            local tags = tweet.entities.hashtags
            for x, tag in pairs(tags) do
                local tag_text = conn:escape(string.lower(tag.text))
                query = string.format("INSERT INTO hashtags (id) VALUES ('%s')", tag_text)
                functions.insert(query, 198, conn)
                query = string.format("INSERT INTO tweets_hashtags (tweet_id, hashtag_id) VALUES (%u, '%s')", tweet.id, tag_text)
                functions.insert(query, 200, conn)
            end
        end
    end
end)

return app
