#!/bin/bash

echo "Start of the process"

# Check if an argument is provided for the input file
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 path/to/accounts.csv"
  exit 1
fi

# Input and output file paths
input_file="$1"
output_file="accounts_new.csv"
temp_file="temp_emails.txt"
reference_file="reference_accounts.csv"

# Header for the new CSV file
echo "id,location_id,name,title,email,department" > "$output_file"

# Clear the temporary file
> "$temp_file"

# Initialize an associative array to track generated emails
declare -A email_map
declare -A duplicate_email_tracker

awk -F, '
BEGIN {
    OFS=","  # Output field separator
    FPAT="([^,]+)|(\"[^\"]+\")"  # Field pattern to handle quoted fields
}

function format_name(name) {
    gsub(/^"|"$/, "", name)  # Remove leading/trailing quotes
    gsub(/^ +| +$/, "", name)  # Remove leading/trailing spaces
    split(name, parts, " ")  # Split name into words
    for (i=1; i<=length(parts); i++) {
        parts[i] = toupper(substr(parts[i], 1, 1)) tolower(substr(parts[i], 2))  # Capitalize each word
    }
    return join(parts, " ")
}

function join(arr, delim) {
    result = arr[1]
    for (i=2; i<=length(arr); i++) {
        result = result delim arr[i]
    }
    return result
}

function generate_email(first_name, last_name, location_id) {
    first = tolower(substr(first_name, 1, 1))
    last = tolower(last_name)
    gsub(/[^a-z0-9-]/, "", last)  # Allow only lowercase letters, numbers, and hyphens in the last name

    new_email = first last "@abc.com"

    # Track duplicate emails and append location_id for duplicates
    if (new_email in email_map) {
        duplicate_email_tracker[new_email]++
        return first last location_id "@abc.com"
    } else {
        email_map[new_email] = 1
        duplicate_email_tracker[new_email] = 1
    }

    return new_email
}

function update_existing_email(first_name, last_name, location_id) {
    return generate_email(first_name, last_name, location_id)
}

NR == 1 {next}  # Skip header row

{
    id = $1
    location_id = $2
    name = format_name($3)
    title = $4
    email = $5
    department = $6

    # Split full name into first and last
    split(name, name_parts, " ")
    first_name = name_parts[1]
    last_name = name_parts[length(name_parts)]

    # Ensure last name has hyphens intact and capitalized
    gsub(/[^a-zA-Z0-9-]/, "", last_name)
    last_name = toupper(substr(last_name, 1, 1)) tolower(substr(last_name, 2))

    # Generate email, whether or not one exists in the original file
    email = update_existing_email(first_name, last_name, location_id)

    # Enclose the title with quotes if it contains commas
    if (title ~ /,/) {
        title = "\"" title "\""  
    }

    # Ensure no duplicate quotes in the title
    gsub(/""+/, "\"", title)

    # Output the formatted CSV row
    print id, location_id, name, title, email, department
}
' "$input_file" > "$temp_file"

# Append the processed data to the output file
cat "$temp_file" >> "$output_file"

# Clean up temporary files
rm "$temp_file"

# Compare the newly created CSV file with the original CSV file
if [ -n "$reference_file" ]; then
    echo "Comparing the new CSV file with the reference file..."

    diff_output="diff_output.txt"
    diff -u "$reference_file" "$output_file" > "$diff_output"

    if [ -s "$diff_output" ]; then
        echo "Differences found:"
        cat "$diff_output"
    else
        echo "No differences found."
    fi

    rm "$diff_output"
fi

echo "New CSV file created: $output_file"
echo ""
echo "End of the process"
