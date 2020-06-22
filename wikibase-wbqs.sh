#!/usr/bin/env bash

VARS=${1:-vars.env}

source <(sed -E -n 's/[^#]+/export &/ p' $VARS)

# Config here: https://github.com/wmde/wikibase-docker/tree/master/wdqs
docker run -e WDQS_ENTITY_NAMESPACES="$WDQS_NS" -e WIKIBASE_HOST="$WIKI_CONTAINER" -e WDQS_HOST="$WDQS_CONTAINER" -e WDQS_PORT="$WDQS_PORT" --net=$NETWORK --name $WDQS_CONTAINER -d wikibase/wdqs:$WDQS_TAG /runBlazegraph.sh 

docker run -e WDQS_ENTITY_NAMESPACES="$WDQS_NS" -e WIKIBASE_HOST="$WIKI_CONTAINER" -e WDQS_HOST="$WDQS_CONTAINER" -e WDQS_PORT="$WDQS_PORT" --net=$NETWORK --name $WDQS_CONTAINER-updater -d wikibase/wdqs:$WDQS_TAG /runUpdate.sh

# Config here https://github.com/wmde/wikibase-docker/tree/master/wdqs-frontend
docker run -e WDQS_HOST="$WDQSPX_CONTAINER" -e WIKIBASE_HOST="$WIKI_CONTAINER" -e BRAND_TITLE="$WDQS_TITLE" -e LANGUAGE="$LANGUAGE" --net=$NETWORK -p $WDQSFE_PORT:80 --name $WDQSFE_CONTAINER -d wikibase/wdqs-frontend:$WDQSFE_TAG

# Config here https://github.com/wmde/wikibase-docker/tree/master/wdqs-proxy
docker run -e PROXY_PASS_HOST="$WDQS_CONTAINER:$WDQS_PORT" --net=$NETWORK -p $WDQSPX_PORT:80 --name $WDQSPX_CONTAINER -d wikibase/wdqs-proxy:$WDQSPX_TAG

