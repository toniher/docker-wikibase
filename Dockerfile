FROM toniher/nginx-php:nginx-1.16-php-7.3

ARG MEDIAWIKI_VERSION=1.31
ARG MEDIAWIKI_FULL_VERSION=1.31.6
ARG DB_CONTAINER=db
ARG ELASTIC_CONTAINER=elastic
ARG PARSOID_CONTAINER=parsoid
ARG MYSQL_HOST=127.0.0.1
ARG ELASTIC_HOST=127.0.0.1
ARG MYSQL_DATABASE=mediawiki
ARG MYSQL_USER=mediawiki
ARG MYSQL_PASSWORD=mediawiki
ARG MYSQL_PREFIX=mw_
ARG MW_PASSWORD=prova
ARG MW_SCRIPTPATH=/w
ARG MW_WIKILANG=en
ARG MW_WIKINAME=Test
ARG MW_WIKIUSER=WikiSysop
ARG MW_EMAIL=hello@localhost
ARG DOMAIN_NAME=localhost
ARG PROTOCOL=http://

# Forcing Invalidate cache
ARG CACHE_INSTALL=2016-11-01

RUN set -x; \
    apt-get update && apt-get -y upgrade;
RUN set -x; \
    apt-get install -y gnupg jq php-redis;
RUN set -x; \
    rm -rf /var/lib/apt/lists/*

# https://www.mediawiki.org/keys/keys.txt
RUN gpg --no-tty --fetch-keys "https://www.mediawiki.org/keys/keys.txt"

RUN MEDIAWIKI_DOWNLOAD_URL="https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_VERSION/mediawiki-$MEDIAWIKI_FULL_VERSION.tar.gz"; \
	set -x; \
	mkdir -p /var/www/w \
	&& curl -fSL "$MEDIAWIKI_DOWNLOAD_URL" -o mediawiki.tar.gz \
	&& curl -fSL "${MEDIAWIKI_DOWNLOAD_URL}.sig" -o mediawiki.tar.gz.sig \
	&& gpg --verify mediawiki.tar.gz.sig \
	&& tar -xf mediawiki.tar.gz -C /var/www/w --strip-components=1

COPY composer.local.json /var/www/w

RUN set -x; echo $MYSQL_HOST >> /tmp/startpath; cat /tmp/startpath

RUN set -x; echo "Host is $MYSQL_HOST"

COPY nginx-default.conf /etc/nginx/conf.d/default.conf
# Adding extra domain name
RUN sed -i "s/localhost/localhost $DOMAIN_NAME/" /etc/nginx/conf.d/default.conf

# Starting processes
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY LocalSettings.local.php /var/www/w

RUN cd /var/www/w; php maintenance/install.php \
		--dbname "$MYSQL_DATABASE" \
		--dbpass "$MYSQL_PASSWORD" \
		--dbserver "$MYSQL_HOST" \
		--dbtype mysql \
		--dbprefix "$MYSQL_PREFIX" \
		--dbuser "$MYSQL_USER" \
		--installdbpass "$MYSQL_PASSWORD" \
		--installdbuser "$MYSQL_USER" \
		--pass "$MW_PASSWORD" \
		--scriptpath "$MW_SCRIPTPATH" \
		--lang "$MW_WIKILANG" \
"${MW_WIKINAME}" "${MW_WIKIUSER}"

COPY download-extension.sh /usr/local/bin/

# Elastica extension
RUN ENVEXT=$MEDIAWIKI_VERSION && ENVEXT=$(echo $ENVEXT | sed -r "s/\./_/g") && bash /usr/local/bin/download-extension.sh Elastica $ENVEXT /var/www/w/extensions
# CirrusSearch extension
RUN ENVEXT=$MEDIAWIKI_VERSION && ENVEXT=$(echo $ENVEXT | sed -r "s/\./_/g") && bash /usr/local/bin/download-extension.sh CirrusSearch $ENVEXT /var/www/w/extensions
# VisualEditor extension
RUN ENVEXT=$MEDIAWIKI_VERSION && ENVEXT=$(echo $ENVEXT | sed -r "s/\./_/g") && bash /usr/local/bin/download-extension.sh VisualEditor $ENVEXT /var/www/w/extensions
# Wikibase extension
RUN ENVEXT=$MEDIAWIKI_VERSION && ENVEXT=$(echo $ENVEXT | sed -r "s/\./_/g") && bash /usr/local/bin/download-extension.sh Wikibase $ENVEXT /var/www/w/extensions

# WikibaseImprot
RUN cd /var/www/w/extensions; curl -fSL https://github.com/filbertkm/WikibaseImport/archive/master.tar.gz -o WikibaseImport.tar.gz \
    && mkdir -p /var/www/w/extensions/WikibaseImport \
    && tar -xf WikibaseImport.tar.gz -C /var/www/w/extensions/WikibaseImport --strip-components=1

RUN cd /var/www/w/extensions/WikibaseImport; composer update;

# Addding extra stuff to LocalSettings
RUN echo "\n\
include_once \"\$IP/LocalSettings.local.php\"; " >> /var/www/w/LocalSettings.php

RUN cd /var/www/w; composer update --no-dev;

RUN cd /var/www/w; php maintenance/update.php

RUN cd /var/www/w; php maintenance/runJobs.php

RUN mkdir -p /run/php

# Redis configuration
COPY LocalSettings.redis.php /var/www/w
RUN echo "\n\
include_once \"\$IP/LocalSettings.redis.php\"; " >> /var/www/w/LocalSettings.php

# Elastic configuration
COPY LocalSettings.elastic.php /var/www/w
RUN echo "\n\
include_once \"\$IP/LocalSettings.elastic.php\"; " >> /var/www/w/LocalSettings.php

# Elastica maintenance scripts
RUN sed -i "s/\$ELASTIC_HOST/$ELASTIC_HOST/" /var/www/w/LocalSettings.elastic.php 

RUN cd /var/www/w/extensions/CirrusSearch/maintenance; php updateSearchIndexConfig.php; php forceSearchIndex.php --skipParse; php forceSearchIndex.php --skipLinks --indexOnSkip

RUN sed -i "s/$MYSQL_HOST/$DB_CONTAINER/" /var/www/w/LocalSettings.php 
RUN sed -i "s/$ELASTIC_HOST/$ELASTIC_CONTAINER/" /var/www/w/LocalSettings.elastic.php 

# Changing owner
RUN chown -R www-data:www-data /var/www/w

# VOLUME image
VOLUME /var/www/w/images

CMD ["/usr/bin/supervisord"]


