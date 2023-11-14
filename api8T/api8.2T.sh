#!/bin/bash

private_token="Sx7EMNvjiP-LHkEPUXb8"
base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
per_page=20
output_file="api8.2T.json"
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

# Make a request for the projects
response=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&statistics=true")

# Extract project IDs and store them in the array
project_ids+=($(echo "$response" | jq -r '.[].id'))  # Process the first two projects

# Create a custom JSON structure and store it in the output file
custom_json='['

total_projects=${#project_ids[@]}
echo "Total projects to process: $total_projects"

for ((i = 0; i < total_projects; i++)); do
  id=${project_ids[i]}
  project_data=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "http://internal.git.unifun.com/api/v4/projects/$id?statistics=true")
  project_name=$(echo "$project_data" | jq -r '.name')
  project_size_human_readable=$(convert_bytes_to_human_readable $project_size_bytes)
  last_activity_at=$(echo "$project_data" | jq -r '.last_activity_at')

  custom_json+='{'
  custom_json+=$'\n'
  custom_json+    '"id": '$id','
  custom_json+    '"name": "'$project_name'",'
  custom_json+    '"last_activity_at": "'$(date -d "$last_activity_at" +"%Y-%m-%d %H:%M:%S")'",'
  custom_json+    '"repository_size_human_readable": "'$project_size_human_readable'",'

  # Remove the trailing comma in the recursive tree array
  custom_json="${custom_json%,}"
  custom_json+=$'\n'
  custom_json+    ']'
  custom_json+=$'\n'
  custom_json+='},'

  echo "Processing data for project with ID: $id ($((i + 1))/$total_projects)"
done

# Remove the trailing comma in the custom JSON array
custom_json="${custom_json%,}"
# Close the JSON array
custom_json+=$'\n'
custom_json+=']'

# Write the custom JSON structure to the output file
echo -e "$custom_json" > "$output_file"

echo "Custom JSON data with recursive tree for test projects has been created and saved to $output_file."
