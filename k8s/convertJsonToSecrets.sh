#!/bin/bash

# Function to convert JSON to YAML format
convert_json_to_yaml() {
	local json=$1
	local prefix=$2

	for key in $(jq -r "keys[]" <<<"$json"); do
		local value=$(jq -r ".[\"$key\"]" <<<"$json")

		# Check if the value is a nested JSON object
		if [[ $(jq -r ".[\"$key\"] | type" <<<"$json") == "object" ]]; then
			# Recursive call to handle nested JSON
			convert_json_to_yaml "$value" "${prefix}${key}__"
		else
			# Print the YAML formatted key-value pair
			echo "  ${prefix}${key}: $(echo -n $value | sed -e 's/True/true/' -e 's/False/false/' | base64 -w 0)"
		fi
	done
}

# Convert JSON to YAML format

# Main script execution
if [ $# -eq 0 ]; then
	echo "Usage: $0 <filename>"
	exit 1
fi

input_file=$1

# Check if file exists
if [ ! -f "$input_file" ]; then
	echo "File not found: $input_file"
	exit 1
fi

# Read JSON from file
input_json=$(cat "$input_file")

# Define the name of the Kubernetes Secret
SECRET_NAME=$2
NAMESPACE=$3

# Read the JSON configuration file and convert it to a Kubernetes Secret YAML
SECRET_YAML="apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: ${NAMESPACE}
data:"

# Output the Secret YAML to a file
echo "$SECRET_YAML" >"$SECRET_NAME-secret.tmp.yaml"
convert_json_to_yaml "$input_json" >>"$SECRET_NAME-secret.tmp.yaml"

echo "Kubernetes Secret YAML file '$SECRET_NAME-secret.tmp.yaml' created."
