#!/bin/sh

#Following script has been made by Naman Jain with following features included in the
#different version upgrades

##Updating to count outliers in the image


# As per AFNI from https://afni.nimh.nih.gov/pub/dist/doc/program_help/3dToutcount.html
#  * The trend and MAD of each time series are calculated.
#    - MAD = median absolute deviation
#          = median absolute value of time series minus trend.
#  * In each time series, points that are 'far away' from the
#     trend are called outliers, where 'far' is defined by
#       alpha * sqrt(PI/2) * MAD
#       alpha = qginv(0.001/N) (inverse of reversed Gaussian CDF)
#       N     = length of time series
#  * Some outliers are to be expected, but if a large fraction of the
#     voxels in a volume are called outliers, you should investigate
#     the dataset more fully.

# $1 is the input file

SLICE_TIMING_CORRECTION () {

    3dToutcount -automask -fraction -polort 3 -legendre $1 > outlier_count.1D
    1Dplot -pnm outcount_file -DAFNI_1DPLOT_IMSIZE=8192 -xlabel 'Repetition' -ylabel 'Fraction of outliers' outlier_count.1D
    sips -s format png outcount_file.pnm --out outlier_count.png

# prefix stc is for slice timing corrected image
  
    3dTshift -tzero 0 -Fourier -prefix stc_func $1 
    3dAFNItoNIFTI stc_func+orig.BRIK 

    3dToutcount -automask -fraction -polort 3 -legendre stc_func+orig.BRIK > stc_outlier_count.1D
    1Dplot -pnm stc_outcount_file -DAFNI_1DPLOT_IMSIZE=8192 -xlabel 'Repetition' -ylabel 'Fraction of outliers' stc_outlier_count.1D
    sips -s format png stc_outcount_file.pnm --out stc_outlier_count.png

    rm -f *.pnm

}