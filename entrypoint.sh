#!/bin/bash

set -e

# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- elasticsearch "$@"
fi

# Drop root privileges if we are running elasticsearch
# allow the container to be started with `--user`
if [ "$1" = 'elasticsearch' -a "$(id -u)" = '0' ]; then
	# Change the ownership of user-mutable directories to elasticsearch
	for path in \
		/usr/share/elasticsearch/data \
		/usr/share/elasticsearch/logs \
	; do
		chown -R elasticsearch:elasticsearch "$path"
	done
	
	set -- gosu elasticsearch "$@"
fi

# Launch elasticsearch as daemon process and with custom pid
elasticsearch -p /tmp/elasticsearch-pid -d

# Wait for ES to be started
until /wait-for-it/wait-for-it.sh --host=localhost --port=9200 --timeout=5 --quiet; do
    >&2 echo "Connection not available for Elasticsearch on localhost:9200 - waiting 5 seconds"
done

# Populate searchguard index with demo roles and credentials
sh sgadmin_demo.sh

# Kill elasticsearch daemon
kill -SIGTERM $(cat /tmp/elasticsearch-pid && echo)

# Add correct config to elasticsearch file
sed -i 's/searchguard.ssl.http.enabled: true/searchguard.ssl.http.enabled: false/g' /usr/share/elasticsearch/config/elasticsearch.yml
echo "searchguard.ssl.transport.resolve_hostname: false" >> /usr/share/elasticsearch/config/elasticsearch.yml

# Start elasticsearch in foreground
elasticsearch
