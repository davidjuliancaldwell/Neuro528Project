
% clear all
% close all
% clc
animal_number = 1712;

%%
data_path = pwd;               
sessionObj = classGUI_buildStructObj(data_path, animal_number, 1, 0);

TRIAL_DATA.GBL_trial_number             = sessionObj.DATA.GBL_trial_number;
TRIAL_DATA.GBL_STATE_MACHINE            = sessionObj.DATA.GBL_STATE_MACHINE;
TRIAL_DATA.GBL_stimulation_enabled      = sessionObj.DATA.GBL_stimulation_enabled;
TRIAL_DATA.GBL_subjectTouchingHandle    = sessionObj.DATA.GBL_subjectTouchingHandle;
TRIAL_DATA.GBL_subjectTouchingSipper    = sessionObj.DATA.GBL_subjectTouchingSipper;
TRIAL_DATA.GBL_x_axis                   = sessionObj.DATA.GBL_x_axis;
TRIAL_DATA.GBL_y_axis                   = sessionObj.DATA.GBL_y_axis;
TRIAL_DATA.time_tstamp_msec             = sessionObj.DATA.time_tstamp_msec;


%% Load MRLT Data
% data_files       = dir(data_file_path);   
% valid_data_files = strfind({data_files.name}, 'MLRT_DATA');
% valid_ind        = ~cellfun(@isempty, valid_data_files);
% data_files       = data_files(valid_ind);
% num_data_files   = length(data_files);
% 
% fullFilePath = [data_file_path '/' data_files(1).name];
% load(fullFilePath);
% TRIAL_DATA = dataStruct;


%% Load TDT ADC
data_file_path     = [data_path '/' 'SUBJECT_' num2str(animal_number) '/Block-1'];

data_files       = dir(data_file_path);   
valid_data_files = strfind({data_files.name}, 'Adc1');
valid_ind        = ~cellfun(@isempty, valid_data_files);
data_files       = data_files(valid_ind);
num_data_files   = length(data_files);

ADC1_DATA = [];
fullFilePath = [data_file_path '/' data_files(1).name];
load(fullFilePath);
ADC1_DATA = dataStruct.data';

fullFilePath = [data_file_path '/' data_files(2).name];
load(fullFilePath);
ADC1_DATA(2,:) = dataStruct.data';


%% Get TDT Path Names
data_files       = dir(data_file_path);   
valid_data_files = strfind({data_files.name}, 'Wave');
valid_ind        = ~cellfun(@isempty, valid_data_files);
data_files       = data_files(valid_ind);
num_data_files   = length(data_files);


%% Load 
% textprogressbar('Loading: ')
% 
% CHAN_DATA = [];
% for index = 1:num_data_files,    
%     fullFilePath = [data_file_path '/' data_files(index).name];
%     
%     load(fullFilePath);
%     CHAN_DATA(index,:) = dataStruct.data;
%     
%     % Status
%     textprogressbar(index/num_data_files*100);
% end
% textprogressbar('  Finished.') 


%% Filter
% fs = dataStruct.fs;
% f_top = 5000;
% f_bot = 100;
% 
% [b_stop, a_stop] = butter(3,[f_bot/(fs/2) f_top/(fs/2)], 'stop');
% 
% textprogressbar('BandPass Filter: ')
% for index = 1:num_data_files,    
%     dataIn = CHAN_DATA(index,:);
%     dataOut = filter(b_stop, a_stop, dataIn);
%     
%     CHAN_DATA(index,:) = dataOut;
%     
%     % Status
%     textprogressbar(index/num_data_files*100);
% end
% textprogressbar('  Finished.') 


%% Threshold
% textprogressbar('Firing Rate: ')
% 
% CHAN_DATA_spikeTimes = [];
% for index = 1:num_data_files,
%     dataIn = CHAN_DATA(index,:);
%     
%     threshold = std(dataIn((10^6):end-(10^6)))*1;
%     
%     posValues = dataIn > threshold;
%     posValueArea = bwlabel(posValues);
%     
%     spikeIndices = diff(posValueArea) > 0;
%     
%     CHAN_DATA_spikeTimes(index,:) = spikeIndices;
%     
%     % Status
%     textprogressbar(index/num_data_files*100);
% end
% textprogressbar('  Finished.')


%% Reconcile Timeseries
N_1 = length(TRIAL_DATA.time_tstamp_msec);
N_2 = length(ADC1_DATA(2,:));

fs_1 = 1000;
fs_2 = dataStruct.fs;

ts_1 = TRIAL_DATA.time_tstamp_msec./1000;
ts_2 = linspace(0, (N_2-1)/fs_2, N_2)';

