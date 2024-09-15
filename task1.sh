#!/bin/bash

echo "Start of the process"

# Exit if path to accounts.csv file not provided as argument
if [ $# -lt 1 ]; then
    echo "Error: Usage: ./task1.sh /path/to/accounts.csv"
    exit 1
fi

file=$1

# Exit if provided file doesn't exist
if [ ! -f "$file" ]; then
    echo "Error: File $file does not exist"
    exit 1
fi

echo "Processing file: $file"

# Extract directory from file
path=$(dirname "$file")
output_file="$path/accounts_new.csv"

# Processing CSV file with awk
awk '
    BEGIN {
        FS = ","; OFS = ",";  # Set field and output field separators
        FPAT = "([^,]+)|(\"[^\"]+\")";  # Handle quoted fields properly
    }

    # First pass: Track email counts
    NR == FNR {
        # Skip header row
        if (NR == 1) {
            next
        }

        # Split the name field to get first and last names
        split($3, name, " ")
        first_name = name[1]
        last_name = name[length(name)]

        # Generate the base email: first letter of first name + last name
        email = tolower(substr(first_name, 1, 1) last_name)

        # Increment the counter for the email
        email_count[email]++
        next
    }

    # Second pass: Generate the updated CSV
    NR != FNR {
        # Output the header row as-is
        if (FNR == 1) {
            print $0
            next
        }

        # Split the name field to get first and last names
        split($3, name, " ")
        first_name = name[1]
        last_name = name[length(name)]

        # Format name: first letter uppercase, rest lowercase
        for (i = 1; i <= length(name); i++) {
            name[i] = toupper(substr(name[i], 1, 1)) tolower(substr(name[i], 2))
        }
        formatted_name = name[1] " " name[length(name)]

        # Generate base email
        email = tolower(substr(first_name, 1, 1) last_name)

        # If the email is not unique, append the location_id
        if (email_count[email] > 1) {
            email = email $2  # Append location_id to the email
        }

        # Assign the generated email to the email field
        $5 = email "@abc.com"

        # Update the name field with the formatted name
        $3 = formatted_name

        # Print the updated row, including the department field unchanged
        print $1, $2, $3, $4, $5, $6
    }
' "$file" "$file" > "$output_file"

echo "CSV processing complete."

echo "New CSV file created at: $output_file"
