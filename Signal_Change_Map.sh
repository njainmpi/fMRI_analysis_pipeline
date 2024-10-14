#!/bin/sh

input_4d_nifti="G1_cp.nii.gz"   # 4D NIfTI file you want to smooth
mask_image="G1_cp_mask.nii.gz"     # Binary mask file
output_smoothed="sG1_cp.nii.gz"  # Output smoothed file
fwhm=2                                  # Full-width half-maximum for Gaussian smoothing (in mm)

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
  3dcalc -a block_mean_${label}.nii.gz -b baseline_image.nii.gz -expr '(a-b)/b' -prefix processed_${label}.nii.gz
  
  # Add the processed image to the list
  processed_images+=("processed_${label}.nii.gz")
  
  echo "Processed block: ${start_idx} to ${end_idx}"
done


# Step 3: Combine all the processed blocks into a single 4D image
3dTcat -prefix final_processed_image.nii.gz "${processed_images[@]}"

echo "All blocks processed and combined into final 4D image: final_processed_image.nii.gz"