% Trial Number Vectors
trainer_TrialNum = TRIAL_DATA.GBL_trial_number;

TDT_TrialNum = ADC1_DATA(2,:);
TDT_TrialNum = bwlabel(TDT_TrialNum);
TDT_TrialNum = [0 diff(TDT_TrialNum) > 0];
TDT_TrialNum = cumsum(TDT_TrialNum);
TDT_TrialNum = TDT_TrialNum + 1;

if max(TDT_TrialNum) ~= max(trainer_TrialNum)
    error('Time Series Not Aligned')
end
numTrials = max(TDT_TrialNum);


%% Align Timeseries 

% Index of Trial 1
trial2_idx = find(trainer_TrialNum > 1, 1, 'first');
ts_1 = ts_1 - ts_1(trial2_idx);

trial2_idx = find(TDT_TrialNum > 1, 1, 'first');
ts_2 = ts_2 - ts_2(trial2_idx);

trainer_trialEnd_idx = find(trainer_TrialNum > numTrials-1, 1, 'first');
TDT_trialEnd_idx = find(TDT_TrialNum > numTrials-1, 1, 'first');

% Ratio
ts_1(trainer_trialEnd_idx)/ts_2(TDT_trialEnd_idx);


%% Plot
% figure
%     hold all
%     
%     ydata = trainer_TrialNum;
%     xdata = ts_1';
%     mask = xdata>=0 & xdata < 1000;
%     plot(xdata(mask), ydata(mask), 'r');
%     
%     ydata = TDT_TrialNum;
%     xdata = ts_2';
%     mask = xdata>=0 & xdata < 1000;
%     plot(xdata(mask), ydata(mask), 'b');


%% Trial Num Downsampling
[~, binInd] = histc(ts_2.*1000, ts_1.*1000);
TDT_TrialNum_binned = accumarray(binInd, TDT_TrialNum(1:end), [], @mean);
left_over_samples = (length(ts_1)-length(TDT_TrialNum_binned));
ts_2_new = ts_1(1:end-left_over_samples);


%% Plot
figure
    hold all
    
    ydata = trainer_TrialNum;
    xdata = ts_1';
    mask = xdata>=0 & xdata < 1000;
    plot(xdata(mask), ydata(mask), 'r');
    
    ydata = TDT_TrialNum_binned;
    xdata = ts_2_new';
    mask = xdata>=0 & xdata < 1000;
    plot(xdata(mask), ydata(mask), 'b');


%% Downsample (Bin spike Times)
% textprogressbar('Binning: ');
% 
% CHAN_DATA_spikeTimes_binned = [];
% for index = 1:num_data_files,
%     dataIn = CHAN_DATA_spikeTimes(index,:);
%     
% %     dummy_ts = [0:1/fs:1-1/fs].*1000;
% %     dummy_dataIn = dataIn(1:length(dummy_ts));
% %     
% %     dummy_newTs = [0:1000];
% %     [~, binInd] = histc(dummy_ts, dummy_newTs);
% %     dataOut = accumarray(binInd', dummy_dataIn);
%     
%     [~, binInd] = histc(ts_2.*1000, ts_1.*1000);
%     dataOut = accumarray(binInd, dataIn);
%     
%     CHAN_DATA_spikeTimes_binned(index,:) = dataOut;
%     
%     % Status
%     textprogressbar(index/num_data_files*100);
% end
% textprogressbar('  Finished.');


%% Smoothing
% textprogressbar('Smoothing: ');
% 
% for index = 1:num_data_files,
%     dataIn = CHAN_DATA_spikeTimes_binned(index,:);
%     
%     window_size = 100; %ms
%     dataOut = smooth(dataIn, window_size);
%     
%     CHAN_DATA_spikeTimes_binned(index,:) = dataOut;
%     
%     % Status
%     textprogressbar(index/num_data_files*100);
% end
% textprogressbar('  Finished.');


%% Data
samplingRate = 1000;    % Hz

timeStamps    = ts_1;
trialNumber   = trainer_TrialNum;
joystick_XPos = TRIAL_DATA.GBL_x_axis;
joystick_YPos = TRIAL_DATA.GBL_y_axis;
stateMachine  = TRIAL_DATA.GBL_STATE_MACHINE;

% Neural Sample is 'left_over_samples' less than trainer samples
timeStamps_neural = timeStamps(1:end-left_over_samples);
neuralSpikeFiringRates = CHAN_DATA_spikeTimes_binned;


%% Plot
figure
    plot(neuralSpikeFiringRates(:, 20000:end)')





