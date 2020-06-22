#!/usr/bin/env bash

VARS=${1:-vars.env}

source <(sed -E -n 's/[^#]+/export &/ p' $VARS)

echo "Running Redis"

docker run --net=$NETWORK --name $REDIS_CONTAINER -d redis:$REDIS_TAG

echo "Running Elasticsearch"

docker run --name $ELASTIC_CONTAINER -d wikibase/elasticsearch:$ELASTIC_TAG

echo "Running MariaDB"

docker run --name $DB_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -e MYSQL_DATABASE=$MYSQL_DATABASE -e MYSQL_USER=$MYSQL_USER -e MYSQL_PASSWORD=$MYSQL_PASSWORD -v ${DB_LOCAL}:/var/lib/mysql -v $(pwd)/mariadb-custom.cnf:/etc/mysql/conf.d/custom.cnf -p $PORT_DB:3306 -d mariadb:$MARIADB_TAG
