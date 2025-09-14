#!/bin/bash

#Following script has been made by Naman Jain with following features included in the
#different version upgrades

##Calling all the functions that will be used in the upcoming script

#01.04.2025: Intial Script Planned, all functions called through external script


bash ../toolbox_name.sh
source ../log_execution.sh
source ../missing_run.sh
source ../folder_existence_function.sh
source ../func_parameters_extraction.sh
source ../bias_field_correction.sh
source ../check_spikes.sh
source ../coregistration.sh
source ../data_conversion.sh
source ../motion_correction.sh
source ../quality_check.sh
source ../signal_change_map.sh
source ../smoothing_using_fsl.sh
source ../temporal_snr_using_afni.sh
source ../temporal_snr_using_fsl.sh

currentpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Clear terminal before each dataset
clear

cd ..
path_for_python_script_time_course="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ts_roi_python_script=$path_for_python_script_time_course/time_course_single_subject.py

echo $ts_roi_python_script

##In order to use awk, you need to convert xlsx file to csv file


identity="$(whoami)@$(hostname)"

# Path to your data file
datafile="individual_project_based_scripts/path_definition.txt"  # replace with actual path

# Extract the matching path (3rd column)

matched_path=$(awk -v id="$identity" -F',' '
    $2 == id {
        path = $3
        for (i=4; i<=NF; i++) {
            path = path "," $i
        }
        print path
    }
' "$datafile")

echo "$matched_path"

echo "Running data anaylysis for $(whoami) on system $(hostname) with $matched_path as root location."

root_location="$matched_path"

cd "$root_location/RawData"

# Read the CSV file line by line, skipping the header
awk -F ',' 'NR>2 {print $0}' "Animal_Experiments_Sequences.csv" | while IFS=',' read -r col1 dataset_name project_name sub_project_name structural_name functional_name struc_coregistration roi_left roi_right histology physiology spio baseline_duration injection_duration _
do
    
    # Prepare log file name per dataset
    logfile="log_${dataset_name}_FuncScan_${functional_name}_Dated_$(date +%Y%m%d_%H%M%S).txt"

    # Start capturing terminal output to a log file
    {
    # Trim any extra whitespace
    project_name=$(echo "$project_name" | xargs)
    
    if [[ "$project_name" == "Project_SeroAVATar_NJ_KR" ]]; then
        export Project_Name="$project_name"
        export Sub_project_Name="$sub_project_name"
        export Dataset_Name="$dataset_name"
        export structural_run="$structural_name"
        export run_number="$functional_name"
        export str_for_coreg="$struc_coregistration"
        export baseline_duration_in_min="$baseline_duration"
        export injection_duration_in_min="$injection_duration"

echo $baseline_duration_in_min $injection_duration_in_min
exit
        # echo $Structural_Data

        Path_Raw_Data="$root_location/RawData/$project_name/$sub_project_name"
        Path_Analysed_Data="$root_location/AnalysedData/$project_name/$sub_project_name/$Dataset_Name"
 
        # Add your further processing steps here

        datapath=$(find "$Path_Raw_Data" -type d -name "*${Dataset_Name}*" 2>/dev/null)
        # echo "$datapath"     

        echo ""
        echo ""
        echo "Dataset Currently Being Analysed is $Dataset_Name" 
        echo "from $Project_Name with Subproject $Sub_project_Name"
        echo "for Structural run number $structural_run and Functional run number $run_number" 
        echo ""
        echo ""

        if [ -d "$Path_Analysed_Data" ]; then
            echo "$Path_Analysed_Data does exist."
        else
            mkdir $Path_Analysed_Data
        fi

        cd $Path_Analysed_Data

        echo ""
        echo ""

        LOG_DIR="$datapath/Data_Analysis_log" # Define the log directory where you want to store the script.
        user=$(whoami)
        log_execution "$LOG_DIR" || exit 1


        #conversion for structural data
        FUNC_PARAM_EXTARCT $datapath/$structural_run
               
        CHECK_FILE_EXISTENCE "$Path_Analysed_Data/$structural_run""$SequenceName"
        cd $Path_Analysed_Data/$structural_run''$SequenceName

        run_if_missing "anatomy.nii.gz" -- BRUKER_to_NIFTI "$datapath" "$structural_run" "$datapath/$structural_run/method"
        cp G1_cp.nii.gz anatomy.nii.gz
        echo "This data is acquired using $SequenceName"


        #conversion for functional data
        FUNC_PARAM_EXTARCT $datapath/$run_number

        echo $SequenceName

        CHECK_FILE_EXISTENCE "$Path_Analysed_Data/$run_number$SequenceName"
        cd $Path_Analysed_Data/$run_number''$SequenceName
    
        run_if_missing "G1_cp.nii.gz" -- BRUKER_to_NIFTI "$datapath" "$run_number" "$datapath/$run_number/method"
        echo "This data is acquired using $SequenceName"

  
        ## Function to perform motion correction

        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 1: Motion Correction\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Motion Correction using AFNI executed on Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing "mc_func.nii.gz" "mc_func+orig.HEAD" "mc_func+orig.BRIK" -- MOTION_CORRECTION "$MiddleVolume" G1_cp.nii.gz mc_func

        ## Function to obtain tSNR Maps
        
        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 2: Obtaining Mean func, Std func and tSNR Maps\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Temporal SNR estimated on Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing  "tSNR_mc_func.nii.gz" "tSNR_mc_func+orig.HEAD" "tSNR_mc_func+orig.BRIK" -- TEMPORAL_SNR_using_AFNI mc_func+orig

        # Function to perform Bias Field Corrections
        
        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 3: Performing N4 Bias Field Correction of mean_mc_func\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "N4Bias Field Correction on Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing  "cleaned_mc_func.nii.gz" -- BIAS_CORRECTED_IMAGE mean_mc_func.nii.gz 100 mc_func.nii.gz
        # -b (Inpout #2 in above command) [54,3] means start with 32 points scale (equiv 20mm coil divided by 0.375mm resolution) with 3rd order b-spline
       
        ## Function to Check for Spikes
        
        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 4: Checking presence of spikes in the data\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Checked for presence of spikes in the data on Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing "before_despiking_spikecountTC.png" -- CHECK_SPIKES cleaned_mc_func.nii.gz

        ## Function to remove spikes from the data
        
        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 5: Removing spikes from the data\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Checking for Spikes and Despiking Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing  "despike_cleaned_mc_func.nii.gz" -- DESPIKE despike_cleaned_mc_func.nii.gz cleaned_mc_func.nii.gz


        ## Function to perform Smoothing and clean the data to get it ready for estimating Signal change maps        
        
        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 6: Smoothing of the data - 1 or 2 voxel smoothing\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Smoothing using FSL executed on Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing  "sm_despike_cleaned_mc_func.nii.gz" -- SMOOTHING_using_FSL despike_cleaned_mc_func.nii.gz mask_mean_mc_func.nii.gz


        #Function for estimating Signal Change Maps
        

        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 7: Estimating Signal Change Maps\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Signal Change Map created for Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing  "sm_despike_cleaned_mc_func.nii.gz" -- SMOOTHING_using_FSL despike_cleaned_mc_func.nii.gz mask_mean_mc_func.nii.gz










        echo ""


        echo ""
        echo -e "\033[1;33mPerforming Step 7: Estimating Signal Change Maps\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Signal Change Map created for Run Number $run_number acquired using $SequenceName" || exit 1
        run_if_missing  "Signal_Change_Map.nii.gz" -- Signal_Change_Map cleaned_sm_despike_cleaned_mc_func.nii.gz "$datapath/$run_number" 


        if [[ "$SequenceName" == *"functionalEPI"* ]]; then
            run_if_missing "Signal_Change_Map.nii.gz" -- \
            SIGNAL_CHANGE_MAPS cleaned_sm_despike_cleaned_mc_func.nii.gz "$datapath/$run_number" 10 10
        elif [[ "$SequenceName" == *"FLASH"* ]]; then
            run_if_missing "Signal_Change_Map.nii.gz" -- \
            SIGNAL_CHANGE_MAPS mc_func.nii.gz 5 12 "$datapath/$run_number" 5 5 mean_mc_func.nii.gz
        else
            echo "Unknown sequence type: $SequenceName — skipping SIGNAL_CHANGE_MAPS."
        fi


        #Function for coregistration of Signal change maps to anatomical and 
        #extraction of time courses

        echo ""
        echo ""
        echo -e "\033[1;33mPerforming Step 8: Coregistration of Signal Change Maps and Getting Time Courses.\033[0m"
        echo ""
        echo ""
        log_function_execution "$LOG_DIR" "Applying coregistration for Run Number $run_number acquired using $SequenceName" || exit 1

        echo ""
        echo "Description:"
        echo "  This function performs manual alignment (coregistration) between a mean functional image"
        echo "  and a high-resolution anatomical image using ITK-SNAP for visualization and ANTs for transformation."
        echo ""
        echo "Steps:"
        echo "  1. Opens ITK-SNAP with 'mean_func' as the background and 'anatomy.nii.gz' as the overlay image."
        echo "     You are expected to perform a manual rigid alignment and save the transformation matrix"
        echo "     as 'anatomy_to_epi_mean.txt'."
        echo ""
        echo "  2. Applies the saved transformation using ANTs to bring 'mean_func' into anatomical space."
        echo "     Output file is saved as 'epi_mean_to_anatomy.nii.gz'."
        echo ""
        echo "  3. Optionally visualizes the result in FSLeyes, overlaid with another image if provided"
        echo "     as a positional argument to this function."
        echo ""
        echo "Notes:"
        echo "  - Ensure 'mean_func' and 'anatomy.nii.gz' are in your working directory."
        echo "  - The transformation matrix must be saved manually in ITK-SNAP as 'anatomy_to_epi_mean.txt'."
        echo "  - This function uses ANTs (antsApplyTransforms) and FSLeyes. Ensure they are installed and available."
        echo ""


        
        if [ -f anatomy_to_func.txt ]; then
            echo -e " \033[31mTransformation matrix\033[0m \033[32mexists.\033[0m"
        
            run_if_missing  "Coregistered_SCM.nii.gz" -- COREGISTRATION_UPSAMPLING Signal_Change_Map.nii.gz ../${str_for_coreg}*/anatomy.nii.gz anatomy_to_func.txt
             
            if ls ../${str_for_coreg}*/roi* 1> /dev/null 2>&1; then
                echo -e "\033[32mROI exists. Proceeding for ROI analysis\033[0m"
            else
                echo -e "\033[31mROI does not exist.\033[0m"
                echo -e "\033[31mCreate ROIs on Structural Image.\033[0m"

                echo -e "\033[31mCreate Mask on Structural Image to filter Signal Change Maps.\033[0m"
                fslmaths anatomy.nii.gz -thrp 30 -bin initial_anatomy

                echo -e "\033[31mSave it by the name cleaned_anatomy_mask\033[0m"

                fsleyes ../${str_for_coreg}*/anatomy.nii.gz
                fslmaths Coregistered_SCM.nii.gz -mas mask_${input_file} cleaned_Coregistered_SCM
            fi

            for roi_file in ../${str_for_coreg}*/roi*; do
                
                # Skip if no files match (avoid literal 'roi*' when no match)
                [ -e "$roi_file" ] || continue

                echo -e "\033[31mRunning coregistration\033[0m on \033[32m$roi_file\033[0m"
                COREGISTRATION_ROI "$roi_file" cleaned_N4_mean_mc_func.nii.gz anatomy_to_func.txt
            done

        else
            echo -e " \033[31mYour transformation file does not exist. Create a new one using ITK-Snap.\033[0m"
            echo -e " Please save your \033[31mtransformation matrix\033[0m as: \033[32manatomy_to_func.txt\033[0m"
            
            return
        fi
    fi
exit
    } | tee "$logfile"  # Save all output from this block and also show on screen

    # Clear terminal after each dataset
  


    if [ -d $All_Logs/$project_name ]; then

        mv $logfile All_Logs/$project_name.
    else 
        mkdir All_Logs/$project_name.
        mv $logfile All_Logs/$project_name.
    fi

done



