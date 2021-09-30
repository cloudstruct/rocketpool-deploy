#!/bin/bash
CONTAINER_NAME="rocketpool_eth1"
GETH_VERSION=$( docker exec -i $CONTAINER_NAME geth version | grep -Po "(?<=^Version: )[0-9\.]+" ) # See docker exec -i rocketpool_eth1 geth version
ETH1_DATA_VOLUME=$( docker inspect -f '{{ json .Mounts }}' $CONTAINER_NAME | jq -r '.[] | select(.Destination=="/ethclient").Source' )

fail() {
    MESSAGE=$1
    RED='\033[0;31m'
    COLOR_RESET='\033[0m'
    >&2 echo -e "${RED}**ERROR** - ${MESSAGE}${COLOR_RESET}"
    exit 1
}

start_geth() {
    echo "Starting geth..."
    docker start $CONTAINER_NAME || fail "Could not start $CONTAINER_NAME"
}

trap start_geth EXIT

echo "Stopping geth..."
docker stop $CONTAINER_NAME || fail "Could not stop $CONTAINER_NAME"

echo "Running the pruner..."
docker run --rm -v $ETH1_DATA_VOLUME:/ethclient ethereum/client-go:v$GETH_VERSION snapshot prune-state --goerli --datadir /ethclient/geth || fail "Failed to start pruning"
echo "Done pruning!"
