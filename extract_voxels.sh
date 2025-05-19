EXTRACT_VOXELS() {
    local roi="$1"
    local side="$2"

    read x_center y_center z_center <<< "$roi"
    echo "ROI centered at x = $x_center, y = $y_center and z = $z_center"
    local dir="Voxel_${side}"
    mkdir -p "$dir"
    cd "$dir" || exit

    local voxel_list_file="voxels_${side}.txt"
    rm -f grouped_z_*.txt  # clean up previous groupings

    for dx in {0..1}; do
        for dy in {0..1}; do
            for dz in {0..1}; do
                x=$((x_center + dx))
                y=$((y_center + dy))
                z=$((z_center + dz))

                echo "$x $y $z" >> "$voxel_list_file"
                echo "Extracting voxel ($x, $y, $z)"
                out_file="vox_${side}_${x}_${y}_${z}.txt"
                fslmeants -i ../mc_func.nii.gz -c $x $y $z -o "$out_file"

                # Append file path to temp list for that z
                echo "$out_file" >> "grouped_z_${z}.txt"
            done
        done
    done

  for zfile in grouped_z_*.txt; do
        z=${zfile##*_}
        z=${z%.txt}
        python3 ~/Desktop/Github/fMRI_analysis_pipeline/voxel_plotting.py \
            "grouped_voxels_${side}_z${z}.svg" $(cat "$zfile")
    done


}

