#!/bin/sh

[ -e lib ] || crystal deps

export KEMAL_ENV=test
export DATABASE_URL=sqlite3:./spec/test.db

cp ./spec/test.db ./spec/test.db.bak

crystal spec -v spec/users_spec.cr
crystal spec -v spec/posts_spec.cr
crystal spec -v spec/comments_spec.cr
crystal spec -v spec/gateway_spec.cr

mv ./spec/test.db.bak ./spec/test.db
