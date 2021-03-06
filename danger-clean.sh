#!/usr/bin/env bash

VARS=${1:-vars.env}

source <(sed -E -n 's/[^#]+/export &/ p' $VARS)

docker rm -f $DB_CONTAINER
docker rm -f $REDIS_CONTAINER
docker rm -f $PARSOID_CONTAINER
docker rm -f $WIKI_CONTAINER
docker rm -f $ELASTIC_CONTAINER
docker rm -f $WDQS_CONTAINER
docker rm -f $WDQSFE_CONTAINER
docker rm -f $WDQSPX_CONTAINER

docker network rm $NETWORK


