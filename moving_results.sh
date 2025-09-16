#!/bin/bash

move_results() {
  set -Eeuo pipefail
  shopt -s nullglob

  # --- exact filenames to keep in place ---
  local KEEP=(
    "mc_func.nii.gz"
    "G1_cp.nii.gz"
    "NIFTI_file_header_info.txt"
    "RGRO_250430_0224_RN_SD_020_1-10-1-functionalEPI-(E10).nii.gz"
  )

  # --- destination folder name: DD_MM_YY_username ---
  local stamp
  stamp=$(date +%y_%m_%d_%H%M%S)
  local user=${USER:-$(whoami)}
  local dest="${stamp}_${user}"
  mkdir -p -- "$dest"

  # --- helper: check if file should be skipped ---
  should_skip() {
    local f="$1"
    for k in "${KEEP[@]}"; do
      [[ "$f" == $k ]] && return 0
    done
    return 1
  }

  # --- move files (skip keepers and results folders) ---
  for f in *; do
    [[ -e "$f" ]] || continue           # only existing files/dirs
    [[ "$f" == "$dest" ]] && continue   # skip today’s new folder
    [[ -d "$f" && "$f" =~ ^[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{6}_.+$ ]] && continue  # skip old results folders

    if [[ -f "$f" ]]; then
      if ! should_skip "$f"; then
        mv -v -- "$f" "$dest/"
      fi
    elif [[ -d "$f" ]]; then
      mv -v -- "$f" "$dest/"
    fi
  done

  echo "✅ Moved files into: $dest/"
}
