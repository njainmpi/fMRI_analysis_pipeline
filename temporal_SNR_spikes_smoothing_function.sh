#!/bin/bash


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
    3dTstat -mean -prefix 'mean_'$1 $1
    3dTstat -stdev -prefix 'std_'$1 $1
    3dcalc -a 'mean_'$1 -b 'std_'$1 -expr 'a/b' -prefix 'tSNR_'$1
    3dAFNItoNIFTI "mean_$1" && gzip "mean_${1/+orig/.nii}"
    3dAFNItoNIFTI "tSNR_$1" && gzip "tSNR_${1/+orig/.nii}"

}

#Function 2
CHECK_SPIKES () {
    3dToutcount -automask -fraction -polort 3 -legendre $1 > spikecountTC.1D
    fsl_tsplot -i spikecountTC.1D -o spikecountTC -t 'spike count' -x $Runid'_'$FunctionalRunName -y 'fraction of voxels' -h 650 -w 1800
}

#Function 3
SMOOTHING_using_FSL () {
    fslmaths $1 -s 1.1774 'sm_'$1
}


#Function 4
SMOOTHING_using_AFNI () {
    3dmerge -1blur_fwhm 0.4 -doall -prefix sm_mc_stc_func $1
}