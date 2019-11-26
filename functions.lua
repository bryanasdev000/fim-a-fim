local json = require('cjson')
local https = require("ssl.https")
local http = require('socket.http')

local functions = {}
local cmd = io.popen('hostname -f')
functions.hostname = string.gsub(cmd:read("*a"), "%s+", "")

functions.insert = function(query, line, conn)
    
    local status, msg = pcall(function()
        local res = assert (conn:execute(query))
    end)

    if not status then
        local level = 4
        if string.find(msg, 'PRIMARY or UNIQUE KEY') == nil and string.find(msg, 'attempt to store duplicate value') == nil then
            level = 3
        end
        local payload = json.encode({version='1.1', host=functions.hostname, level=level, short_message='QUERY ERROR', full_message=msg, _line=line, _file='app.lua', _query=query, _app='twitter_harvester'})
        
        local b, c, h, s = http.request {
            url = string.format('http://%s:%s/%s', os.getenv('GRAYLOG_HOST'), os.getenv('GRAYLOG_PORT'), os.getenv('GRAYLOG_INPUT')),
            method = 'POST',
            source = ltn12.source.string(payload),
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = payload:len()
            }       
        }
    end
end

functions.push_graylog = function(short_message, full_message, level)
    
    local payload = json.encode({version='1.1', host=functions.hostname, level=level, short_message=short_message, full_message=full_message, _file='app.lua', _app='twitter_harvester'})
    local b, c, h, s = http.request {
        url = string.format('http://%s:%s/%s', os.getenv('GRAYLOG_HOST'), os.getenv('GRAYLOG_PORT'), os.getenv('GRAYLOG_INPUT')),
        method = 'POST',
        source = ltn12.source.string(payload),
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = payload:len()
        }       
    }
end

return functions
