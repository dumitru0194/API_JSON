#!/bin/bash

private_token="Sx7EMNvjiP-LHkEPUXb8"
base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
per_page=20
page=1
output_file="git3_custom.json"
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

  # Extract project IDs and store them in the array
  project_ids+=($(echo "$response" | jq -r '.[].id'))

  # Increment the page number for the next request
  ((page++))
done

# Create a custom JSON structure and store it in the output file
custom_json='['

for id in "${project_ids[@]}"; do
  project_data=$(curl --header "PRIVATE-TOKEN: $private_token" "http://internal.git.unifun.com/api/v4/projects/$id?statistics=true")
  project_name=$(echo "$project_data" | jq -r '.name')
  project_size=$(echo "$project_data" | jq -r '.statistics.repository_size')

  custom_json+='{"id": '$id', "name": "'$project_name'", "repository_size": "'$project_size'"},'
done

# Remove the trailing comma and close the JSON array
custom_json="${custom_json%,}]"

# Write the custom JSON structure to the output file
echo "$custom_json" > "$output_file"

echo "Custom JSON data has been created and saved to $output_file."
