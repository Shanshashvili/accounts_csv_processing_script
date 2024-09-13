#!/bin/bash

# Check if an argument is provided for the input file
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 path/to/accounts.csv"
  exit 1
fi

# Input and output file paths
input_file="$1"
output_file="accounts_new.csv"
temp_file="temp_emails.txt"

# Header for the new CSV file
echo "id,location_id,name,title,email,department" > "$output_file"

# Clear the temporary file
> "$temp_file"

# Initialize an associative array to track generated emails
declare -A email_map

awk -F, '
BEGIN {
    OFS=","  # Output field separator
    FPAT="([^,]+)|(\"[^\"]+\")"  # Field pattern to handle quoted fields
}

function format_name(name) {
    gsub(/^"|"$/, "", name)  # Remove leading/trailing quotes
    gsub(/^ +| +$/, "", name)  # Remove leading/trailing spaces
    split(name, words, " ")  # Split name into words
    formatted = ""
    for (i=1; i<=length(words); i++) {
        word = words[i]
        gsub(/^.|-./, toupper(substr(word,1,1)), word)  # Capitalize first letter of word
        formatted = formatted (i>1?" ":"") word  # Join formatted words with spaces
    }
    return formatted
}

function generate_email(name, location_id) {
    split(name, parts, " ")
    first = tolower(substr(parts[1], 1, 1))
    last = tolower(parts[length(parts)])
    gsub(/-/, "", last)  # Remove hyphens from last name

    new_email = first last "@abc.com"

    # If the email is already in use, add location_id
    while (new_email in email_map) {
        new_email = first last location_id "@abc.com"
        location_id++
    }

    email_map[new_email] = 1
    return new_email
}

NR == 1 {next}  # Skip header row

{
    id = $1
    location_id = $2
    name = format_name($3)
    title = $4
    email = $5
    department = $6

    if (email == "") {
        # Generate email based on the rules only if the email field is empty
        email = generate_email(name, location_id)
    }

    if (title ~ /,$/) {
        gsub(/,$/, "", title)  # Remove trailing comma from title
    }

    if (title ~ /,/) {
        title = "\"" title "\""  # Enclose title with quotes if it contains commas
    }

    gsub(/""+/, "\"", title)  # Remove duplicate quotes from title

    print id, location_id, name, title, email, department
}
' "$input_file" > "$temp_file"

# Append the processed data to the output file
cat "$temp_file" >> "$output_file"

# Clean up temporary files
rm "$temp_file"

echo "New CSV file created: $output_file"
