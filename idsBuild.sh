#!/bin/bash

#
# This script is only intended to run in the IBM DevOps Services Pipeline Environment.
#

echo Informing slack...
curl -X 'POST' --silent --data-binary '{"text":"A new build for the gitbook has started."}' $WEBHOOK > /dev/null
mkdir dockercfg ; cd dockercfg
echo Downloading Docker requirements..
wget --user=admin --password=$ADMIN_PASSWORD https://$BUILD_DOCKER_HOST:8443/dockerneeds.tar -q
echo Setting up Docker...
wget http://security.ubuntu.com/ubuntu/pool/main/a/apparmor/libapparmor1_2.8.95~2430-0ubuntu5.3_amd64.deb -O libapparmor.deb
sudo dpkg -i libapparmor.deb
tar xzf dockerneeds.tar ; mv docker ../ ; cd .. ; chmod +x docker ; \
	export DOCKER_HOST="tcp://$BUILD_DOCKER_HOST:2376" DOCKER_TLS_VERIFY=1 DOCKER_CONFIG=./dockercfg

git submodule init ; git submodule sync

sed -i s/PLACEHOLDER_ADMIN_PASSWORD/$ADMIN_PASSWORD/g ./Dockerfile

./docker build -t gameon-docs .
./docker stop -t 0 gameon-docs
./docker rm gameon-docs
./docker run -d -p 4000:8080 -e LOGSTASH_ENDPOINT=$LOGSTASH_ENDPOINT -e LOGSTASH_CERT="$LOGSTASH_CERT" -e LOGSTASH_KEY="$LOGSTASH_KEY" --name gameon-docs gameon-docs
