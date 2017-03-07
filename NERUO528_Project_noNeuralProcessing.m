
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
TRIAL_DATA.GBL_x_axis                   = sessionObj.DATA.GBL_x_axis;
TRIAL_DATA.GBL_y_axis                   = sessionObj.DATA.GBL_y_axis;
TRIAL_DATA.time_tstamp_msec             = sessionObj.DATA.time_tstamp_msec;


%% Load neural Data
load('neuralSpikeFiringRates_Animal_1711')


%% Data
samplingRate = 1000;    % Hz

timeStamps    = TRIAL_DATA.time_tstamp_msec;
trialNumber   = TRIAL_DATA.GBL_trial_number;
joystick_XPos = TRIAL_DATA.GBL_x_axis;
joystick_YPos = TRIAL_DATA.GBL_y_axis;
stateMachine  = TRIAL_DATA.GBL_STATE_MACHINE;


%% Plot
figure
    plot(neuralSpikeFiringRates(:, 20000:end)')





