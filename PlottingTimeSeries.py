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
def PercentSignalChange(RangeRawData, InputData, ErrorBars,DurationStimulationOn, filename):
    fig, ax = plt.subplots()
    ax.errorbar(RangeRawData, InputData, yerr=ErrorBars, linewidth=2.0, ecolor='red', elinewidth=0.5, capsize=2)
    ax.set(xlabel='Time (in sec)', ylabel='Percent Signal Change', title='PSC averaged over all blocks')
    major_ticks = np.arange(0, 3*(len(InputData)+1), 10)
    minor_ticks = np.arange(0, 3*(len(InputData)+1), 2)
    ax.set_xticks(major_ticks)
    ax.set_xticks(minor_ticks, minor=True)
    # ax.grid(which='both')
    # ax.grid(which='minor', alpha=0.2)
    # ax.grid(which='major', alpha=0.5)
    # ax.axvspan(0, DurationStimulationOn, color='y', alpha=0.5, lw=0)
    plt.gcf()
    # plt.show()
    # print('PSC_'+filename)
    plt.savefig('PSC_'+filename)
    # plt.savefig('Percent Signal Change'+fileName.replace(".txt",""))
def PercentSignalChangeConcatenated(RangeRawData, InputData, ErrorBars, DurationStimulationOn, filename):
    fig, ax = plt.subplots()
    ax.errorbar(RangeRawData, InputData, yerr=ErrorBars, linewidth=2.0, ecolor='red', elinewidth=0.5, capsize=2)
    ax.set(xlabel='Time (in sec)', ylabel='Percent Signal Change', title='PSC averaged over all blocks')
    major_ticks = np.arange(0, 1 * (len(InputData) + 8), 10)
    minor_ticks = np.arange(0, 1 * (len(InputData) + 8), 2)
    ax.set_xticks(major_ticks)
    ax.set_xticks(minor_ticks, minor=True)
    # ax.grid(which='both')
    # ax.grid(which='minor', alpha=0.2)
    # ax.grid(which='major', alpha=0.5)
    # ax.axvspan(0+21, DurationStimulationOn+21, alpha=0.5, lw=0)
    plt.gcf()
    # plt.show()
    # print('PSCC_' + filename)
    plt.savefig('PSCC_' + filename)
    np.savetxt('PSCC_' + filename + '.txt', PSC)
    # plt.savefig('Percent Signal Change'+fileName.replace(".txt",""))

if __name__ == '__main__':

    #===================================================================================================================
    #Section 1: Intialising file and gathering parameters
    #===================================================================================================================
    #initializing command line argument
    fileName = sys.argv[1]
    Activation3ColumnFormatLoad = sys.argv[2]
    Rows = int(sys.argv[3]) #no of volumes contained in one block
    Cols = int(sys.argv[4]) #no of blocks
    
    # fileName= "/Users/uqnjain/Desktop/PSC/vc_roi.txt"
    
    # voxel_fileName = sys.argv[2]
    # voxel_fileName = "/Users/uqnjain/Desktop/Project1_UTEEnhanedCBV/AnalysedData/Mouse8/Session2/7flash4msNoFlow/voxel_vc_roi.txt"
    # print('voxel_FileName: ',voxel_fileName)


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

    print('Rows: ', Rows)
    print('Cols: ', Cols)
    print("type of number Rows", type(Rows))
    print("type of number Cols", type(Cols))
    # ===================================================================================================================
    # Section 2: Reshaping Matrices based on the parameters
    # ===================================================================================================================

    reshaped_arr,df=traverseData(fileName,StartIndex,NoOfVolsToBeDeletedFromEnd,Rows,Cols)
    DataOverBlocks=np.array(reshaped_arr[0:])
    print(DataOverBlocks)
    RawData=np.array(df[0:])

    # ===================================================================================================================
    # Section 3: Calculating Time(in sec) for x-axis for different plots
    # ===================================================================================================================

    #converting volume info into time format,
    # first val is the point when first volume finishes to get acquired then based on the lenght of each block ,
    # we get the final time point of the block,
    # third part is the volume TR
    TimeScaleRawData = range(1, 1 * (len(RawData) + 1), 1)
    TimeScaleBlocks = range(1, 1 * (len(DataOverBlocks) + 1), 1)
    TimeScaleBlocksConcanate = range(1, 1*(len(DataOverBlocks)+8), 1)
    EndIndexOfABlock = len(DataOverBlocks) - 1

    # ===================================================================================================================
    # Section 4: Computing Percentage Signal Change
    # ===================================================================================================================

    # meanArrays = DataOverBlocks.mean(axis=1)    #mean values of all blocks
    df1 = pd.DataFrame(data=DataOverBlocks)
    df1_transposed = df1.transpose()

    meanArrays = [float(sum(l)) / len(l) for l in zip(*df1_transposed.values.tolist())]
    meanArrays = np.array(meanArrays)
    print('MeanArrays: ', meanArrays[EndIndexOfABlock-4:])
    BaselineVal=meanArrays[EndIndexOfABlock - 5:].mean()
    for i in meanArrays:
        PSC.append(((i - BaselineVal) / BaselineVal) * 100)
    print('PSC: ', PSC)
    print(PSC[EndIndexOfABlock-4:])
    PSC_Mean5 = np.array(PSC[EndIndexOfABlock - 5:]).mean()
    print("Baseline Mean Val", np.mean(PSC_Mean5))


    # ===================================================================================================================
    # Section 5: Computing Standard Error of Mean
    # ===================================================================================================================

    ErrorOfMean=[]
    for i in range(len(DataOverBlocks)):
        ErrorOfMean.append((np.std(PSC[i]))/math.sqrt(1))

    # ===================================================================================================================
    # Section 6: Plotting Graphs and Saving Data
    # ===================================================================================================================

    np.savetxt('PercentageSignalChange' + fileName.replace(".txt","") + '.txt',PSC)
    np.savetxt('DataOverBlocks' + fileName.replace(".txt","") + '.txt', DataOverBlocks)


    AllStartTimes = np.array(range(FirstBlockStartTime, LastBlockStartTime ,DurationOfOneBlock))    #all times when the activation start
    PlotRawData(TimeScaleRawData, RawData, AllStartTimes, StimulusOnDuration,fileName.replace(".txt",""))

    PlotDataOverBlocks(TimeScaleBlocks, DataOverBlocks, StimulusOnDuration, fileName.replace(".txt", ""))
 
    #PSC madification
    PSC2=PSC[-7:]
    PSC_final=PSC2+PSC


    ErrorOfMean2=ErrorOfMean[-7:]
    ErrorOfMeanFinal=ErrorOfMean2+ErrorOfMean

    PercentSignalChangeConcatenated(TimeScaleBlocksConcanate, PSC_final, ErrorOfMeanFinal, StimulusOnDuration, fileName.replace(".txt",""))

