local driver = require('luasql.firebird')

local env = assert (driver.firebird())
local uri = string.format('%s:%s', os.getenv('FIREBIRD_HOST'), os.getenv('FIREBIRD_DATABASE'))
local conn = assert (env:connect(uri, os.getenv('FIREBIRD_USER'), os.getenv('FIREBIRD_PASSWORD')))
conn:setautocommit(true)

ddl = {
"CREATE TABLE tweets (id BIGINT NOT NULL PRIMARY KEY, created_at TIMESTAMP NOT NULL, user_id BIGINT NOT NULL, text VARCHAR(500) NOT NULL)",
"CREATE TABLE users (id BIGINT NOT NULL PRIMARY KEY, name VARCHAR(100) NOT NULL, followers_count INT NOT NULL, screen_name VARCHAR(50) NOT NULL, location VARCHAR(100) NOT NULL)",
"CREATE TABLE hashtags (id VARCHAR(20) NOT NULL PRIMARY KEY)",
"CREATE TABLE tweets_hashtags (tweet_id BIGINT NOT NULL, hashtag_id VARCHAR(20) NOT NULL)",
"ALTER TABLE tweets ADD CONSTRAINT fk_tweet_user FOREIGN KEY (user_id) REFERENCES users(id)",
"ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_tweet FOREIGN KEY (tweet_id) REFERENCES tweets(id)",
"ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_hashtag FOREIGN KEY (hashtag_id) REFERENCES hashtags(id)"
}

local res = nil;
for i, query in pairs(ddl) do
	res =assert (conn:execute(query))
	if not res then
		print(res)
	end
end
