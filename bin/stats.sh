#!/bin/sh

export DATABASE_URL="sqlite3:./db/stats.db" && ./svc_stats
