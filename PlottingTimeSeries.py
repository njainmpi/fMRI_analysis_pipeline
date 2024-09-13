import math
import sys
import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt



def DelRows(df,StartIndex,EndIndex):

    # Delete Initial Rows
    # print('Start Index: ', StartIndex)
    if StartIndex is not None and StartIndex!=0:
        df = df.drop(index=df.index[:StartIndex]).reset_index(drop=True)
        print('Length of df After removing Initial Rows: ',len(df))
    else:
        print('Start Index is None or zero.')

    # Delete End Rows
    # print('End Index: ', EndIndex)
    if EndIndex is not None and EndIndex != 0:
        df = df.drop(index=df.index[-int(EndIndex):]).reset_index(drop=True)
        # print('Length of df After removing End Rows: ', len(df))
    else:
        print('EndIndex is None or zero.')

    return df
def traverseData(inputFileName,StartIndex,EndIndex,Rows,Cols):

    #Read Text File
    # print(f'InputFileName, {inputFileName}')
    df = pd.read_csv(inputFileName, header=None)
    # print('len of df: ', str(len(df)))

    #Delete Rows
    df=DelRows(df,StartIndex,EndIndex)

    #Rows Count in df
    rowcount = df[df.columns[0]].count()
    # print('Row Count: ', rowcount)
    # print('len of df: ',str(len(df)))

    if rowcount==Rows*Cols:
        print('Rows: ', Rows)
        print('Cols: ', Cols)
    else:
        print('Invalid Rows*Cols\nCan not form an appropriate Matrix\nPlease try some other values.')
        exit()

    # reshaped_cols=np.array(df[0]).reshape( len(df) // 3 , 3 )
    reshaped_cols_arr = np.array(df[0]).reshape(Rows, Cols, order='F')
    reshaped_cols_df = pd.DataFrame(data=reshaped_cols_arr)
    # print('reshaped_cols: ', reshaped_cols_df)

    return reshaped_cols_arr,df
    #output = np.transpose(df)
    # output=output.reshape((row*col, depth))
    # print(output)
def PlotRawData(RangeRawData, InputData, StartTimes, DurationStimulationOn,filename):
    fig, ax = plt.subplots()
    ax.plot(RangeRawData, InputData, linewidth=2.0)
    ax.set(xlabel='Time (in sec)', ylabel='Raw Signal Intensity', title='Signal Intensity over time')
    major_ticks = np.arange(0, 3*(len(InputData)+1), 40)
    minor_ticks = np.arange(0, 3*(len(InputData)+1), 5)
    ax.set_xticks(major_ticks)
    ax.set_xticks(minor_ticks, minor=True)
    # ax.grid(which='both')
    # ax.grid(which='minor', alpha=0.2)
    # ax.grid(which='major', alpha=0.5)
    # for time in StartTimes:
    #     ax.axvspan(time, time+DurationStimulationOn, color='y', alpha=0.5, lw=0)
    plt.gcf()
    # print('RawSignal_'+filename)
    plt.savefig('RawSignal_'+filename)
def PlotDataOverBlocks(RangeRawData, InputData, DurationStimulationOn,filename):
    fig, ax = plt.subplots()
    ax.plot(RangeRawData, InputData, linewidth=2.0)
    ax.set(xlabel='Time (in sec)', ylabel='Raw Signal Intensity', title='Block Signal Intensity over time')
    major_ticks = np.arange(0, 3*(len(InputData)+1), 10)
    minor_ticks = np.arange(0, 3*(len(InputData)+1), 2)
    ax.set_xticks(major_ticks)
    ax.set_xticks(minor_ticks, minor=True)
    # ax.grid(which='both')
    # ax.grid(which='minor', alpha=0.2)
    # ax.grid(which='major', alpha=0.5)
    # ax.axvspan(0, DurationStimulationOn, color='y', alpha=0.5, lw=0)
    plt.gcf()
    # print('BlockDataOverTime_'+filename)
    plt.savefig('BlockDataOverTime_'+filename)
def Graph_Plot (Time, InputData, ErrorBars,filename):
    # Create the error bar plot
    
    # Convert DataFrames to NumPy arrays for easy access
    x = Time.values.flatten()   # X-axis values
    y = InputData.values.flatten()   # Y-axis values
    error = ErrorBars.values.flatten()  # Error values
    
    fig, ax = plt.subplots()
    ax.errorbar(x, y, yerr=error, xerr=None, linewidth=3.0, ecolor='red', capsize=5, capthick=2)
    ax.set_xlabel('Time (in sec)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Percent Signal Change', fontsize=14, fontweight='bold')
    ax.set_title('PSC averaged over all blocks', fontsize=16, fontweight='bold')

    ax.tick_params(axis='x', labelsize=20)  
    ax.tick_params(axis='y', labelsize=20)  
    plt.gcf()
    # Show the plot
    # plt.show()
    fig.savefig('Percent_Signal_Change_' + fileName.replace(".txt", "") + ".png", dpi=1200)


