#!/bin/sh

#Following script has been made by Naman Jain with following features included in the
#different version upgrades

##Calling all the functions that will be used in the upcoming script


source ./data_conversion_function.sh
source ./folder_existence_function.sh
source ./motion_correction_function.sh
source ./temporal_SNR_spikes_smoothing_function.sh
source ./time_series_function.sh

# chmod +x ./Functions_Bash/*


## Main Script Starts from here
# File_with_Dataset_Names="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/RawData/DatasetNames.txt"
File_with_Dataset_Names="/Users/njain/Desktop/data.txt"

indices=(1) #enter the index number of the file name that you would like to analyse

for datasets in "${indices[@]}"; do
    
    DatasetName=$(awk -F "\"*,\"*" -v var="$datasets" 'NR == var {print $1}' $File_with_Dataset_Names)
    echo "Dataset Currently Being Analysed is": $DatasetName

    #Locate the source of Raw Data on the server, this needs to be changed by the user based on the paths defined in their system#
    # Raw_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/RawData/$DatasetName"
    # Analysed_Data_Path="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/AnalysedData/$DatasetName"

    Raw_Data_Path="/Users/njain/Desktop/$DatasetName"
    Analysed_Data_Path="/Users/njain/Desktop/MPI/$DatasetName"


    CHECK_FILE_EXISTENCE $Analysed_Data_Path

    for runnames in {26,28,30,34,35,36,37,39,40,41,44,45,46,47,48,49,50,51,52,53,54,56,57,5,6,8,9,15,16,18,19,20,21,22}; do

        echo ""
        echo ""
        echo "Currently Analysing Run Number: $runnames"
        echo ""
        echo ""

        Raw_Data_Path_Run="$Raw_Data_Path/$runnames"
        NoOfRepetitions=$(awk '/PVM_NRepetitions=/ {print substr($0,21,3)}' $Raw_Data_Path_Run/method)
        #here the awk will look at the number of slices acquired using the information located in the methods file
        MiddleVolume=$(($NoOfRepetitions / 2))

        Sequence="`grep -A1 'ACQ_protocol_name=( 64 )' $Raw_Data_Path_Run/acqp | grep -v -e 'ACQ_protocol_name=( 64 )' -e '--'`"
        #here the grep command will read the no of slices from the Bruker raw file acquired during acquisiton
        SequenceName=$(echo "$Sequence" | sed 's/[<>]//g')

        CHECK_FILE_EXISTENCE $Analysed_Data_Path/$runnames''$SequenceName
        cd $Analysed_Data_Path/$runnames''$SequenceName
       
        BRUKER_to_NIFTI $Raw_Data_Path $runnames $Raw_Data_Path/$runnames/method

        if [ "$NoOfRepetitions" == "1" ]; then
            echo "It is a Structural Scan acquired using $SequenceName"
        

        else 
            echo "It is an fMRI scan"
            echo  "*************Checking for Stimulated Scan or Baseline Scan*************"

            Baseline_TRs=$(awk '/PreBaselineNum=/ {print substr($0,19,3)}' $Raw_Data_Path_Run/method)
            StimOn_TRs=$(awk '/StimNum=/ {print substr($0,12,2); exit}' $Raw_Data_Path_Run/method)  
            StimOff_TRs=$(awk '/InterStimNum=/ {print substr($0,17)}' $Raw_Data_Path_Run/method)  
            NoOfEpochs=$(awk '/NEpochs=/ {print substr($0,12)}' $Raw_Data_Path_Run/method)  

            TaskDuration=$(echo "$Baseline_TRs + ($StimOn_TRs + $StimOff_TRs) * $NoOfEpochs" | bc)
            BlockLength=$(($StimOn_TRs + $StimOff_TRs))

            MOTION_CORRECTION $MiddleVolume G1_cp.nii.gz
            CHECK_SPIKES rG1_fsl.nii.gz

            if [ $TaskDuration == $NoOfRepetitions ]; then
                echo "It is Stimulated Scan with a total of $NoOfRepetitions Repetitions"
                TEMPORAL_SNR rG1_fsl.nii.gz
                SMOOTHING $Raw_Data_Path/$runnames/method
                
                CHECK_FILE_EXISTENCE TimeSeiesVoxels
                
                CREATING_3_COLUMNS $NoOfEpochs $Baseline_TRs $BlockLength 3

                fsleyes rG1_fsl_mean.nii.gz
                fsl_glm -i sG1_fsl.nii.gz -m rG1_fsl_mean.nii.gz -d ~/Desktop/$SequenceName.txt -o betamap --des_norm --dat_norm --demean --out_p=pmap_sm --out_z=zmap_sm
                fsl_glm -i sG1_fsl.nii.gz -d ~/Desktop/$SequenceName.txt -o betamap --des_norm --dat_norm --demean --out_p=pmap_sm --out_z=zmap_sm_withoutmask

                # TIME_SERIES $Analysed_Data_Path/$runnames''$SequenceName/NIFTI_file_header_info.txt
            
            else
                echo "It is a Baseline Scan with a total of $NoOfRepetitions Repetitions"
                TEMPORAL_SNR rG1_fsl.nii.gz
                SMOOTHING $Raw_Data_Path/$runnames/method
            fi
        
        fi
 
    done 
   
done