#!/usr/bin/env bash

source <(sed -E -n 's/[^#]+/export &/ p' vars.env)

echo "Running wiki"

docker run --net=$NETWORK -p $PORT:80 -v ${MW_IMAGES}:/var/www/w/images --name $WIKI_CONTAINER --network-alias=$DOMAIN_NAME -d wikibase

echo "Running parsoid"

docker run --net=$NETWORK --name $PARSOID_CONTAINER -d -p 8142:8000 \
        -e PARSOID_DOMAIN_localhost=http://localhost/w/api.php \
        -e PARSOID_DOMAIN_localhost=http://$WIKI_CONTAINER/w/api.php \
        -e PARSOID_DOMAIN_localhost=http://$DOMAIN_NAME/w/api.php \
        thenets/parsoid:$PARSOID_TAG

