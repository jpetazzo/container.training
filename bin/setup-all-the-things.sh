#!/bin/sh
unset DOCKER_REGISTRY
unset DOCKER_HOST
unset COMPOSE_FILE

SWARM_IMAGE=${SWARM_IMAGE:-swarm:1.2.0}

prepare_1_check_ssh_keys () {
    for N in $(seq 1 5); do
        ssh node$N true
    done
}

prepare_2_compile_swarm () {
    cd ~
    git clone git://github.com/docker/swarm
    cd swarm
    [[ -z "$1" ]] && {
        echo "Specify which revision to build."
        return
    }
    git checkout "$1" || return
    mkdir -p image
    docker build -t docker/swarm:$1 .
    docker run -i --entrypoint sh docker/swarm:$1 \
         -c 'cat $(which swarm)' > image/swarm
    chmod +x image/swarm
    cat >image/Dockerfile <<EOF
FROM scratch
COPY ./swarm /swarm
ENTRYPOINT ["/swarm", "-debug", "-experimental"]
EOF
    docker build -t jpetazzo/swarm:$1 image
    docker login
    docker push jpetazzo/swarm:$1
    docker logout
    SWARM_IMAGE=jpetazzo/swarm:$1
}

clean_1_containers () {
    for N in $(seq 1 5); do
        ssh node$N "docker ps -aq | xargs -r -n1 -P10 docker rm -f"
    done
}

clean_2_volumes () {
    for N in $(seq 1 5); do
        ssh node$N "docker volume ls -q | xargs -r docker volume rm"
    done
}

clean_3_images () {
    for N in $(seq 1 5); do
        ssh node$N "docker images | awk '/dockercoins|jpetazzo/ {print \$1\":\"\$2}' | xargs -r docker rmi -f"
    done
}

clean_4_machines () {
    rm -rf ~/.docker/machine/
}

clean_all () {
    clean_1_containers
    clean_2_volumes
    clean_3_images
    clean_4_machines
}

dm_swarm () {
    eval $(docker-machine env node1 --swarm)
}
dm_node1 () {
    eval $(docker-machine env node1)
}

setup_1_swarm () {
    grep node[12345] /etc/hosts | grep -v ^127 |
    while read IPADDR NODENAME; do
      docker-machine create --driver generic \
        --engine-opt cluster-store=consul://localhost:8500 \
        --engine-opt cluster-advertise=eth0:2376 \
        --swarm --swarm-master --swarm-image $SWARM_IMAGE \
        --swarm-discovery consul://localhost:8500 \
        --swarm-opt replication --swarm-opt advertise=$IPADDR:3376 \
        --generic-ssh-user docker --generic-ip-address $IPADDR $NODENAME
    done
}

setup_2_consul () {
    ssh node1 docker run --name consul_node1 \
          -d --restart=always --net host \
          jpetazzo/consul agent -server -bootstrap

    IPADDR=$(ssh node1 ip a ls dev eth0 |
             sed -n 's,.*inet \(.*\)/.*,\1,p')

    # Start other Consul nodes
    for N in 2 3 4 5; do
    ssh node$N docker run --name consul_node$N \
               -d --restart=always --net host \
               jpetazzo/consul agent -server -join $IPADDR
    done
}

setup_3_wait () {
    # Wait for a Swarm master
    dm_swarm
    while ! docker ps; do sleep 1; done

    # Wait for all nodes to be there
    while ! [ "$(docker info | grep "^Nodes:")" = "Nodes: 5" ]; do sleep 1; done
}

setup_4_registry () {
    cd ~/orchestration-workshop/registry
    dm_swarm
    docker-compose up -d
    for N in $(seq 2 5); do
        docker-compose scale frontend=$N
    done
}

setup_5_btp_dockercoins () {
    cd ~/orchestration-workshop/dockercoins
    dm_node1
    export DOCKER_REGISTRY=localhost:5000
    cp docker-compose.yml-v2 docker-compose.yml
    ~/orchestration-workshop/bin/build-tag-push.py | tee /tmp/btp.log
    export $(tail -n 1 /tmp/btp.log)
}

setup_6_add_lbs () {
    cd ~/orchestration-workshop/dockercoins
    ~/orchestration-workshop/bin/add-load-balancer-v2.py rng
    ~/orchestration-workshop/bin/add-load-balancer-v2.py hasher
}

setup_all () {
    setup_1_swarm
    setup_2_consul
    setup_3_wait
    setup_4_registry
    setup_5_btp_dockercoins
    setup_6_add_lbs
    dm_swarm
}


force_remove_network () {
    dm_swarm
    NET="$1"
    for CNAME in $(docker network inspect $NET | grep Name | grep -v \"$NET\" | cut -d\" -f4); do
        echo $CNAME
        docker network disconnect -f $NET $CNAME
    done
    docker network rm $NET
}

demo_1_compose_up () {
    dm_swarm
    cd ~/orchestration-workshop/dockercoins
    docker-compose up -d
}

grep -qs -- MAGICMARKER "$0" && { # Don't display this line in the function lis
    echo "You should source this file, then invoke the following functions:"
    grep -- '^[a-z].*{$' "$0" | cut -d" " -f1
}