if __name__ == '__main__':

    #===================================================================================================================
    #Section 1: Intialising file and gathering parameters
    #===================================================================================================================
    #initializing command line argument
    fileName = sys.argv[1]
    Activation3ColumnFormatLoad = sys.argv[2]
    Rows = int(sys.argv[3]) #no of volumes contained in one block
    Cols = int(sys.argv[4]) #no of blocks
    
    # Activation3ColumnFormatLoad = "/Users/njain/Desktop/epi_220_vol_1sec.txt"
    Activation3ColumnFormat = np.loadtxt(Activation3ColumnFormatLoad)
    FirstBlockStartTime = int( Activation3ColumnFormat[0][0] )
    LastBlockStartTime = int( Activation3ColumnFormat[len(Activation3ColumnFormat) - 1][0] )
    DurationOfOneBlock = int( Activation3ColumnFormat[1][0] - Activation3ColumnFormat[0][0] )
    StimulusOnDuration = int( Activation3ColumnFormat[0][1] )

    # RawInputFile = "task_ts.txt" #enter the name of the file here that has to be analysed
    StartIndex=10 #enter the first timepoint or volume that needs to be analysed
    NoOfVolsToBeDeletedFromEnd=0 #enter if any number of volumes needs to be deleted from the end
    
    PSC = []

    # ===================================================================================================================
    # Section 2: Reshaping Matrices based on the parameters
    # ===================================================================================================================

 

    reshaped_arr,df=traverseData(fileName,StartIndex,NoOfVolsToBeDeletedFromEnd,Rows,Cols)
    DataOverBlocks=np.array(reshaped_arr[0:])
    RawData=np.array(df[0:])
    
    Average_Blocks = np.mean(DataOverBlocks, axis=1)
        
    # ===================================================================================================================
    # Section 3: Estimating Baseline and Computing PSC
    # ===================================================================================================================

    
    Mean_Raw_Signal = DataOverBlocks[-7:]
    # Compute the mean for each column
    Baseline_Mean_Raw_Signal = np.mean(Mean_Raw_Signal, axis=0)
    # Computing PSC
    adjusted_array = DataOverBlocks - Baseline_Mean_Raw_Signal
    adjusted_array_divided = np.divide(adjusted_array, Baseline_Mean_Raw_Signal, where=Baseline_Mean_Raw_Signal != 0)
    PSC_blocks = adjusted_array_divided * 100
    Percent_Signal_Change = np.mean(PSC_blocks, axis=1)
    
    # Compute the standard error of the mean (SEM)
    std_dev_PSC = np.std(PSC_blocks, axis=1, ddof=1)
    SEM_PSC = std_dev_PSC / np.sqrt(Cols)
    


    ## Creating an array with concatenated data
    ## Step 1: Copy the last 10 rows from the array
    PSC_last_n_rows = Percent_Signal_Change[-10:]
    zero_row = np.array([[0]])
    SEM_last_n_rows = SEM_PSC[-10:]

    # Converting arrays into DataFrame
    Percent_Signal_Change_df = pd.DataFrame(Percent_Signal_Change, columns=['Column1'])
    zero_row_df = pd.DataFrame(zero_row, columns=['Column1'])
    PSC_last_n_rows_df = pd.DataFrame(PSC_last_n_rows, columns=['Column1'])
    SEM_PSC_df = pd.DataFrame(SEM_PSC, columns=['Column1'])
    SEM_last_n_rows_df = pd.DataFrame(SEM_last_n_rows, columns=['Column1'])


    PSC_Concatenated = pd.concat([PSC_last_n_rows_df, zero_row_df, Percent_Signal_Change_df], axis=0, ignore_index=True)
    SEM_Concatenated = pd.concat([SEM_last_n_rows_df, zero_row_df, SEM_PSC_df], axis=0, ignore_index=True)
    # ===================================================================================================================
    # Section 4: Calculating Time(in sec) for x-axis for different plots
    # ===================================================================================================================


    Time_Scale = list(range(-10, 31, 1))

    # Create a DataFrame from the range
    Time_Scale_df = pd.DataFrame(Time_Scale, columns=['Numbers'])
    Time_Scale_df['Numbers'] = Time_Scale_df['Numbers'].astype(float)

    # # ===================================================================================================================
    # # Section 5: Plotting Graphs and Saving Data
    # # ===================================================================================================================

    np.savetxt('PSC_Concatenated' + fileName.replace(".txt","") + '.txt', PSC_Concatenated)
    np.savetxt('SEM_Concatenated' + fileName.replace(".txt","") + '.txt', SEM_Concatenated)
    np.savetxt('Time_Scale' + fileName.replace(".txt","") + '.txt', Time_Scale_df)
    

    
    Graph_Plot (Time_Scale_df, PSC_Concatenated, SEM_Concatenated, fileName)

    