
#Function 1
CREATING_3_COLUMNS () {
    {  
        Total_Epochs_For_Indexing_Purpose=$(($1 - 1)) #$1 is the total no of epochs, $2 is the no of baseline stimulation TRs, $3 is the total length of an epoch, $4 is the Volume TR
        for BlockNumber in $(seq 0 1 $Total_Epochs_For_Indexing_Purpose); do
            echo "$(echo "($2 + ($3 * $BlockNumber)) * $4" | bc -l) $((5 * $4)) 1"
        done
    } > "activation_times.txt"
}

#Function 2
TIME_SERIES_VOXEL () {

    SliceDim=$(awk '/dim3/ {print $2; exit}' $1)
    PhaseDim=$(awk '/dim2/ {print $2; exit}' $1)
    ReadDim=$(awk '/dim1/ {print $2; exit}' $1)

    for slice in $(seq 1 1 $SliceDim); do 
        for phase in $(seq 1 1 $PhaseDim); do 
            for read in $(seq 1 1 $ReadDim); do 
                fslmeants -i rG1_fsl.nii.gz -o $read'_'$phase'_'$slice.txt -c $read $phase $slice;
                python $time_series $read'_'$phase'_'$slice.txt $PATH_INIT/TasksGLM/3col_$NoOfRepetitions.txt $Rows $Cols  
            done
        done
    done

}

#Function 3
TIME_SERIES () {

    fslmeants -i $1 -m $2 -o $2 # First value is the name of the input file, second value is the mask, third value is the name of the output file, fourth value is the path of the python script to analyse data. 
    python3 $4 $2 activation_times.txt $5 $Total_Epochs_For_Indexing_Purpose  $5 #fifth value is the block length i.e. no of rows in one block
    
}

