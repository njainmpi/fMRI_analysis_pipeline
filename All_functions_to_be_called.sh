#!/bin/sh

#07.11.2024: All files with functions located here

source ./data_conversion_function.sh #converting data from either Bruker or Dicom format to NIFTI format
source ./folder_existence_function.sh #check if folder is present or not
source ./motion_correction_function.sh #perform motion correction using AFNI
source ./temporal_SNR_spikes_smoothing_function.sh #check presence of spikes, peforms smoothing using either AFNI or NIFTI, caclulates temporal SNR
source ./time_series_function.sh
source ./activation_maps.sh # to map areas of activation using AFNI, also generates signal change maps
source ./outlier_count.sh #14.08.2024 new function to perfom slice timing correction and outlier estimate before and after slice timing correction
source ./video_making.sh #19.08.2024 new function to make videos of the signal change maps
source ./func_parameters_extraction.sh #07.11.2024 new function to extract parameters for fMRI analysis

