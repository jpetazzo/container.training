#!/bin/bash

#http://www.apache.org/licenses/LICENSE-2.0.txt
#
#
#Copyright 2015 Intel Corporation
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

# add some color to the output
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

die () {
    echo >&2 "${red} $@ ${reset}"
    exit 1
}

# verify deps and the env
type docker-compose >/dev/null 2>&1 || die "Error: docker-compose is required"
type docker >/dev/null 2>&1 || die "Error: docker is required"
type netcat >/dev/null 2>&1 || die "Error: netcat is required"

#start containers
docker-compose up -d

echo -n "waiting for influxdb and grafana to start" 

host_ip=$(curl canihazip.com/s)
echo -n "host ip: ${host_ip}"

# wait for influxdb to start up
while ! curl --silent -G "http://${host_ip}:8086/query?u=admin&p=admin" --data-urlencode "q=SHOW DATABASES" 2>&1 > /dev/null ; do
  sleep 1
  echo -n "."
done
echo ""

# create snap database in influxdb
curl -G "http://${host_ip}:8086/ping"
echo -n ">>deleting snap influx db (if it exists) => "
curl -G "http://${host_ip}:8086/query?u=admin&p=admin" --data-urlencode "q=DROP DATABASE snap"
echo ""
echo -n "creating snap influx db => "
curl -G "http://${host_ip}:8086/query?u=admin&p=admin" --data-urlencode "q=CREATE DATABASE snap"
echo ""

# create influxdb datasource in grafana
echo -n "${green}adding influxdb datasource to grafana => ${reset}"
COOKIEJAR=$(mktemp)
curl -H 'Content-Type: application/json;charset=UTF-8' \
	--data-binary '{"user":"admin","email":"","password":"admin"}' \
    --cookie-jar "$COOKIEJAR" \
    "http://${host_ip}:3000/login"

curl --cookie "$COOKIEJAR" \
	-X POST \
	--silent \
	-H 'Content-Type: application/json;charset=UTF-8' \
	--data-binary "{\"name\":\"influx\",\"type\":\"influxdb\",\"url\":\"http://${host_ip}:8086\",\"access\":\"proxy\",\"database\":\"snap\",\"user\":\"admin\",\"password\":\"admin\"}" \
	"http://${host_ip}:3000/api/datasources"
echo ""

dashboard=$(cat grafana/dashboard.json)
curl --cookie "$COOKIEJAR" \
	-X POST \
	--silent \
	-H 'Content-Type: application/json;charset=UTF-8' \
	--data "$dashboard" \
	"http://${host_ip}:3000/api/dashboards/db"
echo ""

echo "${green}loading snap-plugin-collector-docker${reset}"
(snapctl plugin load /opt/snap/plugin/snap-plugin-collector-docker) || die "Error: failed to load docker plugin"

echo "${green}loading snap-plugin-publisher-influxdb${reset}"
(snapctl plugin load /opt/snap/plugin/snap-plugin-publisher-influxdb) || die "Error: failed to load influxdb plugin"

echo -n "${green}adding task${reset}"
TMPDIR=${TMPDIR:="/tmp"}
TASK="${TMPDIR}/snap-task-$$.json"
echo "$TASK"
cat docker-influxdb.json | sed s/HOST_IP/${host_ip}/ > $TASK
snapctl task create -t $TASK

echo ""${green}
echo "Influxdb UI       => http://${host_ip}:8083"
echo "Grafana Dashboard => http://${host_ip}:3000/dashboard/db/snap-dashboard"
echo ""
echo "Press enter to start viewing the snap.log${reset}"
read
tail -f /tmp/snap.out

