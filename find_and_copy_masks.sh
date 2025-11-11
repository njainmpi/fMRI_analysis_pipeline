#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Function: find_and_copy_masks
# Searches recursively for mask_*.nii.gz in the current directory
# Lets the user choose one folder and copies files into current dir
# ============================================================

find_and_copy_masks() {
  local BASE_DIRS=("$PWD")

  echo "🔍 Searching recursively for mask_*.nii.gz in:"
  for d in "${BASE_DIRS[@]}"; do
    echo "   - $d"
  done
  echo

  # --- Find all matching files ---
  local FOUND_FILES
  FOUND_FILES=$(find "${BASE_DIRS[@]}" -type f -name "mask_*.nii.gz" 2>/dev/null)

  if [ -z "$FOUND_FILES" ]; then
    echo "❌ No mask_*.nii.gz files found."
    return 0
  fi

  # --- Extract unique folders and counts ---
  local FOLDER_LIST_FILE
  FOLDER_LIST_FILE=$(mktemp)
  echo "$FOUND_FILES" | while IFS= read -r file; do
    dir=$(dirname "$file")
    echo "$dir"
  done | sort | uniq -c > "$FOLDER_LIST_FILE"

  if [ ! -s "$FOLDER_LIST_FILE" ]; then
    echo "❌ No folders found."
    rm -f "$FOLDER_LIST_FILE"
    return 1
  fi

  # --- Display results ---
  echo "📁 The following folders contain mask_*.nii.gz files:"
  echo
  local i=1
  declare -a FOLDER_PATHS
  while read -r count folder; do
    echo "  $i) $folder  ($count file(s))"
    FOLDER_PATHS[$i]="$folder"
    i=$((i + 1))
  done < "$FOLDER_LIST_FILE"

  echo
  read -p "👉 Enter the number of the folder to copy from: " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ -z "${FOLDER_PATHS[$choice]:-}" ]; then
    echo "❌ Invalid selection."
    rm -f "$FOLDER_LIST_FILE"
    return 1
  fi

  local SELECTED_FOLDER="${FOLDER_PATHS[$choice]}"
  local DEST_FOLDER="$PWD"

  echo
  echo "🚚 Copying files from:"
  echo "   $SELECTED_FOLDER"
  echo "➡️  To:"
  echo "   $DEST_FOLDER"
  echo

  # --- Copy files ---
  local COUNT=0
  for f in "$SELECTED_FOLDER"/mask_*.nii.gz; do
    if [ -f "$f" ]; then
      cp -v "$f" "$DEST_FOLDER"/
      COUNT=$((COUNT + 1))
    fi
  done

  if [ "$COUNT" -eq 0 ]; then
    echo "⚠️ No mask_*.nii.gz files found directly inside $SELECTED_FOLDER (maybe deeper)."
  else
    echo "✅ Copied $COUNT file(s) to $DEST_FOLDER."
  fi

  rm -f "$FOLDER_LIST_FILE"
  echo
  echo "🎉 Done!"
}

# ============================================================
# Example usage:
# ============================================================
# Uncomment this line to run the function standalone:
# find_and_copy_masks
