#!/bin/sh

#Following script has been made by Naman Jain with following features included in the
#different version upgrades

##Calling all the functions that will be used in the upcoming script

#31.07.2024 instead of adding run numbers the code picks all the run numbers automatically located in the folder
#14.08.2024 adding slice timing correction to all the functional scans
#14.08.2024 assigning tags to the folders if they are structural or functional
#07.11.2024 all functions to be called are sourced in one file

source ./All_functions_to_be_called.sh

## Main Script Starts from here
# File_with_Dataset_Names="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/RawData/DatasetNames.txt"
File_with_Dataset_Names="/Users/njain/Desktop/data.txt"

indices=(6) #enter the index number of the file name that you would like to analyse
echo $indices

for datasets in "${indices[@]}"; do
    
    DatasetName=$(awk -F "\"*,\"*" -v var="$datasets" 'NR == var {print $1}' $File_with_Dataset_Names)
    echo "Dataset Currently Being Analysed is": $DatasetName

    #Locate the source of Raw Data on the server, this needs to be changed by the user based on the paths defined in their system#
    Raw_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/RawData/$DatasetName"
    # Analysed_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/AnalysedData/$DatasetName"
  
    # Raw_Data_Path="/Users/njain/Desktop/$DatasetName"
    Analysed_Data_Path="/Users/njain/Desktop/MPI/$DatasetName"
    
    CHECK_FILE_EXISTENCE $Analysed_Data_Path
   
    cd $Raw_Data_Path

    for runnames in *; do #31.07.2024 instead of adding run numbers the code picks all the run numbers automatically located in the folder
   
        echo $runnames
        echo ""
        echo ""
        echo "Currently Analysing Run Number: $runnames"
        echo ""
        echo ""

        Raw_Data_Path_Run="$Raw_Data_Path/$runnames"
            
        FUNC_PARAM_EXTARCT $Raw_Data_Path_Run

        CHECK_FILE_EXISTENCE $Analysed_Data_Path/$runnames''$SequenceName
        if [ $? -eq 1 ]; then
            echo "Run already analysed, moving to next run"
            continue
        fi
            cd $Analysed_Data_Path/$runnames''$SequenceName

        #31.07.2024: Adding a loop to check for Localizer scans and separrate them from other used sequences

        word_to_check="Localizer"
        echo $SequenceName
        
        if echo "$SequenceName" | grep -q "$word_to_check"; then
            echo "This data is acquired using '$word_to_check'. This will not be analyzed."
            
        else
            echo "This data is not acquired using $word_to_check"

            BRUKER_to_NIFTI $Raw_Data_Path $runnames $Raw_Data_Path/$runnames/method

            if [ "$NoOfRepetitions" == "1" ]; then
                echo "It is a Structural Scan acquired using $SequenceName"
                
            else 
                echo "It is an fMRI scan"
                echo  "*************Checking for Test Scan or Functional Scan*************"
                  
                    
                if grep -q "PreBaselineNum" "$Raw_Data_Path_Run/method"; then
                    echo "It is either a functional or baseline scan"
                    
                    TaskDuration=$(echo "$Baseline_TRs + ($StimOn_TRs + $StimOff_TRs) * $NoOfEpochs" | bc)
                    
                    BlockLength=$(($StimOn_TRs + $StimOff_TRs))
                    MiddleVolume=$(($NoOfRepetitions / 2))
                        
                    # SLICE_TIMING_CORRECTION G1_cp.nii.gz #15.08.2024 updated to perform slice timing correction
                    MOTION_CORRECTION $MiddleVolume G1_cp.nii.gz mc_func
                    CHECK_SPIKES mc_func+orig
                    TEMPORAL_SNR_using_AFNI mc_func+orig
                    SMOOTHING_using_FSL mc_func+orig

                    if [ $TaskDuration == $NoOfRepetitions ]; then
                        echo "It is Stimulated Scan with a total of $NoOfRepetitions Repetitions"
                        
                        STIMULUS_TIMING_CREATION $NoOfEpochs $BlockLength $Baseline_TRs stimulus_times.txt #16.08.2024 creating epoch times
                        ACTIVATION_MAPS sm_mc_stc_func+orig stimulus_times.txt 6 stats_offset_sm_mc_stc_func #16.08.2024 adding a function to estimate activation maps from the data      
                        
                        CHECK_FILE_EXISTENCE Signal_Change_Map
                        
                        cd Signal_Change_Map
                        SIGNAL_CHANGE_MAPS ../G1_cp.nii.gz # 16.10.2024 creating signal change maps
                        cd ..
                                                
                        # THRESHOLDING signal_change_map+orig 0.5 6.0 signal_change_map_threshholded.nii.gz # 19.08.2024 added a function to threshhold images, here we threshhold signal change maps
                        
                        # CHECK_FILE_EXISTENCE TimeSeiesVoxels
                
                        # CREATING_3_COLUMNS $NoOfEpochs $Baseline_TRs $BlockLength $VolTR
                        # TIME_COURSE_PYTHON mc_stc_func.nii parenchyma.nii.gz parenchyma.txt activation_times.txt $BlockLength $NoOfEpochs #10.09.2024 function to get time course for individual voxel and averaged for all voxels in a mask
                        
                        # TIME_SERIES $Analysed_Data_Path/$runnames''$SequenceName/NIFTI_file_header_info.txt
            
                    else
                        echo "It is a Baseline/ rs-fMRI Scan with a total of $NoOfRepetitions Repetitions"

                    fi
                
                else 
                    echo "It is a test scan"
                    
                fi
        
            fi
        
        fi

    done 
   
done