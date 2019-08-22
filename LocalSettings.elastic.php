<?php

# CirrusSearch
wfLoadExtension( 'Elastica' );
require_once "$IP/extensions/CirrusSearch/CirrusSearch.php";
$wgCirrusSearchServers = [ "$ELASTIC_HOST" ];
$wgSearchType = 'CirrusSearch';
$wgCirrusSearchExtraIndexSettings['index.mapping.total_fields.limit'] = 5000;
