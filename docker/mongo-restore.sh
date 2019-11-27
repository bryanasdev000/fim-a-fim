#!/bin/bash

tar -xzf /tmp/mongo-graylog.tar.gz -C /tmp
cd /tmp
mongorestore
