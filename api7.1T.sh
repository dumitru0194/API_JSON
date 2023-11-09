#!/bin/bash

private_token="Sx7EMNvjiP-LHkEPUXb8"
base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
per_page=100
page=1
output_file="git3_custom_full.json"
project_ids=()

# Create or truncate the output file
> "$output_file"

convert_bytes_to_human_readable() {
  local bytes=$1
  local -a suffix=('B' 'KB' 'MB' 'GB' 'TB')

  local i=0
  while ((bytes >= 1024 && i < 4)); do
    bytes=$(($bytes / 1024))
    ((i++))
  done

  echo "$bytes${suffix[i]}"
}

filter_unique_paths() {
  echo "$1" | tr ',' '\n' | tr '/' '\n' | awk '!a[$0]++'
}

# Collect project IDs
while true; do
  response=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&page=$page&statistics=true")
  total_projects=$(echo "$response" | jq length)

  if [ "$total_projects" -eq 0 ]; then
    break
  fi

  project_ids+=($(echo "$response" | jq -r '.[].id'))

  ((page++))
done

echo "Total projects to process: ${#project_ids[@]}"

# Create a custom JSON structure and store it in the output file
custom_json='['

for ((i=0; i<${#project_ids[@]}; i++)); do
  id=${project_ids[i]}
  echo "Processing data for project with ID: $id ($((i+1))/${#project_ids[@]})"

  project_data=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "http://internal.git.unifun.com/api/v4/projects/$id?statistics=true")
  project_name=$(echo "$project_data" | jq -r '.name')
  project_size_bytes=$(echo "$project_data" | jq -r '.statistics.repository_size')
  project_size_human_readable=$(convert_bytes_to_human_readable $project_size_bytes)

  custom_json+='{"id": '$id', "name": "'$project_name'", "repository_size_bytes": '$project_size_bytes', "repository_size_human_readable": "'$project_size_human_readable'", "recursive_tree": ['

  tree_response=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "http://internal.git.unifun.com/api/v4/projects/$id/repository/tree?recursive=true&per_page=$per_page")
  tree_paths=$(filter_unique_paths "$(echo "$tree_response" | jq -r '.[].path')")

  for path in $tree_paths; do
    custom_json+='"'$path'",'
  done

  # Remove the trailing comma in the recursive tree array
  custom_json="${custom_json%,}"
  custom_json+=']},'
done

# Remove the trailing comma and close the JSON array
custom_json="${custom_json%,}]"

# Write the custom JSON structure to the output file
echo "$custom_json" > "$output_file"

echo "Custom JSON data with recursive tree for all projects has been created and saved to $output_file."
