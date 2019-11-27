#!/bin/bash

cd /var/lib/grafana/
gunzip grafana.db.gz
exec /run.sh
