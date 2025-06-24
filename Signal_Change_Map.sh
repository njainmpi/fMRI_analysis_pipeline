#!/bin/sh


SIGNAL_CHANGE_MAPS () {

        input_4d_nifti=$1   # 4D NIfTI file you want to smooth
        local base_start=$2
        local base_end=$3
        local file_for_parameter_calculation=$4
        local baseline_duration=$5
        local pacap_injection=$6
        local mean_image=$7


        NoOfRepetitions=$(awk -F'=' '/##\$PVM_NRepetitions=/{print $2}' $file_for_parameter_calculation/method)
        TotalScanTime=$(awk -F'=' '/##\$PVM_ScanTime=/{print $2}' $file_for_parameter_calculation/method)
        slice_count=$(awk -F'=' '/##\$NSLICES=/{print $2}' $file_for_parameter_calculation/acqp)
 
        #here the awk will look at the number of slices acquired using the information located in the methods file    
            
        # 07.08.2024 Estimating Volume TR
        VolTR_msec=$(echo "scale=0; $TotalScanTime/$NoOfRepetitions" | bc)
        VolTR=$(echo "scale=0; $VolTR_msec/1000" | bc)
        

        No_of_Vols_in_pre_PACAP_injection=$((baseline_duration * 60 / VolTR))
        No_of_Vols_during_pre_PACAP_injection=$((pacap_injection * 60 / VolTR))


        #Creating Mask Image to Limit Signal Change Maps to masking area
        fslmaths mean_mc_func.nii.gz -thrp 30 -bin mask_mean_mc_func.nii.gz
        
       
        output_smoothed="s${input_4d_nifti}" # Output smoothed file
        output_dir="frames"                  # Directory to store screenshot frames
        movie_output="final_movie.mp4"       # Name of the output movie file

     
        # Step 1: Smooth the 4D NIfTI file (Gaussian smoothing)
        fslmaths $input_4d_nifti -s 0.14 -fmean smoothed_4d.nii.gz

        # Step 3: Apply the mask to the smoothed image
        # This ensures that the smoothing only affects the areas inside the mask
        fslmaths smoothed_4d.nii.gz -mas mask_mean_mc_func.nii.gz "$output_smoothed"

        # Cleanup intermediate files (optional)
        # rm smoothed_4d.nii.gz

        echo "Smoothing complete. Output saved as $output_smoothed"

        # Step 1: Compute the baseline image (mean of the first 600 repetitions)
        3dTstat -mean -prefix baseline_image.nii.gz $output_smoothed"[${base_start}..${base_end}]"

        # Initialize an empty list to store the intermediate processed images
        processed_images=()

        volumes_per_block=$((60 / VolTR))
        end_idx_pt=$(( NoOfRepetitions - volumes_per_block ))
        echo $NoOfRepetitions
        echo $volumes_per_block
        echo $end_idx_pt
 


        # Step 2: Process blocks of 60 repetitions, starting from time point 601
        for start_idx in $(seq $No_of_Vols_in_pre_PACAP_injection $volumes_per_block $end_idx_pt); do
                end_idx=$((start_idx + volumes_per_block - 1))
                
                # Create a meaningful label for this block of repetitions
                label="${start_idx}_to_${end_idx}"
                
                # Step 2a: Compute the mean for the current block of 60 repetitions
                3dTstat -mean -prefix block_mean_${label}.nii.gz smoothed_4d.nii.gz"[${start_idx}..${end_idx}]"
                
                # Step 2b: Subtract the baseline and divide by the baseline
                3dcalc -a block_mean_${label}.nii.gz -b baseline_image.nii.gz -expr '(a-b)/b' -prefix ratio_processed_${label}.nii.gz

                #Step 2c: Converting into percent by multiplying it by 100
                3dcalc -a ratio_processed_${label}.nii.gz -expr 'a*100' -prefix processed_${label}.nii.gz
                    
                # Add the processed image to the list
                processed_images+=("processed_${label}.nii.gz")
                
                echo "Processed block: ${start_idx} to ${end_idx}"
        done


        # Step 3: Combine all the processed blocks into a single 4D image
        3dTcat -prefix Signal_Change_Map_premask.nii.gz "${processed_images[@]}"

        fslmaths Signal_Change_Map_premask.nii.gz -mas mask_mean_mc_func.nii.gz Signal_Change_Map

        echo "All blocks processed and combined into final 4D image: Signal_Change_Map.nii.gz"


        rm -f *block* processed* ratio_processed*

        # Step 4: Create the output directory for screenshots
        mkdir -p "$output_dir"


        # Step 5: Extract screenshots for each volume in the final processed 4D image
        num_volumes=$(3dinfo -nv Signal_Change_Map.nii.gz)  # Get the number of volumes

for ((slice_idx=0; slice_idx<slice_count; slice_idx++)); do     

    echo "Making Video for Slice Number $slice_idx"
    python ~/Desktop/Github/fMRI_analysis_pipeline/Making_videos_for_SCM.py $7 Signal_Change_Map.nii.gz $slice_idx
done

}

