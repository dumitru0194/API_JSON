#!/bin/bash

private_token="Sx7EMNvjiP-LHkEPUXb8"
base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
per_page=20
page=1
output_file="git3.json"
project_ids=()

# Create or truncate the output file
> "$output_file"

while true; do
  # Make a request for the current page
  response=$(curl --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&page=$page&statistics=true")

  # Check if the response contains an empty JSON array
  if [ "$(echo "$response" | jq 'length')" -eq 0 ]; then
    echo "All pages processed. Page $((page - 1)) is the last page."
    break
  fi

  # Append the data from the current page to the output file
#  echo "$response" >> "$output_file"

  # Extract project IDs and store them in the array
  project_ids+=($(echo "$response" | jq -r '.[].id'))

  # Increment the page number for the next request
  ((page++))
done

# Print the project IDs
for id in "${project_ids[@]}"; do
  echo "Project ID: $id"
done
