#!/bin/sh


#07th August 2024: $$Naman Jain$$ This function is created get activation maps using AFNI through CLI

# ** Step 1: From a training dataset, generate activation map.
#   The input dataset has 1 runs, each variable and the time 
#   points longinformation comes from the method file .  3dDeconvolve
#   is used to generate the activation map.  There is one visual stimuli.

ACTIVATION_MAPS () {

3dDeconvolve -input $1 \
             -num_stimts 1 \
             -stim_times 1 $2 'BLOCK($3,1)' \
             -stim_label 1 Stimulus \
             -fout -tout \
             -bucket stats_sm_mc_stc_func \
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