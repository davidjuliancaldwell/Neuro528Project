
clear all
close all
clc
animal_number = 1711;

%%
data_path = pwd;               
sessionObj = classGUI_buildStructObj(data_path, animal_number, 1, 0);

TRIAL_DATA.GBL_trial_number             = sessionObj.DATA.GBL_trial_number;
TRIAL_DATA.GBL_STATE_MACHINE            = sessionObj.DATA.GBL_STATE_MACHINE;
TRIAL_DATA.GBL_stimulation_enabled      = sessionObj.DATA.GBL_stimulation_enabled;
TRIAL_DATA.GBL_subjectTouchingHandle    = sessionObj.DATA.GBL_subjectTouchingHandle;
TRIAL_DATA.GBL_subjectTouchingSipper    = sessionObj.DATA.GBL_subjectTouchingSipper;

TRIAL_DATA.time_tstamp_msec             = sessionObj.DATA.time_tstamp_msec;

TRIAL_DATA.GBL_Current_Target           = sessionObj.DATA.GBL_Current_Target;
TRIAL_DATA.GBL_x_axis                   = sessionObj.DATA.GBL_x_axis;
TRIAL_DATA.GBL_y_axis                   = sessionObj.DATA.GBL_y_axis;


%% Load neural Data
load('neuralSpikeFiringRates_Animal_1713')


%% Data
samplingRate = 1000;    % Hz

timeStamps    = TRIAL_DATA.time_tstamp_msec;
trialNumber   = TRIAL_DATA.GBL_trial_number;
joystick_XPos = TRIAL_DATA.GBL_x_axis;
joystick_YPos = TRIAL_DATA.GBL_y_axis;
stateMachine  = TRIAL_DATA.GBL_STATE_MACHINE;

target = TRIAL_DATA.GBL_Current_Target;


%% Plot
% figure
%     plot(neuralSpikeFiringRates(:, 20000:end)')

%% STA

event_enter_target0 = [0 diff(target' == 0) > 0];
event_leave_target0 = [0 diff(target' == 0) < 0];

event_enter_target1 = [0 diff(target' == 1) > 0];
event_leave_target1 = [0 diff(target' == 1) < 0];

event_enter_target2 = [0 diff(target' == 2) > 0];
event_leave_target2 = [0 diff(target' == 2) < 0];


%%
% Find spike events
spikeEvent_idx = find(event_leave_target1)';
num_spikeEvents = length(spikeEvent_idx);

N = length(neuralSpikeFiringRates(1, :));
bin_size = 0.200;
% Calculate window size
bin_idx_size = floor(bin_size*samplingRate);
bin_idx = [0:bin_idx_size]-bin_idx_size/2;

% Generate matrix of all bin indices
mat_idx = repmat(bin_idx, [num_spikeEvents 1]);
% Generate matrix of all spike events in rows
stimEvent_mat = repmat(spikeEvent_idx, [1 bin_idx_size+1]);

% Add matrices together for final indexing
stimEventMat_idx = stimEvent_mat + mat_idx;

% Remove invalide indices (either averages hanging off the front or back)
invalid_idx = any(stimEventMat_idx' < 1) | ...
              any(stimEventMat_idx' > N);
stimEventMat_idx(invalid_idx, :) = [];

sta = [];
for chan = 1:16,
    stimValues = neuralSpikeFiringRates(chan,:); 
    
    % Generate matrix of stimulus values in a given window
    stimEventMat = stimValues(stimEventMat_idx);

    %Calculate STA
    sta(chan,:) = mean(stimEventMat);
end

figure
    hold all
    plot(sta');





