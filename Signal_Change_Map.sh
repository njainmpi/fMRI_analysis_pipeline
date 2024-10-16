#!/bin/sh


SIGNAL_CHANGE_MAPS () {

        input_4d_nifti=$1   # 4D NIfTI file you want to smooth

        fslmaths $input_4d_nifti -Tmean mean_${1}
        input_4d_nifti_mean=mean_${1}
        echo $input_4d_nifti_mean

        if [ -f "mask_${input_4d_nifti}" ]; then 
            echo "Mask Present"
        else 
            echo "Create a mask first"
            fsleyes "$input_4d_nifti_mean"
        fi
        
        mask_image="mask_${input_4d_nifti}"  # Binary mask file
        output_smoothed="s${input_4d_nifti}" # Output smoothed file
        fwhm=1                               # Full-width half-maximum for Gaussian smoothing (in mm)
        output_dir="frames"                  # Directory to store screenshot frames
        movie_output="final_movie.mp4"       # Name of the output movie file

        # Step 1: Convert FWHM to sigma for fslmaths smoothing
        # FSL smoothing sigma = FWHM / (2 * sqrt(2 * log(2)))
        sigma=$(echo "$fwhm / (2 * sqrt(2 * l(2)))" | bc -l)

        # Step 2: Smooth the 4D NIfTI file (Gaussian smoothing)
        fslmaths "$input_4d_nifti" -s "$sigma" smoothed_4d.nii.gz

        # Step 3: Apply the mask to the smoothed image
        # This ensures that the smoothing only affects the areas inside the mask
        fslmaths smoothed_4d.nii.gz -mas "$mask_image" "$output_smoothed"

        # Cleanup intermediate files (optional)
        rm smoothed_4d.nii.gz

        echo "Smoothing complete. Output saved as $output_smoothed"

        # Step 1: Compute the baseline image (mean of the first 600 repetitions)
        3dTstat -mean -prefix baseline_image.nii.gz sG1_cp.nii.gz'[0..599]'

        # Initialize an empty list to store the intermediate processed images
        processed_images=()

        # Step 2: Process blocks of 60 repetitions, starting from time point 601
        for start_idx in $(seq 600 60 1740); do
        end_idx=$((start_idx + 59))
        
        # Create a meaningful label for this block of repetitions
        label="${start_idx}_to_${end_idx}"
        
        # Step 2a: Compute the mean for the current block of 60 repetitions
        3dTstat -mean -prefix block_mean_${label}.nii.gz sG1_cp.nii.gz"[${start_idx}..${end_idx}]"
        
        # Step 2b: Subtract the baseline and divide by the baseline
        3dcalc -a block_mean_${label}.nii.gz -b baseline_image.nii.gz -expr '(a-b)/b' -prefix ratio_processed_${label}.nii.gz
        #Step 2c: Converting into percent by multiplying it by 100
        3dcalc -a ratio_processed_${label}.nii.gz -expr 'a*100' -prefix processed_${label}.nii.gz
            
        # Add the processed image to the list
        processed_images+=("processed_${label}.nii.gz")
        
        echo "Processed block: ${start_idx} to ${end_idx}"
        done


        # Step 3: Combine all the processed blocks into a single 4D image
        3dTcat -prefix Signal_Change_Map.nii.gz "${processed_images[@]}"

        echo "All blocks processed and combined into final 4D image: Signal_Change_Map.nii.gz"


        rm -f *block* processed* ratio_processed*

        # Step 4: Create the output directory for screenshots
        mkdir -p "$output_dir"


        # Step 5: Extract screenshots for each volume in the final processed 4D image
        num_volumes=$(3dinfo -nv Signal_Change_Map.nii.gz)  # Get the number of volumes


python ~/Desktop/Github/fMRI_analysis_pipeline/Making_videos_for_SCM.py mean_${1} Signal_Change_Map.nii.gz

}