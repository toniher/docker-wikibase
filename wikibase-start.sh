#!/usr/bin/env bash

source <(sed -E -n 's/[^#]+/export &/ p' vars.env)

bash wikibase-start-db.sh

bash wikibase-start-wiki.sh

