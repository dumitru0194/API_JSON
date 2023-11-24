#!/bin/bash
# d.pintilie@unifun.com dmitri.sinitin@unifun.com
# set -x

# scripts base setup
declare -r DIR="$(dirname "$(readlink -f "$0")")"
declare -r BINARY=$DIR/"$(basename "$(readlink -f "$0")")"
declare -r CONFIG_DIR="${DIR}/.config"
declare -ar DEPS=(curl jq)

# script's variables
declare -r  available_hosts_file="${CONFIG_DIR}/all_hosts.txt"
declare -r  private_token="Sx7EMNvjiP-LHkEPUXb8"
declare -r  base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
declare -r  output_file="${CONFIG_DIR}/git3_custom_all.json"
declare  per_page=100
declare  page=1
declare -a project_ids=()

# Checking dependencies
for dep in ${DEPS[@]}; do
        type ${dep} &>/dev/null || { echo "Please, install ${dep}"; exit; }
        unset dep
done

# Update/Create Available Hosts File
mkdir -p ${CONFIG_DIR}
awk '{print $2}' /etc/ansible/hosts | grep -v '^$' | awk -F'=' '/ansible_host/{print $ 2}'  > ${available_hosts_file}

[[ $1 == 'get_hosts' ]] && { echo "${available_hosts_file}"; exit 0; }

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

# Create an array of available hosts from the file
available_hosts=()
while IFS= read -r line; do
  available_hosts+=("$line")
done < "$available_hosts_file"

# Make a request for all pages
while true; do
  # Make a request for the current page
  echo "Requesting current ${page} page" 1>&2
  response=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&page=$page&statistics=true")

  # Check if the response contains an empty JSON array
  if [ "$(echo "$response" | jq 'length')" -eq 0 ]; then
    echo "All pages processed. Page $((page - 1)) is the last page." 1>&2
    break
  fi

  # Extract project IDs and store them in the array
  project_ids+=($(echo "$response" | jq -r '.[].id'))

  # Increment the page number for the next request
  ((page++))
done

# Create a custom JSON structure and store it in the output file
custom_json='['

total_projects=${#project_ids[@]}
echo "Total projects to process: $total_projects" 2>/dev/null 1>&2

#for ((i = 0; i < 3; i++)); do

for ((i = 0; i < total_projects; i++)); do
  echo "Processing data for project with ID: $id ($((i + 1))/$total_projects)" 1>&2
  id=${project_ids[i]}
  project_data=$(curl --silent --header "PRIVATE-TOKEN: $private_token" "http://internal.git.unifun.com/api/v4/projects/$id?statistics=true")
  project_name=$(echo "$project_data" | jq -r '.name')
  project_size_bytes=$(echo "$project_data" | jq -r '.statistics.repository_size')
  project_size_human_readable=$(convert_bytes_to_human_readable $project_size_bytes)
  last_activity_at=$(echo "$project_data" | jq -r '.last_activity_at' | date -f - +"%Y-%m-%d")



  # Check if the project name exists in the available hosts array
  if [[ " ${available_hosts[*]} " == *"$project_name"* ]]; then
    host_exists="yes"
  else
    host_exists="no"
  fi

   # Check if the project name exists in the available hosts array
   if [[ "$(echo "$project_data" | jq -r '.description')" == "null" ]]; then
     description=""
   else
     description=$(echo "$project_data" | jq -r '.description')
   fi

  custom_json+='{"Hosts": "'$project_name'", "Repository_Size": "'$project_size_human_readable'", "last_activity": "'$last_activity_at'", "Host exists": "'$host_exists'", "Backup Description" : "'$description'"},'
done

# Remove the trailing comma in the custom JSON array
custom_json="${custom_json%,}"

# Close the JSON array
custom_json+=']'

# Write the custom JSON structure to the output file
echo "$custom_json" > "$output_file"
echo "Custom JSON data for all projects has been created and saved to ${output_file}" 1>&2
echo "${output_file}" 2>/dev/null
