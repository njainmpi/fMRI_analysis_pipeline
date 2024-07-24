#!/bin/sh


#06th June 2024: $$Naman Jain$$ This function is to estimate temporal SNR. Second part of the code checks
#                               for the presence of spikes, if present any, in the data. 
       
#Function 51
TEMPORAL_SNR () {
    echo "******* Computing Temporal SNR *******"
    fslmaths $1 -Tmean rG1_fsl_mean
    fslmaths $1 -Tstd rG1_fsl_std
    fslmaths rG1_fsl_mean.nii.gz -div rG1_fsl_std.nii.gz rG1_fsl_tSNR
}

#Function 2
CHECK_SPIKES () {
    3dToutcount -automask -fraction -polort 3 -legendre $1 > spikecountTC.1D
    fsl_tsplot -i spikecountTC.1D -o spikecountTC -t 'spike count' -x $Runid'_'$FunctionalRunName -y 'fraction of voxels' -h 450 -w 1800
}

#Function 6
SMOOTHING () {
    fslmaths rG1_fsl.nii.gz -kernel gauss 0.212 -fmean sG1_fsl.nii.gz
}