#!/bin/bash

#Made on 01.08.2024 by Naman Jain to check if the variables are present in the desired file or not.

# Usage: ./check_variables.sh file_name variable1 variable2 ... variableN

# Argument Check:

# The script checks if at least two arguments are provided (a file and at least one variable).
# Variable Extraction:

# check_variable function uses awk to search for the variable in the file and extracts its value if present.
# FS = "=" sets the field separator to = to split the variable name and value.
# exit ensures the function stops after finding the first match.
# Loop Through Variables:

# The script loops through each provided variable name and checks its presence using the check_variable function.


# Check if at least two arguments are provided (file and one variable)
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 file_name variable1 variable2 ... variableN"
    exit 1
fi

# Get the file name and shift to process variable names
file_name=$1
shift

# Function to extract and check variable presence and non-emptiness
CHECK_VARIABLE() {
    local var_name=$1
    local var_value=$(awk -v var_name="$var_name" '
    BEGIN { FS = "=" }
    $1 == var_name { print $2; exit }' "$file_name")
    
    if [ -n "$var_value" ]; then
        echo "$var_name is present and non-empty: $var_value"
    else
        echo "$var_name is missing or empty"
    fi
}

# Loop through all provided variable names and check each one
for var in "$@"; then
    CHECK_VARIABLE "$var"
done