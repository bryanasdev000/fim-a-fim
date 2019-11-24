#!/usr/bin/lua5.1

local http = require("socket.http")
local inspect = require('inspect')

local payload = string.format('{"version" : "1.1", "host" : "%s", "level" : "4", "short_message" : "Erro ao executar query", "full_message" : "%s", "line" : "93", "file" : "app.lua"}', 'example.com', 'Mensagem de teste da Lua')

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
