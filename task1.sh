#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path_to_accounts.csv"
    exit 1
fi

# Input and output file paths
input_file="$1"
output_file="accounts_new.csv"

# Header for the new CSV file
echo "id,location_id,name,title,email,department" > "$output_file"

# Temporary file to track emails
temp_file=$(mktemp)

# Function to handle quoted fields properly
handle_quotes() {
    local field="$1"
    echo "$field" | sed 's/^"\(.*\)"$/\1/' | sed 's/""/"/g'
}

# Read the input file and process each line
while IFS= read -r line; do
    # Skip the header line
    if [[ "$line" != id* ]]; then
        # Split fields, handling quotes and commas correctly
        id=$(echo "$line" | awk -F',' '{print $1}')
        location_id=$(echo "$line" | awk -F',' '{print $2}')
        name=$(handle_quotes "$(echo "$line" | awk -F',' '{print $3}')")
        title=$(handle_quotes "$(echo "$line" | awk -F',' '{print $4}')")
        email=$(handle_quotes "$(echo "$line" | awk -F',' '{print $5}')")
        department=$(handle_quotes "$(echo "$line" | awk -F',' '{print $6}')")

        # Format the name (capitalize first letter of each word)
        formatted_name=$(echo "$name" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')

        # Generate email
        first_letter=$(echo "$formatted_name" | cut -d' ' -f1 | cut -c1 | tr '[:upper:]' '[:lower:]')
        last_name=$(echo "$formatted_name" | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')
        email="${first_letter}${last_name}@abc.com"

        # If email already exists, append the location_id to it
        if grep -q "$email" "$temp_file"; then
            email="${first_letter}${last_name}${location_id}@abc.com"
        fi

        # Add the email to the temporary file for tracking
        echo "$email" >> "$temp_file"

        # Preserve the title with quotes if it contains commas
        if [[ "$title" =~ "," ]]; then
            title="\"${title}\""
        fi

        # Format department field
        formatted_department="${department//\"/}"

        # Write the updated line to the new CSV file
        if [ -n "$id" ] && [ -n "$name" ]; then
            echo "$id,$location_id,$formatted_name,$title,$email,$formatted_department" >> "$output_file"
        fi
    fi
done < <(tail -n +2 "$input_file")

# Remove the temporary file
rm "$temp_file"

echo "New CSV file created: $output_file"
