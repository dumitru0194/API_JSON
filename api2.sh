#!/bin/bash

private_token="Sx7EMNvjiP-LHkEPUXb8"
base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
per_page=20
output_file="git3.json"

# Create or truncate the output file
> "$output_file"

# Make an initial request to get the X-Total-Pages header
response=$(curl --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&page=1&statistics=true")
total_pages=$(echo "$response" | grep -i 'X-Total-Pages' | cut -d ':' -f 2 | tr -d '[:space:]')

# Loop over the pages
for ((page=1; page <= total_pages; page++)); do
  response=$(curl --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&page=$page&statistics=true")

  # Append the data from the current page to the output file
  echo "$response" >> "$output_file"
done

echo "All pages processed. Total pages: $total_pages"
