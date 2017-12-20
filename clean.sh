#!/bin/sh

rm -rf lib .shards cov
rm -f shard.lock
rm -f ./gateway_spec ./users_spec ./posts_spec ./comments_spec
rm -f ./bin/logs/*
rm -f ./bin/svc_*
rm -f ./bin/frontend

