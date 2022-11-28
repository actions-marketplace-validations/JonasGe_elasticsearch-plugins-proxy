#!/bin/bash

set -euxo pipefail

if [[ -z $STACK_VERSION ]]; then
  echo -e "\033[31;1mERROR:\033[0m Required environment variable [STACK_VERSION] not set\033[0m"
  exit 1
fi

docker network create elastic

PLUGINS_STR=`echo ${PLUGINS} | sed -e 's/\n/ /g'`
MAJOR_VERSION=`echo ${STACK_VERSION} | cut -c 1`

PLUGIN_INSTALL_CMD=""

if [ "x${PLUGINS_STR}" != "x" ]; then
    ARRAY=(${PLUGINS_STR})
    for i in "${ARRAY[@]}"
    do
        PLUGIN_INSTALL_CMD+="elasticsearch-plugin install --batch ${i} && "
    done
fi

# single node only
if [ "x${MAJOR_VERSION}" == 'x6' ]; then
  docker run \
    --rm \
    --env "node.name=es1" \
    --env "cluster.name=docker-elasticsearch" \
    --env "cluster.routing.allocation.disk.threshold_enabled=false" \
    --env "bootstrap.memory_lock=true" \
    --env "ES_JAVA_OPTS=-Xms1g -Xmx1g -Dhttp.proxyHost=${http_proxy_host} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${http_proxy_host} -Dhttps.proxyPort=${http_proxy_port}" \
    --env "xpack.security.enabled=false" \
    --env "xpack.license.self_generated.type=basic" \
    --ulimit nofile=65536:65536 \
    --ulimit memlock=-1:-1 \
    --publish "9200:9200" \
    --detach \
    --network=elastic \
    --name="es1" \
    --entrypoint="" \
    docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION} \
    /bin/sh -vc "${PLUGIN_INSTALL_CMD} /usr/local/bin/docker-entrypoint.sh"
elif [ "x${MAJOR_VERSION}" == 'x7' ]; then
  docker run \
    --rm \
    --env "node.name=es1" \
    --env "cluster.name=docker-elasticsearch" \
    --env "cluster.initial_master_nodes=es1" \
    --env "discovery.seed_hosts=es1" \
    --env "cluster.routing.allocation.disk.threshold_enabled=false" \
    --env "bootstrap.memory_lock=true" \
    --env "ES_JAVA_OPTS=-Xms1g -Xmx1g -Dhttp.proxyHost=${http_proxy_host} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${http_proxy_host} -Dhttps.proxyPort=${http_proxy_port}" \
    --env "xpack.security.enabled=false" \
    --env "xpack.license.self_generated.type=basic" \
    --ulimit nofile=65536:65536 \
    --ulimit memlock=-1:-1 \
    --publish "9200:9200" \
    --detach \
    --network=elastic \
    --name="es1" \
    --entrypoint="" \
    docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION} \
    /bin/sh -vc "${PLUGIN_INSTALL_CMD} /usr/local/bin/docker-entrypoint.sh"
elif [ "x${MAJOR_VERSION}" == 'x8' ]; then
    if [ "${SECURITY_ENABLED}" == 'true' ]; then
      elasticsearch_password=${elasticsearch_password-'changeme'}
      docker run \
        --rm \
        --env "ELASTIC_PASSWORD=${elasticsearch_password}" \
        --env "xpack.license.self_generated.type=basic" \
        --env "node.name=es${node}" \
        --env "cluster.name=docker-elasticsearch" \
        --env "cluster.initial_master_nodes=es1" \
        --env "discovery.seed_hosts=es1" \
        --env "cluster.routing.allocation.disk.threshold_enabled=false" \
        --env "bootstrap.memory_lock=true" \
        --env "ES_JAVA_OPTS=-Xms1g -Xmx1g -Dhttp.proxyHost=${http_proxy_host} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${http_proxy_host} -Dhttps.proxyPort=${http_proxy_port}" \
        --env "http.port=${port}" \
        --env "action.destructive_requires_name=false" \
        --ulimit nofile=65536:65536 \
        --ulimit memlock=-1:-1 \
        --publish "${port}:${port}" \
        --network=elastic \
        --name="es${node}" \
        --detach \
        -v /es/plugins/:/usr/share/elasticsearch/plugins/ \
        docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    else
      docker run \
        --rm \
        --env "xpack.security.enabled=false" \
        --env "node.name=es${node}" \
        --env "cluster.name=docker-elasticsearch" \
        --env "cluster.initial_master_nodes=es1" \
        --env "discovery.seed_hosts=es1" \
        --env "cluster.routing.allocation.disk.threshold_enabled=false" \
        --env "bootstrap.memory_lock=true" \
        --env "ES_JAVA_OPTS=-Xms1g -Xmx1g -Dhttp.proxyHost=${http_proxy_host} -Dhttp.proxyPort=${http_proxy_port} -Dhttps.proxyHost=${http_proxy_host} -Dhttps.proxyPort=${http_proxy_port}" \
        --env "xpack.license.self_generated.type=basic" \
        --env "http.port=${port}" \
        --env "action.destructive_requires_name=false" \
        --ulimit nofile=65536:65536 \
        --ulimit memlock=-1:-1 \
        --publish "${port}:${port}" \
        --network=elastic \
        --name="es${node}" \
        --detach \
        -v /es/plugins/:/usr/share/elasticsearch/plugins/ \
        docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    fi
fi

docker run \
  --network elastic \
  --rm \
  appropriate/curl \
  --max-time 120 \
  --retry 120 \
  --retry-delay 1 \
  --retry-connrefused \
  --show-error \
  --silent \
  http://es1:9200

sleep 10

echo "Elasticsearch up and running"
