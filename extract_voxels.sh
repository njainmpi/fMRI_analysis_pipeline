EXTRACT_VOXELS() {


    local roi="$1"
    local side="$2"

    read x_center y_center z_center <<< "$roi"

    local dir="Voxel_${side}"
    mkdir -p "$dir"
    cd "$dir" || exit

    local voxel_list_file="voxels_${side}.txt"

    for dx in {-3..3}; do
        for dy in {0..3}; do
            for dz in {-1..1}; do
                x=$((x_center + dx))
                y=$((y_center + dy))
                z=$((z_center + dz))

                echo "$x $y $z" >> "$voxel_list_file"
                echo "Extracting voxel ($x, $y, $z)"
                fslmeants -i ../mc_func.nii.gz -c $x $y $z -o "vox_${side}_${x}_${y}_${z}.txt"
            done
        done
    done

    cd ..
}
