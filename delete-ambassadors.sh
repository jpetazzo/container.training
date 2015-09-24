#!/bin/sh
docker ps -q --filter label=ambassador.project=dockercoins | 
xargs docker rm -f
