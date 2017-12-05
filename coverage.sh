#!/bin/sh

[ -e cov ] && rm -r cov
[ -e lib ] || crystal deps

mkdir cov
mkdir cov/{users,posts,comments,gateway,all}

cp ./spec/test.db ./spec/test.db.bak

export KEMAL_ENV=test
export DATABASE_URL=sqlite3:./spec/test.db

crystal build --debug spec/users_spec.cr &&
kcov \
--include-pattern=src/svc \
cov/users ./users_spec

crystal build --debug spec/posts_spec.cr &&
kcov \
--include-pattern=src/svc \
cov/posts ./posts_spec

crystal build --debug spec/comments_spec.cr &&
kcov \
--include-pattern=src/svc \
cov/comments ./comments_spec

crystal build --debug spec/gateway_spec.cr &&
kcov \
--include-pattern=src/svc \
cov/gateway ./gateway_spec

kcov --merge cov/all cov/users cov/posts cov/comments cov/gateway

mv ./spec/test.db.bak ./spec/test.db

rm ./gateway_spec ./users_spec ./posts_spec ./comments_spec
