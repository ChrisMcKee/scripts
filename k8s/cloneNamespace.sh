#!/bin/bash

## Usage copy_namespace existing-namespace new-namespace

function copy_namespace() {
	source_namespace=$1
	target_namespace=$2

	# Ensure both source and target namespaces are provided
	if [ -z "$source_namespace" ] || [ -z "$target_namespace" ]; then
		echo "Usage: copy_namespace source_namespace target_namespace"
		return 1
	fi

	# Create new namespace
	kubectl create namespace "$target_namespace"

	# Define the list of Kubernetes objects to copy
	declare -a types=("secret" "ingress" "serviceaccount" "service" "deployment" "statefulset" "cronjob")

	# For each type, export the object from the source namespace and create it in the target namespace
	for type in "${types[@]}"; do
		# Get the list of object names for the current type
		objects=$(kubectl -n "$source_namespace" get "$type" -o jsonpath='{.items[*].metadata.name}')

		for object in $objects; do
			# If type is secret, skip Service Account Tokens
			if [ "$type" == "secret" ]; then
				secret_type=$(kubectl -n "$source_namespace" get "$type" "$object" -o jsonpath='{.type}')
				if [ "$secret_type" == "kubernetes.io/service-account-token" ]; then
				continue
				fi
			fi

			# Export the object without status and creationTimestamp fields
			kubectl -n "$source_namespace" get "$type" "$object" -o json |
				jq 'del(.status, .metadata.creationTimestamp)' |
				# Update the namespace field to target namespace
				jq --arg target_namespace "$target_namespace" '.metadata.namespace=$target_namespace' >tmp.json

			# Create the object in the target namespace from the exported json
			kubectl -n "$target_namespace" create -f tmp.json
		done
	done

	# Clean up the temporary file
	rm tmp.json
}
