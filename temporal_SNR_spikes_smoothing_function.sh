#!/bin/sh


#06th June 2024: $$Naman Jain$$ This function is to estimate temporal SNR. Second part of the code checks
#                               for the presence of spikes, if present any, in the data. 
       
#Function 1
TEMPORAL_SNR_using_FSL () {
    echo "******* Computing Temporal SNR *******"
    fslmaths $1 -Tmean rG1_fsl_mean
    fslmaths $1 -Tstd rG1_fsl_std
    fslmaths rG1_fsl_mean.nii.gz -div rG1_fsl_std.nii.gz rG1_fsl_tSNR
}

TEMPORAL_SNR_using_AFNI () {
    3dTstat -mean -prefix mean_mc_stc_func+orig $1
    3dTstat -stdev -prefix std_mc_stc_func+orig $1
    3dcalc -a mean_mc_stc_func+orig -b std_mc_stc_func+orig -expr 'a/b' -prefix tSNR_mc_stc_func+orig
    3dAFNItoNIFTI mean_mc_stc_func+orig
}

#Function 2
CHECK_SPIKES () {
    3dToutcount -automask -fraction -polort 3 -legendre $1 > spikecountTC.1D
    fsl_tsplot -i spikecountTC.1D -o spikecountTC -t 'spike count' -x $Runid'_'$FunctionalRunName -y 'fraction of voxels' -h 650 -w 1800
}

#Function 3
SMOOTHING_using_FSL () {
    fslmaths rG1_fsl.nii.gz -s 0.2812 sG1_fsl.nii.gz
}


#Function 4
SMOOTHING_using_AFNI () {
    3dmerge -1blur_fwhm 0.4 -doall -prefix sm_mc_stc_func $1
}