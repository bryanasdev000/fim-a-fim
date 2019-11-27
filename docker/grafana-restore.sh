#!/bin/bash

cd /var/lib/grafana/
gunzip -k grafana.db.gz
exec /run.sh
