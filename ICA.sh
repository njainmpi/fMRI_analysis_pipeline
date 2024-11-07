#!/bin/bash

# This script applies ICA to fMRI data using FSL's MELODIC tool.

# Define the input data path
INPUT_DATA="$1"        # First argument: path to the fMRI data (e.g., /path/to/fmri_data.nii.gz)
OUTPUT_DIR="$2"        # Second argument: path to output directory (e.g., /path/to/output)

# Check if input data is provided
if [ -z "$INPUT_DATA" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: $0 /path/to/fmri_data.nii.gz /path/to/output"
  exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run MELODIC for ICA analysis
melodic -i "$INPUT_DATA" -o "$OUTPUT_DIR" --nobet --bgthreshold=10 --tr=1.0 --report --guireport="$OUTPUT_DIR/report.html"

# Explanation of MELODIC options:
# -i: input data (fMRI data file)
# -o: output directory
# --nobet: do not apply brain extraction (skip BET); assuming brain extraction was done
# --bgthreshold: background threshold for ICA
# --tr: repetition time (TR) in seconds; adjust if different
# --report: generate a report of the ICA analysis
# --guireport: specify an HTML report path

echo "ICA analysis complete. Results are saved in $OUTPUT_DIR."
