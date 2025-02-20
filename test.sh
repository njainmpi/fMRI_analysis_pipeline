#!/bin/bash

# Base directory where the folders start

# Find all directories at exactly three levels deep from the base directory
find "$base_dir" -mindepth 3 -maxdepth 3 -type d | while read dir; do

echo $base_dir

    # Change to directory
    cd "$dir" || exit
   
   
    # Assuming you want to echo the name of the current folder
    name=$(basename "$PWD")
    
    pwd
    echo $name
    # Return to the base directory
    cd - > /dev/null

    # exit
done





## Main Script Starts from here
# File_with_Dataset_Names="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/RawData/DatasetNames.txt"


Raw_Data_Path="/Volumes/pr_ohlendorf/fMRI/RawData"

find "$Raw_Data_Path" -mindepth 3 -maxdepth 3 -type d | while read dir; do
echo $base_dir

    # Change to directory
    cd "$dir" || exit

    DatasetName=$(basename "$PWD")
    echo "Dataset Currently Being Analysed is": $DatasetName

    #Locate the source of Raw Data on the server, this needs to be changed by the user based on the paths defined in their system#
    Raw_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_SeroAVATar_NJ_KR/RawData/$DatasetName"
    Analysed_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_SeroAVATar_NJ_KR/AnalysedData/$DatasetName"

    # Raw_Data_Path="/Users/njain/Desktop/RawData/$DatasetName"
    # Analysed_Data_Path="/Users/njain/Desktop/AnalysedData/$DatasetName"

    LOG_DIR="$Raw_Data_Path/Data_Analysis_log" # Define the log directory where you want to store the script.
    user=$(whoami)
    log_execution "$LOG_DIR" || exit 1

    CHECK_FILE_EXISTENCE $Analysed_Data_Path
   
    cd $Raw_Data_Path