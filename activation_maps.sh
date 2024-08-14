#!/bin/sh


#07th August 2024: $$Naman Jain$$ This function is created get activation maps using AFNI through CLI

# ** Step 1: From a training dataset, generate activation map.
#   The input dataset has 1 runs, each variable and the time 
#   points longinformation comes from the method file .  3dDeconvolve
#   is used to generate the activation map.  There is one visual stimuli.

  3dDeconvolve -x1D xout_short_two.1D -input sG1_fsl.nii.gz   \
      -num_stimts 1                                                   \
      -stim_file 1 test.txt        -stim_label 1 Somatosensory_Cortex \
      -mask rG1_fsl_mean_mask.nii.gz                                  \
      -full_first -fout -tout                                         \
      -bucket func_ht2_short_two -cbucket cbuc_ht2_short_two

  N.B.: You may want to de-spike, smooth, and register the 3D+time
        dataset prior to the analysis (as usual).  These steps are not
        shown here -- I'm presuming you know how to use AFNI already.

** Step 2: Create a mask of highly activated voxels.
  The F statistic threshold is set to 30, corresponding to a voxel-wise
  p = 1e-12 = very significant.  The mask is also lightly clustered, and
  restricted to brain voxels.

  3dAutomask -prefix Amask rall_vr+orig
  3dcalc -a 'func_ht2_short+orig[0]' -b Amask+orig -datum byte \
         -nscale -expr 'step(a-30)*b' -prefix STmask300
  3dmerge -dxyz=1 -1clust 1.1 5 -prefix STmask300c STmask300+orig

** Step 3: Run 3dInvFMRI to estimate the stimulus functions in run #4.
  Run #4 is time points 324..431 of the 3D+time dataset (the -data
  input below).  The -map input is the beta weights extracted from
  the -cbucket output of 3dDeconvolve.

  3dInvFMRI -mask STmask300c+orig                       \
            -data rall_vr+orig'[324..431]'              \
            -map cbuc_ht2_short_two+orig'[6..7]'        \
            -polort 1 -alpha 0.01 -median5 -method K    \
            -out ii300K_short_two.1D

  3dInvFMRI -mask STmask300c+orig                       \
            -data rall_vr+orig'[324..431]'              \
            -map cbuc_ht2_short_two+orig'[6..7]'        \
            -polort 1 -alpha 0.01 -median5 -method C    \
            -out ii300C_short_two.1D

** Step 4: Plot the results, and get confused.

  1dplot -ynames VV KK CC -xlabel Run#4 -ylabel ComplexStim \
         hrf_complex.1D'{324..432}'                         \
         ii300K_short_two.1D'[0]'                           \
         ii300C_short_two.1D'[0]'

  1dplot -ynames VV KK CC -xlabel Run#4 -ylabel SimpleStim \
         hrf_simple.1D'{324..432}'                         \
         ii300K_short_two.1D'[1]'                          \
         ii300C_short_two.1D'[1]'

  N.B.: I've found that method K works better if MORE voxels are
        included in the mask (lower threshold) and method C if
        FEWER voxels are included.  The above threshold gave 945
        voxels being used to determine the 2 output time series.
=========================================================================

++ Compile date = Jul 16 2024 {AFNI_24.2.01:linux_ubuntu_16_64}
