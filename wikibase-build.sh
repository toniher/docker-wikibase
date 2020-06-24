#!/usr/bin/env bash

VARS=${1:-vars.env}

source <(sed -E -n 's/[^#]+/export &/ p' $VARS)

docker network create --subnet=$NETWORK_SUBNET $NETWORK

bash wikibase-start-db.sh $VARS

bash wikibase-build-wiki.sh $VARS

docker network connect $NETWORK $DB_CONTAINER
docker network connect $NETWORK $ELASTIC_CONTAINER

bash wikibase-start-wiki.sh $VARS

