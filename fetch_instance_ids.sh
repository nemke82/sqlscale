#!/bin/bash

# Fetch all node names
NODE_NAMES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

# Initialize an empty array to store instance data
INSTANCES=()

# Iterate over each node name to fetch the corresponding instance ID and availability zone
for NODE_NAME in $NODE_NAMES; do
    # Fetch instance ID and availability zone for the current node
    INSTANCE_INFO=$(aws ec2 describe-instances \
        --filters "Name=private-dns-name,Values=${NODE_NAME}" \
        --query 'Reservations[*].Instances[*].[InstanceId, Placement.AvailabilityZone]' \
        --output json)
    
    # Extract instance ID and availability zone from the output
    INSTANCE_ID=$(echo "$INSTANCE_INFO" | jq -r '.[0][0][0]')
    AVAILABILITY_ZONE=$(echo "$INSTANCE_INFO" | jq -r '.[0][0][1]')
    
    # Skip if no instance ID was found
    if [ -z "$INSTANCE_ID" ]; then
        continue
    fi

    # Append instance data to the array
    INSTANCES+=("{\"id\":\"$INSTANCE_ID\",\"availability_zone\":\"$AVAILABILITY_ZONE\"}")
done

# Check if no instances were found
if [ ${#INSTANCES[@]} -eq 0 ]; then
    echo "{\"instances\":\"[]\"}"
    exit 0
fi

# Convert the array to a JSON string
INSTANCES_JSON=$(IFS=, ; echo "[${INSTANCES[*]}]")

# Encode the instances data as a JSON string to ensure it's a flat structure
ENCODED_INSTANCES_JSON=$(echo "$INSTANCES_JSON" | jq -c @json)

# Output the instance data as a JSON object with a string value
echo "{\"instances\":$ENCODED_INSTANCES_JSON}"
