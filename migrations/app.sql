-- isql-fb -u sysdba -p firebird /var/lib/firebird/3.0/system/security3.fdb
-- CREATE USER app PASSWORD 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J';
-- isql-fb -u app -p app /var/lib/firebird/3.0/system/security3.fdb
-- isql-fb -u app -p 'zjgNmeaoENepyDaeq2*vs)x)kbNm8L2J' /var/lib/firebird/3.0/data/luafirebird.fdb
CREATE DATABASE IF NOT EXISTS '/var/lib/firebird/3.0/data/luafirebird.fdb'
CREATE TABLE twitter (hashtag VARCHAR(50) NOT NULL PRIMARY KEY, content VARCHAR(100));
