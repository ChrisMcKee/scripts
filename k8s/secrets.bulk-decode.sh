#!/bin/bash

# Required YQ; replaces in-place

for file in *.yaml; do
    echo "Processing $file..."

    yq e '.data |= with_entries(.value |= @base64d)' "$file" > temp_file && mv temp_file "$file"
done

echo "Processing complete."
