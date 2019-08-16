#!/usr/bin/env bash

source <(sed -E -n 's/[^#]+/export &/ p' vars.env)

docker network create $NETWORK

bash wikibase-start-db.sh

bash wikibase-build-wiki.sh

docker network connect $NETWORK $MARIADB_CONTAINER

bash wikibase-start-wiki.sh

