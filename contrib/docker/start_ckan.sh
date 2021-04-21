#!/bin/bash

echo "Loading the following plugins: $CKAN__PLUGINS"
ckan config-tool "${CKAN_CONFIG}/production.ini" "ckan.plugins = $CKAN__PLUGINS"
ckan --config "${CKAN_CONFIG}/production.ini" db init

echo "Starting CKAN"

ckan -c ${CKAN_CONFIG}/production.ini run --host 0.0.0.0