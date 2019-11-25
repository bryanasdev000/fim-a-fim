#!/usr/bin/lua5.1

local http = require("socket.http")
local inspect = require('inspect')

local payload = json.encode({version='1.1', host='example.com', level=6, short_message='Mensagem curta', full_message='Uma grande mensagem qualquer, apenas para ser maior que a outra', _file='app.lua', _app='twitter_harvester'})

local b, c, h, s = http.request {
    url = 'http://localhost:12201/gelf',
    method = 'POST',
    source = ltn12.source.string(payload),
    headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = payload:len()
    }
}

print(b)
print(c)
print(h)
print(s)
