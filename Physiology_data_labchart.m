% Assuming data_block1_trans is your data array and the values are numeric

load('/Volumes/pr_ohlendorf/fMRI/RawData/PhysiologyData/RGRO_250219_0122_RN_SD_009.mat')
data_block1_trans = data_block1';
data_block1_trans(:,1) = abs(data_block1_trans(:,1));
ind = find (data_block1_trans(:,1) > 1);
first_idx  = ind(6,1);
last_idx   = ind(size(ind, 1), 1);
time = 0:0.01:(size (ind, 1) - 4);
time=time';

%%extracting Index Number for Heart Rate
valCells = cellstr(titles_block1);
trimmedVal = strtrim(valCells);
index_heartrate = find(strcmp(trimmedVal, 'MO Heartrate'));


% Find the first index where the value in column 1 is greater than 1
first_idx = find(data_block1_trans(:,1) > 1.5, 1, 'first');

% Find the last index where the absolute value in column 1 is greater than 1.5
last_idx = find(abs(data_block1_trans(:,1)) > 1.5, 1, 'last');

% Check if such indexes exist and process accordingly
if isempty(first_idx)
    disp('No value greater than 1 found in column 1');
elseif isempty(last_idx)
    disp('No value with magnitude greater than 1.5 found in column 1');
else
    % Select all rows from the first index to the last index
    filtered_data = data_block1_trans(first_idx:last_idx, :);
    disp(filtered_data);
end
    % Plotting section
    figure; 
    plot(filtered_data(:, index_heartrate)); 
    ylabel('Values from Column 1'); 
    set(gca, 'FontSize', 40, 'FontWeight', 'bold');
    set(gcf, 'color', 'w');
    xlabel('Time (in sec)');
    ylabel('Heart Rate (in bpm)'); 


    figFileName = '~/Desktop/heart_rate_figure'; % Change the path and filename as necessary

    % Save the figure as a .fig file
    saveas(gcf, [figFileName '.fig']);


