#!/bin/bash

# Step 1: Extract block device name and node name from kubectl output
kubectl get bd -o wide -n openebs | awk 'NR>1 {print $1, $2}' > temp_bd_mapping.txt

# Step 2: Convert the extracted data to JSON, grouping by node
python3 -c '
import json
from collections import defaultdict

# Initialize a defaultdict to hold the mapping
bd_mapping_by_node = defaultdict(list)

# Read the temp file
with open("temp_bd_mapping.txt") as file:
    lines = file.readlines()
    # Aggregate block devices by node
    for line in lines:
        parts = line.split()
        bd_mapping_by_node[parts[1].strip()].append(parts[0])

# Prepare the final structure
nodes = [{"name": node, "block_devices": bds} for node, bds in bd_mapping_by_node.items()]

# Write to a JSON file
with open("nodes.json", "w") as json_file:
    json.dump(nodes, json_file, indent=4)
'

# Clean up the temporary file
rm temp_bd_mapping.txt

echo 'nodes.json has been updated.'
