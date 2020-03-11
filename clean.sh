#!/usr/bin/env bash
source .env
docker-compose down
docker-compose rm
docker network rm $NETWORK
