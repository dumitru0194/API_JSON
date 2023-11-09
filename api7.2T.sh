#!/bin/bash

private_token="Sx7EMNvjiP-LHkEPUXb8"
base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
per_page=2
page=1
output_file="git3_custom_test.json"
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

# Function to fetch the recursive tree for a given project ID
fetch_recursive_tree() {
  local project_id=$1
  local page=1
  local tree_paths=()
  while true; do
    local tree_response=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "http://internal.git.unifun.com/api/v4/projects/$project_id/repository/tree?recursive=true&per_page=100&page=$page")
    local paths=($(echo "$tree_response" | jq -r '.[].path,.[].name'))

    # Check if there are no more pages
    if [ ${#paths[@]} -eq 0 ]; then
      break
    fi

    tree_paths+=("${paths[@]}")
    ((page++))
  done

  # Filter unique paths and files
  IFS=$'\n' sorted_tree_paths=($(sort -u <<<"${tree_paths[*]}"))
  unset IFS

  echo "${sorted_tree_paths[@]}"
}

# Make a request for the current page
response=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&page=$page&statistics=true")

# Extract project IDs and store them in the array
project_ids+=($(echo "$response" | jq -r '.[].id'))

# Create a custom JSON structure and store it in the output file
custom_json='['

total_projects=${#project_ids[@]}
echo "Total projects to process: $total_projects"

for ((i = 0; i < total_projects; i++)); do
  id=${project_ids[i]}
  project_data=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "http://internal.git.unifun.com/api/v4/projects/$id?statistics=true")
  project_name=$(echo "$project_data" | jq -r '.name')
  project_size_bytes=$(echo "$project_data" | jq -r '.statistics.repository_size')
  project_size_human_readable=$(convert_bytes_to_human_readable $project_size_bytes)
  last_activity_at=$(echo "$project_data" | jq -r '.last_activity_at')

  custom_json+='{"id": '$id', "name": "'$project_name'", "last_activity_at": "'$last_activity_at'", "repository_size_human_readable": "'$project_size_human_readable'", "recursive_tree": ['

  tree_paths=($(fetch_recursive_tree $id))

  for path in "${tree_paths[@]}"; do
    custom_json+='"'$path'",'
  done

  # Remove the trailing comma in the recursive tree array
  custom_json="${custom_json%,}"
  custom_json+=']},'

  echo "Processing data for project with ID: $id ($((i + 1))/$total_projects)"
done

# Remove the trailing comma in the custom JSON array
custom_json="${custom_json%,}"
# Close the JSON array
custom_json+=']'

# Write the custom JSON structure to the output file
echo "$custom_json" > "$output_file"

echo "Custom JSON data with recursive tree for one project has been created and saved to $output_file."
