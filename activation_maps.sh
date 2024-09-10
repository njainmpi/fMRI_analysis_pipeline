#!/bin/sh


#07th August 2024: $$Naman Jain$$ This function is created get activation maps using AFNI through CLI
#17th August 2024: $$Naman Jain$$ Creating Signal change maps
#19th August 2024: $$Naman Jain$$ Adding a function for threhsholding images
#03rd September 2024: $$Naman Jain$$ Making a new function to estimate time courses

# ** Step 1: From a training dataset, generate activation map.
#   The input dataset has 1 runs, each variable and the time 
#   points longinformation comes from the method file .  3dDeconvolve
#   is used to generate the activation map.  There is one visual stimuli.
time_series="/Users/njain/Desktop/Github/fMRI_analysis_pipeline/PlottingTimeSeries.py"

STIMULUS_TIMING_CREATION () {
  Total_Epochs_For_Indexing_Purpose=$(($1 - 1)) #$1 is the total no of epochs, $2 is the no of baseline stimulation TRs, $3 is the total length of an epoch, $4 is the Volume TR
  Total_Epochs_For_Indexing_Purpose=6
  offset=$3
       for BlockNumber in $(seq 0 1 $Total_Epochs_For_Indexing_Purpose); do
           result=$(( ($2 * $BlockNumber) + offset )) # $2 is the block length
           echo "$result " >> "$4"
       done
}

ACTIVATION_MAPS () {

      local block_duration=$3
      3dDeconvolve -input $1 \
            -num_stimts 1 \
            -stim_times 1 $2 "BLOCK(${block_duration},1)" \
            -stim_label 1 Stimulus \
            -fout -tout \
            -bucket $4 \
            -cbucket coefficients_sm_mc_stc_func

}

# Explanation of the Parameters

# -input $1: Specifies your fMRI data file.
# -num_stimts 1: Indicates that there is one stimulus timing file.
# -stim_times 1 $2 'BLOCK(6,1)':
#      1 is the stimulus index.
#      $2 is the file containing the stimulus onset times.
#      'BLOCK($3,1)' models the hemodynamic response with a block design, where each stimulus lasts for 'n' seconds.
# -stim_label 1 Stimulus: Labels this stimulus as "Stimulus."
# -fout -tout: Outputs the F-statistics and t-statistics for the regressor.
# -bucket stats_output_subject1: Specifies the output file for statistical results.
# -cbucket coefficients_output_subject1: Specifies the output file for beta coefficients.
 

# Running the Command
# Copy and paste the command into your terminal where AFNI is installed and execute it. This will produce statistical maps (stats_output_subject1) and coefficient maps (coefficients_output_subject1).

# Interpreting the Output
# stats_sm_mc_stc_func+orig.BRIK/HEAD: This will contain F-statistics and t-statistics maps that show the significance of the activation at each voxel.
# stats_sm_mc_stc_func+orig.BRIK/HEAD: This file will contain the beta coefficients, representing the amplitude of the response at each voxel.

SIGNAL_CHANGE_MAPS () {

  3dTstat -mean -prefix mean_baseline $1[0..9]
  file_list=""

  # Loop to compute the mean of every 5 images from 11 to 140
  for i in $(seq 10 5 $(($2 - 4))); do
    end=$((i+4))  # Define the end index for the 5 images
    output_prefix="mean_${i}_to_${end}"
    3dTstat -mean -prefix ${output_prefix} $1[${i}..${end}]
    3dcalc -a ${output_prefix}+orig -b mean_baseline+orig -expr 'a-b' -prefix ${output_prefix}_sig_change
    3dcalc -a ${output_prefix}_sig_change+orig -b mean_baseline+orig -expr 'a/b' -prefix ${output_prefix}_ratio_sc
    3dcalc -a ${output_prefix}_ratio_sc+orig -expr 'a*100' -prefix ${output_prefix}_percent_sc
    file_list="${file_list} ${output_prefix}_percent_sc+orig"
    
    rm -f *ratio*
  done

echo $file_list
# Use 3dTcat to merge all files into one
3dTcat -prefix signal_change_map $file_list
}

