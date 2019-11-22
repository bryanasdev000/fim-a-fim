-- isql-fb -u app -p 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J' /var/lib/firebird/3.0/data/luafirebird.fdb

-- as SYSDBA
CREATE USER app PASSWORD 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J';

-- as APP
CREATE DATABASE '/var/lib/firebird/3.0/data/luafirebird.fdb';
CREATE TABLE tweets (id BIGINT NOT NULL PRIMARY KEY, created_at TIMESTAMP NOT NULL, user_id BIGINT NOT NULL, text VARCHAR(500) NOT NULL);
CREATE TABLE users (id BIGINT NOT NULL PRIMARY KEY, name VARCHAR(50) NOT NULL, followers_count INT NOT NULL, screen_name VARCHAR(50) NOT NULL, location VARCHAR(50) NOT NULL);
CREATE TABLE hashtags (id VARCHAR(20) NOT NULL PRIMARY KEY);
CREATE TABLE tweets_hashtags (tweet_id BIGINT NOT NULL, hashtag_id VARCHAR(20) NOT NULL);

ALTER TABLE tweets ADD CONSTRAINT fk_tweet_user FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_tweet FOREIGN KEY (tweet_id) REFERENCES tweets(id);
ALTER TABLE tweets_hashtags ADD CONSTRAINT fk_th_hashtag FOREIGN KEY (hashtag_id) REFERENCES hashtags(id);
