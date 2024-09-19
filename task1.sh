#!/bin/bash
echo "Starting the process"
# Check if a file path is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path_to_accounts.csv"
    exit 1
fi

# Input file
INPUT_FILE="$1"

# Temporary file to store the first pass output
TEMP_FILE="accounts_temp.csv"

# Output file
OUTPUT_FILE="accounts_new.csv"

# First pass: Create the emails without the location IDs
awk '
BEGIN {
    FS = ",";  # Set comma as the field separator
    OFS = ","; # Output field separator
    quote = "\"";
}

# Function to capitalize the first letter of first and last name
function format_name_part(name) {
    return toupper(substr(name, 1, 1)) tolower(substr(name, 2));
}

NR == 1 {
    # Print header as-is
    print $0;
}

NR > 1 {
    id = $1;
    location_id = $2;
    name = $3;
    title = $4;
    email = $5;
    department = $6;

    # Handle title with commas
    if (title ~ /^"/ && $5 !~ /^"/) {
        title = title "," $5;
        email = $6;
        department = $7;
    }

    # Extract the first and last name
    split(name, n, " ");
    first_name = n[1];
    last_name = n[2];

     # Format name: first letter uppercase, rest lowercase for each part of the name
        for (i = 1; i <= 2; i++) {
            # Check if the part of the name contains a hyphen
            if (index(n[i], "-") > 0) {
                # Split by hyphen and capitalize both parts
                split(n[i], hyphenated, "-")
                n[i] = toupper(substr(hyphenated[1], 1, 1)) tolower(substr(hyphenated[1], 2)) "-" \
                          toupper(substr(hyphenated[2], 1, 1)) tolower(substr(hyphenated[2], 2))
            } else {
                n[i] = toupper(substr(n[i], 1, 1)) tolower(substr(n[i], 2))
            }
        }
        formatted_name = n[1] " " n[2]

    # Create the email prefix (first letter of first name + last name, lowercase)
    email_prefix = tolower(substr(first_name, 1, 1) last_name);
    email_domain = "@abc.com";

    # Create new email without appending location ID
    new_email = email_prefix email_domain;

    # Print the first pass without location IDs
    print id, location_id, formatted_name, title, new_email, department;
}
' "$INPUT_FILE" > "$TEMP_FILE"

# Second pass: Add location IDs for duplicated emails
awk '
BEGIN {
    FS = ",";  # Set comma as the field separator
    OFS = ","; # Output field separator
}

NR > 1 {
    id = $1;
    location_id = $2;
    name = $3;
    title = $4;
    email = $5;
    department = $6;

    # Count how many times each email occurs
    email_count[email]++;
}

END {
    # Second pass over the file
    while (getline < "'$TEMP_FILE'") {
        split($0, row, FS);
        email = row[5];
		title=row[4];
		department=row[6];
        location_id = row[2];

		if (title ~ /^"/ && $5 !~ /^"/) {
			title = title "," $5;
			email = $6;
			department = row[7];
		}
		
        # If the email appears more than once, append the location ID
        if (email_count[email] > 1) {
            email_prefix = substr(email, 1, index(email, "@") - 1);
            email = email_prefix location_id "@abc.com";
        }

		
        # Reprint the row with the updated email if necessary
        print row[1], row[2], row[3], title, email, department;
    }
}
' "$TEMP_FILE" > "$OUTPUT_FILE"

# Clean up temporary file
rm "$TEMP_FILE"

echo "New file created: $OUTPUT_FILE"
