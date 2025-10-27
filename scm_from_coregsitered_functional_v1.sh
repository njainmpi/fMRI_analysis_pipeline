#!/bin/bash

# this is a function to coregister functional data to structural data and generate signal change map (SCM)
scm_coregsitered_functional () {


  if [[ $# -ne 6 ]]; then
    echo "Usage: make_scm_with_cannula_coreg <mc_func.nii.gz> <cleaned_anatomy.nii.gz> <base_start> <base_end> <sig_start> <sig_end>" >&2
    return 2
  fi

  mc_func="$1"
  anatomy="$2"
  base_start="$3"
  base_end="$4"
  sig_start="$5"
  sig_end="$6"
      
      fslmaths ${1} -Tmean mean_mc_func_cannulas

      
      if [[ -f mask_mean_mc_func_cannulas.nii.gz ]]; then
        echo "Mask file mask_mean_mc_func.nii.gz already exists. Using the existing mask."
      else
        echo "When fsleyes opens, create a mask to include cannulas in the functional data and save it as mask_mean_mc_func_cannulas.nii.gz"
        cp mask_mean_mc_func.nii.gz mask_mean_mc_func_cannulas.nii.gz
        fsleyes mean_mc_func_cannulas.nii.gz mask_mean_mc_func_cannulas.nii.gz
        rm -f mean_mc_func_cannulas.nii.gz
      fi
      

      # Create masks to include cannulas from functional data
      fslmaths mc_func.nii.gz -mas mask_mean_mc_func_cannulas.nii.gz cleaned_with_cannula_mc_func.nii.gz
      fslmaths cleaned_with_cannula_mc_func.nii.gz -Tmean mean_mc_func_cannulas.nii.gz
      
      # Coregsiter cleaned mean functional image to the cleaned structural image
      3dAllineate -base ${2} -input mean_mc_func_cannulas.nii.gz -1Dmatrix_save mean_func_struct_aligned.aff12.1D -cost lpa -prefix mean_func_struct_aligned.nii.gz -1Dparam_save params.1D -twopass

      # Use the transformation matrix generated from above step to register entire functional time series to strucutral data
      3dAllineate -input cleaned_with_cannula_mc_func.nii.gz -1Dmatrix_apply mean_func_struct_aligned.aff12.1D -master ${2} -final linear -prefix fMRI_coregistered_to_struct.nii.gz

      # Create a mean image from the coregistered functional image
      fslmaths fMRI_coregistered_to_struct.nii.gz -Tmean mean_fMRI_coregistered_to_struct.nii.gz 

      # Create a mask on the mean image to estimate signal change map
      
      if [[ -f mask_mean_fMRI_coregistered_to_struct.nii.gz ]]; then
        echo "Mask file mask_mean_fMRI_coregistered_to_struct.nii.gz already exists. Using the existing mask."
      else
        echo "Please save the mask as mask_mean_fMRI_coregistered_to_struct.nii.gz"
        fsleyes mean_fMRI_coregistered_to_struct.nii.gz
      
      fi
      
      # # Apply spatial smoothing - 2 voxel
      # fslmaths fMRI_coregistered_to_struct -s 0.12 sm_fMRI_coregistered_to_struct.nii.gz


      # # Clean the coregsitered functional data to generate SCM
      # fslmaths sm_fMRI_coregistered_to_struct.nii.gz -mas mask_mean_fMRI_coregistered_to_struct.nii.gz sm_fMRI_for_scm

      # Generate SCM
      3dTstat -mean -prefix "coreg_signal_image_${sig_start}_to_${sig_end}.nii.gz" "fMRI_coregistered_to_struct.nii.gz[${sig_start}..${sig_end}]"
      3dTstat -mean -prefix "coreg_baseline_image_${base_start}_to_${base_end}.nii.gz" "fMRI_coregistered_to_struct.nii.gz[${base_start}..${base_end}]"

      fslmaths "coreg_signal_image_${sig_start}_to_${sig_end}.nii.gz" \
            -sub "coreg_baseline_image_${base_start}_to_${base_end}.nii.gz" \
            -div "coreg_baseline_image_${base_start}_to_${base_end}.nii.gz" \
            -mul 100 "sm_coreg_func_Static_Map_${base_start}_to_${base_end}_and_${sig_start}_to_${sig_end}.nii.gz"

      echo "Done ✅  Output map: sm_coreg_func_Static_Map_${base_start}_to_${base_end}_and_${sig_start}_to_${sig_end}.nii.gz"
}


