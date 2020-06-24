#!/usr/bin/env bash

VARS=${1:-vars.env}

source <(sed -E -n 's/[^#]+/export &/ p' $VARS)

bash wikibase-start-db.sh $VARS

docker network connect $NETWORK $DB_CONTAINER
docker network connect $NETWORK $ELASTIC_CONTAINER

bash wikibase-start-wiki.sh $VARS

