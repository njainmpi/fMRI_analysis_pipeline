#!/bin/sh


#06th June 2024: $$Naman Jain$$ This function is to perform motion correction once the data is converted to NIFTI file
                               

#Function 1
MOTION_CORRECTION () {
    
    3dvolreg -prefix $3 -base $1 -1Dfile motion.1D -1Dmatrix_save mats -linear -twopass -float -maxdisp1D rmsabs.1D $2
    3dAFNItoNIFTI $3'+orig.BRIK'
    # 1Dplot -volreg -sep motion.1D
    1dplot -xlabel Time -ylabel "Translation (mm)" -title "3dvolreg translations" -dx 1 -jpgs 640x144 rest_translation 'motion.1D[3..5]'
    1dplot -xlabel Time -ylabel "Rotation" -title "3dvolreg rotations" -dx 1 -jpgs 640x144 rest_rotation 'motion.1D[0..2]'
}


QUALITY_CHECK () {

    # Calculate absolute and relative RMS displacement
    1d_tool.py -infile motion.1D -set_nruns 1 -derivative -write motion_rel.1D
    1d_tool.py -infile motion.1D -set_nruns 1 -show_max_displace -write motion_abs.1D
    1dplot -png rrest_disp.png -xlabel Time -ylabel "Displacement (mm)" -title "3dvolreg estimated mean displacement" -dx 1 -jpgs 640x144 motion_abs.1D motion_rel.1D

    ## Calculate the difference between 1st and last time frame both before and after motion correction:
    3dcalc -a $2[0] -b $2[$] -expr 'a-b' -prefix rest_sub.nii
    3dcalc -a $3[0] -b $3[$] -expr 'a-b' -prefix mc_func_sub.nii

    ## Generate motion metrics, DVARS and Frame Difference (FD)
    fsl_motion_outliers -i $2 -o rest_outlier_dvars_EV.txt -s rest_motion_dvars.txt -p rest_motion_dvars.png --dvars --nomoco
    fsl_motion_outliers -i $2 -o rest_outlier_fd_EV.txt -s rest_motion_fd.txt -p rest_motion_fd.png --fd

    #Create a mask for data analysis
    fslmaths $3 -Tmean mean_image
    fslmaths mean_mask_image.nii.gz -thrp 45 -bin mean_image_mask.nii.gz
    echo "Please clean up the mask image"
    fsleyes mean_image mean_image_mask.nii.gz

    ## Calculate temporal SNR (tSNR) before correction:
    fslmaths $2 -mas mean_image_mask_cleaned.nii.gz -Tstd raw_fMRI_std
    fslmaths $2 -mas mean_image_mask_cleaned.nii.gz -Tmean raw_fMRI_mean
    fslmaths raw_fMRI_mean.nii.gz -div raw_fMRI_std.nii.gz raw_fMRI_tSNR

    ## Calculate temporal SNR (tSNR) after correction:
    fslmaths $3 -mas mean_image_mask_cleaned.nii.gz -Tstd mc_fMRI_std
    fslmaths $3 -mas mean_image_mask_cleaned.nii.gz -Tmean mc_fMRI_mean
    fslmaths mc_fMRI_mean.nii.gz -div mc_fMRI_std.nii.gz mc_fMRI_tSNR

    fslstats -K mean_image_mask_cleaned.nii.gz raw_fMRI_tSNR.nii.gz -n -m > raw_fMRI_tSNR_mean.txt
    fslstats -K mean_image_mask_cleaned.nii.gz mc_fMRI_tSNR.nii.gz -n -m > mc_fMRI_tSNR_mean.txt

}