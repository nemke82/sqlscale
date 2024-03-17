#!/bin/bash

# Output header for JSON
echo '{ "nodes": ['

# Get list of Kubernetes node names
NODES=$(kubectl get nodes -o=jsonpath='{.items[*].metadata.name}')

# Initialize separator for JSON objects
sep=""

for NODE in $NODES; do
    echo "$sep {"
    echo "  \"name\": \"$NODE\","
    echo "  \"block_devices\": ["

    # Fetch unclaimed block devices for the node
    # Adjust the label selector as per your setup if needed
    BLOCK_DEVICES=$(kubectl get blockdevice -n openebs --selector='openebs.io/block-device-tag!=claimed, kubernetes.io/hostname='${NODE}'' -o=jsonpath='{.items[?(@.status.claimState=="Unclaimed")].metadata.name}')

    # Initialize separator for block devices array
    bd_sep=""

    for BD in $BLOCK_DEVICES; do
        echo "    $bd_sep\"$BD\""
        bd_sep=","
    done

    echo "  ]"
    echo -n "}"

    sep=","
done

# Output footer for JSON
echo ']}'
