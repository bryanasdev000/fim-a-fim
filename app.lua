#!/usr/bin/lua5.3

local driver = require 'luasql.firebird'
env = assert (driver.firebird())
con = assert (env:connect('localhost:/var/lib/firebird/3.0/data/luafirebird.fdb', 'app', 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J'))

cur = assert (con:execute'SELECT hashtag, content FROM twitter')
row = cur:fetch ({}, 'a')
while row do
        print (string.format('%s: %s', row.HASHTAG, row.CONTENT))
        row = cur:fetch ({}, 'a')
end
