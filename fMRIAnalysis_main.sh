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

## Main Script Starts from here
# File_with_Dataset_Names="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/RawData/DatasetNames.txt"
File_with_Dataset_Names="/Users/njain/Desktop/data.txt"

indices=(1) #enter the index number of the file name that you would like to analyse

for datasets in "${indices[@]}"; do
    
    DatasetName=$(awk -F "\"*,\"*" -v var="$datasets" 'NR == var {print $1}' $File_with_Dataset_Names)
    echo "Dataset Currently Being Analysed is": $DatasetName

    #Locate the source of Raw Data on the server, this needs to be changed by the user based on the paths defined in their system#
    # Raw_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_SeroAVATar_NJ_KR/RawData/$DatasetName"
    # Analysed_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_SeroAVATar_NJ_KR/AnalysedData/$DatasetName"

    Raw_Data_Path="/Users/njain/Desktop/$DatasetName"
    Analysed_Data_Path="/Users/njain/Desktop/test/$DatasetName"

    LOG_DIR="$Raw_Data_Path/Data_Analysis_log" # Define the log directory where you want to store the script.
    user=$(whoami)
    log_execution "$LOG_DIR" || exit 1

    CHECK_FILE_EXISTENCE $Analysed_Data_Path
   
    cd $Raw_Data_Path

    for runnames in *; do #31.07.2024 instead of adding run numbers the code picks all the run numbers automatically located in the folder
    # if [[ $runname =~ ^[0-9]+$ ]]; then
       
        echo ""
        echo ""
        echo "Currently Analysing Run Number: $runnames"
        echo ""
        echo ""

        Raw_Data_Path_Run="$Raw_Data_Path/$runnames"
            
        FUNC_PARAM_EXTARCT $Raw_Data_Path_Run

        word_to_check="1_Localizer"
                
        if echo "$SequenceName" | grep -q "$word_to_check"; then
            echo "This data is acquired using '$word_to_check'. This will not be analyzed."
            
        else
            echo "This data is acquired using $SequenceName"

            CHECK_FILE_EXISTENCE "$Analysed_Data_Path/$runnames$SequenceName"
            cd $Analysed_Data_Path/$runnames''$SequenceName

            BRUKER_to_NIFTI $Raw_Data_Path $runnames $Raw_Data_Path/$runnames/method

            if [ "$NoOfRepetitions" == "1" ]; then
                echo "It is a Structural Scan or Test Scan acquired using $SequenceName"
                
            else
                echo "It is an fMRI scan"
                                  
                if grep -q "PreBaselineNum" "$Raw_Data_Path_Run/method"; then
                    echo "It is a baseline scan"
                    
                    TaskDuration=$(echo "$Baseline_TRs + ($StimOn_TRs + $StimOff_TRs) * $NoOfEpochs" | bc)
                    
                    BlockLength=$(($StimOn_TRs + $StimOff_TRs))
                    MiddleVolume=$(($NoOfRepetitions / 2))
                        
                    if [ $TaskDuration == $NoOfRepetitions ]; then
                        echo "It is Stimulated Scan with a total of $NoOfRepetitions Repetitions"
                        
                        STIMULUS_TIMING_CREATION $NoOfEpochs $BlockLength $Baseline_TRs stimulus_times.txt #16.08.2024 creating epoch times
                        ACTIVATION_MAPS sm_mc_stc_func+orig stimulus_times.txt 6 stats_offset_sm_mc_stc_func #16.08.2024 adding a function to estimate activation maps from the data      
                        
                        
                        
                        # CHECK_FILE_EXISTENCE TimeSeiesVoxels
                
                        # CREATING_3_COLUMNS $NoOfEpochs $Baseline_TRs $BlockLength $VolTR
                        # TIME_COURSE_PYTHON mc_stc_func.nii parenchyma.nii.gz parenchyma.txt activation_times.txt $BlockLength $NoOfEpochs #10.09.2024 function to get time course for individual voxel and averaged for all voxels in a mask
                        
                        # TIME_SERIES $Analysed_Data_Path/$runnames''$SequenceName/NIFTI_file_header_info.txt
            
                    else
                        echo "It is a Baseline/ rs-fMRI Scan with a total of $NoOfRepetitions Repetitions"

                        # log_function_execution "$LOG_DIR" "Motion Correction using AFNI executed on Run Number $runnames acquired using $SequenceName"|| exit 1
                        # MOTION_CORRECTION $MiddleVolume G1_cp.nii.gz mc_func
                    
                        # log_function_execution "$LOG_DIR" "Checked for presence of spikes in the data on Run Number $runnames acquired using $SequenceName"|| exit 1
                        # CHECK_SPIKES mc_func+orig

                        # log_function_execution "$LOG_DIR" "Temporal SNR estimated on Run Number $runnames acquired using $SequenceName"|| exit 1
                        # TEMPORAL_SNR_using_AFNI mc_func+orig

                        # log_function_execution "$LOG_DIR" "Smoothing using FSL executed on Run Number $runnames acquired using $SequenceName"|| exit 1
                        # SMOOTHING_using_FSL mc_func.nii.gz

                        log_function_execution "$LOG_DIR" "Signal Change Map created for Run Number $runnames acquired using $SequenceName"|| exit 1
                        SIGNAL_CHANGE_MAPS mc_func.nii.gz 100 500 $Raw_Data_Path_Run 10 10 mean_mc_func.nii.gz

                    fi
                
                else 
                    echo "It is a test scan"
                    
                fi
        
            fi
        
        fi
    # fi
    # exit
    done 

done


   # if [ $? -eq 1 ]; then
        #     echo "Run already analysed, moving to next run"
        #     continue
        # fi