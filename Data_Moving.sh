#!/bin/bash

# Set the source and destination directories
SOURCE_DIR="~/Desktop/Administration_Work"
DEST_DIR="~/Desktop/test"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Check if destination directory exists, create it if it doesn't
if [ ! -d "$DEST_DIR" ]; then
    echo "Destination directory does not exist. Creating: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# Move files from source to destination
echo "Moving files from $SOURCE_DIR to $DEST_DIR..."
mv "$SOURCE_DIR"/* "$DEST_DIR"/

echo "Move complete."
