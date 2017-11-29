#!/bin/sh

export DATABASE_URL="sqlite3:./db/users.db" && ./svc_users > logs/svc_users.log &
export DATABASE_URL="sqlite3:./db/posts.db" && ./svc_posts > logs/svc_posts.log &
export DATABASE_URL="sqlite3:./db/comments.db" && ./svc_comments > logs/svc_comments.log &
./svc_gateway
