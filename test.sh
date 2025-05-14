#!/bin/sh

#Following script has been made by Naman Jain with following features included in the
#different version upgrades

##Calling all the functions that will be used in the upcoming script

#31.07.2024 instead of adding run numbers the code picks all the run numbers automatically located in the folder
#14.08.2024 adding slice timing correction to all the functional scans
#14.08.2024 assigning tags to the folders if they are structural or functional
#07.11.2024 all functions to be called are sourced in one file

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
source ./bash_log_create.sh #28.01.2025 creating logs for everytime you run bash scripts
source ./Signal_Change_Map.sh




Raw_Data_Path="/Volumes/pr_ohlendorf/fMRI/RawData"

# The folder to exclude from the search
exclude_folder="Project_Vasoprobes_testing"

# Adjusted find command to exclude the folder properly
find "$Raw_Data_Path" \( -type d -path "$Raw_Data_Path/$exclude_folder" -prune \) -o \( -type d -mindepth 3 -maxdepth 3 -print \) | while read dir; do
    # Change to directory
    cd "$dir" || exit
    pwd
    DatasetName=$(basename "$PWD")
    # echo "Dataset Currently Being Analysed is": $DatasetName

    LOG_DIR="$dir" # Define the log directory where you want to store the script.
    user=$(whoami)
    log_execution "$LOG_DIR" || exit 1


    cd - > /dev/null
done