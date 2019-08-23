#!/usr/bin/env bash

source <(sed -E -n 's/[^#]+/export &/ p' vars.env)

bash wikibase-start-db.sh

docker network connect $NETWORK $MARIADB_CONTAINER
docker network connect $NETWORK $ELASTIC_CONTAINER

bash wikibase-start-wiki.sh