# mean_first10.nii: The mean image from the first 10 images (indices 0 to 9).
# Loop: The loop starts at the 11th image (index 10) and increments by 5 until the 136th image (index 135).
# For each step in the loop:
# i: The starting index of the current 5-image block.
# end: The ending index of the current 5-image block.
# output_prefix: The output file name for the mean of the current block of 5 images.


# Function to apply lower and upper thresholds to a dataset
THRESHOLDING() {
    local input_dataset=$1    # The input dataset name (e.g., dataset+orig)
    local lower_thresh=$2     # The lower threshold value
    local upper_thresh=$3     # The upper threshold value
    local output_prefix=$4    # The prefix for the output dataset

    # Apply the threshold using 3dcalc
    3dcalc -a "${input_dataset}" \
           -expr "a*step(a-${lower_thresh})*step(${upper_thresh}-a)" \
           -prefix "${output_prefix}"

    3dAFNItoNIFTI "${output_prefix}"
}

# Example usage of the function:
# threshold_dataset "dataset+orig" 0 2.5 5.0 "thresholded_dataset"


TIME_COURSE_PYTHON (){

    local input_image=$1
    local mask=$2
    local output_name=$3
    local task_file=$4

    3dTstat -mean -prefix mean_baseline_time_course $1[$base_file_initial_vol..$epoch_length]
    3dAFNItoNIFTI mean_baseline_time_course+orig
    echo "Mark your ROIs for Time COurse Exctraction"
    fsleyes mean_baseline_time_course.nii

    fslmeants -i $input_image -m $mask -o $output_name

    python PlottingTimeSeries.py $output_name $task_file

}




TIME_COURSE () {


  # Define the input dataset
  local input_image=$1
  local starting_point=$2 #because of indexing issues, starting from 0
  local total_repetitions=$3
  local epoch_length=$4
  local no_of_epochs=$5

  # repetitions_for_indexing_purpose=$((total_repetitions - 1))
  # end_point=$(expr $repetitions_for_indexing_purpose - $(expr $epoch_length - 1))
  # # Initialize the counter for output files
  # counter=1

  echo "Starting point is $starting_point"
  echo "Ending point is $((total_repetitions - 1))"
 
  for i in $(seq 0 $((no_of_epochs - 1))); do
    # Calculate the starting and ending volumes for this image
    start_index=$((starting_point + i * epoch_length))
    end_index=$((start_index + epoch_length - 1))
    
    # Create the output file name
    output_file="image_part$((i + 1))"
    echo $output_file


    # Use 3dTcat to create the new image
    3dTcat -prefix $output_file $input_image[$start_index..$end_index]
  done


  # List all BRIK files and construct a string of filenames for 3dMean
  FILES=$(ls image_part*.BRIK)

  # Perform the averaging using 3dMean
  3dMean -prefix "time_course_averaged_raw_signal" $FILES

  3dAFNItoNIFTI time_course_averaged_raw_signal+orig

  # rm -f image_part*
  base_file_initial_vol=$((epoch_length - 10))
  3dTstat -mean -prefix mean_baseline_time_course $1[$base_file_initial_vol..$epoch_length]
  
    base_file="mean_baseline_time_course+orig"
    image_file="time_course_averaged_raw_signal+orig"
    n_vols=$epoch_length
    for ((i=0; i<$n_vols; i++));do
    
    # Define the output file name for the result of the subtraction for the current volume
      output_file=$(printf "result_volume%02d" $i)
       output_prefix="PSC_${i}"
    # Subtract base.BRIK from the current volume (sub-brick) using 3dcalc
      3dcalc -a ${image_file}[$i] -b ${base_file} -expr 'a-b' -prefix ${output_prefix}_base_subtracted
      3dcalc -a ${output_prefix}_base_subtracted+orig -b ${base_file} -expr 'a/b' -prefix ${output_prefix}_base_divided
      3dcalc -a ${output_prefix}_base_divided+orig -expr 'a*100' -prefix ${output_prefix}_final_PSC

      file_list="${file_list} ${output_prefix}_final_PSC+orig"
    done

    file_list="${file_list} ${output_prefix}_final_PSC+orig"
    echo $file_list
    3dTcat -prefix Time_Course_Averaged $file_list
    3dAFNItoNIFTI Time_Course_Averaged+orig
  
    rm -f *_base_subtracted* *_base_divided* *_final_PSC* image_part*
}