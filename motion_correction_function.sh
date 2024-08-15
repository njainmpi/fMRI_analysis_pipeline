#!/bin/sh


#06th June 2024: $$Naman Jain$$ This function is to perform motion correction once the data is converted to NIFTI file
                               

#Function 1
MOTION_CORRECTION () {
    3dvolreg -base $1 -Fourier -zpad 1 -1Dfile motion.1D -1Dmatrix_save mat_vr.aff12.1D -prefix mc_stc_func $2
    3dAFNItoNIFTI rG1_fsl+orig.BRIK
    fslchfiletype NIFTI_GZ rG1_fsl.nii rG1_fsl
    # 1Dplot -volreg -sep motion.1D
    fsl_tsplot -i motion.1D -o Motion -t 'Motion Parameters' -x $Runid'_'$FunctionalRunName -y 'fraction of voxels' -h 450 -w 1800
}
