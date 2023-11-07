#!/bin/bash

private_token="Sx7EMNvjiP-LHkEPUXb8"
base_url="http://internal.git.unifun.com/api/v4/groups/72/projects"
per_page=20
page=1
output_file="git3.json"

# Create or truncate the output file
> "$output_file"

# Create an empty JSON array to hold the combined data
combined_data="[]"

while true; do
  # Make a request for the current page
  response=$(curl --header "PRIVATE-TOKEN: $private_token" "$base_url?per_page=$per_page&page=$page&statistics=true")

  # Check if the response contains an empty JSON array
  if [ "$(echo "$response" | jq 'length')" -eq 0 ]; then
    echo "All pages processed. Page $((page - 1)) is the last page."
    break
  fi

  # Remove the square brackets from the combined_data
  combined_data="${combined_data:1:${#combined_data}-2}"

  # Append the data from the current page to the combined data
  combined_data="${combined_data},${response}"

  # Increment the page number for the next request
  ((page++))
done

# Add square brackets to the combined data to make it a valid JSON array
combined_data="[$combined_data]"

# Save the combined data to the output file
echo "$combined_data" > "$output_file"
