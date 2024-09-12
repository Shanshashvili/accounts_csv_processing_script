#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path_to_accounts.csv"
    exit 1
fi

input_file="$1"
output_file="accounts_new.csv"

awk -F, '
BEGIN {
    OFS=","
    FPAT="([^,]+)|(\"[^\"]+\")"
}

function format_name(name) {
    gsub(/^"|"$/, "", name)
    gsub(/^ +| +$/, "", name)
    split(name, words, " ")
    formatted = ""
    for (i=1; i<=length(words); i++) {
        word = words[i]
        gsub(/^.|-./,toupper(substr(word,1,1)),word)
        formatted = formatted (i>1?" ":"") word
    }
    return formatted
}

function generate_email(name, location_id) {
    split(name, parts, " ")
    first = tolower(substr(parts[1], 1, 1))
    last = tolower(parts[length(parts)])
    gsub(/-/, "", last)
    return first last location_id "@abc.com"
}

NR == 1 {print; next}

{
    id = $1
    location_id = $2
    name = format_name($3)
    title = $4
    email = ""
    department = ""

    for (i=5; i<=NF; i++) {
        if ($i ~ /@/) {
            email = $i
            if (i < NF) department = $(i+1)
            break
        } else if (i == NF) {
            department = $i
        } else {
            title = title "," $i
        }
    }

    gsub(/^"|"$/, "", title)
    gsub(/^"|"$/, "", email)
    gsub(/^"|"$/, "", department)

    if (email == "" || email !~ /@/ || email !~ /abc\.com$/) {
        email = generate_email(name, location_id)
    }

    if (title ~ /,$/) {
        gsub(/,$/, "", title)
    }

    if (title ~ /,/) {
        title = "\"" title "\""
    }

    gsub(/""+/, "\"", title)  # Remove any duplicate quotes

    print id, location_id, name, title, email, department
}
' "$input_file" > "$output_file"

echo "New CSV file created: $output_file"
