
clear all
close all
clc
% use 1712 for presentation
animal_number = 1712;

%%
data_path = pwd;
sessionObj = classGUI_buildStructObj(data_path, animal_number, 1, 0);

TRIAL_DATA.GBL_trial_number             = sessionObj.DATA.GBL_trial_number;
TRIAL_DATA.GBL_target                   = sessionObj.DATA.GBL_TARGET;
TRIAL_DATA.GBL_STATE_MACHINE            = sessionObj.DATA.GBL_STATE_MACHINE;
TRIAL_DATA.GBL_stimulation_enabled      = sessionObj.DATA.GBL_stimulation_enabled;
TRIAL_DATA.GBL_subjectTouchingHandle    = sessionObj.DATA.GBL_subjectTouchingHandle;
TRIAL_DATA.GBL_subjectTouchingSipper    = sessionObj.DATA.GBL_subjectTouchingSipper;

TRIAL_DATA.time_tstamp_msec             = sessionObj.DATA.time_tstamp_msec;

TRIAL_DATA.GBL_Current_Target           = sessionObj.DATA.GBL_Current_Target;
TRIAL_DATA.GBL_x_axis                   = sessionObj.DATA.GBL_x_axis;
TRIAL_DATA.GBL_y_axis                   = sessionObj.DATA.GBL_y_axis;


%% Load neural Data
load('neuralSpikeFiringRates_Animal_1712')


%% Data
samplingRate = 1000;    % Hz

timeStamps    = TRIAL_DATA.time_tstamp_msec;
trialNumber   = TRIAL_DATA.GBL_trial_number;
joystick_XPos = TRIAL_DATA.GBL_x_axis;
joystick_YPos = TRIAL_DATA.GBL_y_axis;
stateMachine  = TRIAL_DATA.GBL_STATE_MACHINE;

target = TRIAL_DATA.GBL_Current_Target;
answer = TRIAL_DATA.GBL_target;

%% STA

event_enter_target0 = [0 diff(target' == 0) > 0];
event_leave_target0 = [0 diff(target' == 0) < 0];

event_enter_target1 = [0 diff(target' == 1) > 0];
event_leave_target1 = [0 diff(target' == 1) < 0];

event_enter_target2 = [0 diff(target' == 2) > 0];
event_leave_target2 = [0 diff(target' == 2) < 0];

% for all of in target

correct_target = [0; diff(target == answer & target ~= -1) > 0 ];
incorrect_target = [0 ; diff(target ~= answer & target ~= -1)  > 0 ];
%enter_target = [0; diff(target ~= -1) > 0];
enter_target = [0; diff( (target == 0) | (target == 1) | (target == 2) ) > 0];

% get random indices 
sampling_vector = [1:length(correct_target)];
num_indices = sum(correct_target)+sum(incorrect_target);
random_indices = datasample(sampling_vector,10*num_indices)';

%% all targets
textprogressbar('Doing plots ')
num_plots = 4;
z = 1;
% Update Progress Bar
textprogressbar((z/num_plots)*100);

spikeEvent_idx = find(enter_target);

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

% single trials

figure

num_points = length(stimEventMat_idx(1,:));
t = [-num_points/2 : num_points/2-1];

for chan = 1:16
    stimValues = neuralSpikeFiringRates(chan,:);
    
    % Generate matrix of stimulus values in a given window
    stimEventMat = stimValues(stimEventMat_idx);
    
    % plot single trials
    subplot(8,2,chan)
    plot(t,stimEventMat)
    title(['Channel ' num2str(chan)])
    vline(0)
    
    %Calculate STA
    sta(chan,:) = mean(stimEventMat);
    set(gca,'FontSize',12)
end

xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')


figure('units','inches')
leg = {};
colorsChoices = distinguishable_colors(16);
for i = 1:size(sta,1)
    plot(t,sta(i,:),'linewidth',2,'Color',[colorsChoices(i,:)]);
    leg{i} = num2str(i);
    hold on
end

vline(0)
set(gca,'FontSize',12)

title({'Event-triggered average for all channels', 'entering any target'})
xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')
lgd = legend(leg,'Location','northwest');
title(lgd,'Channel')

%Get coordinates of figure:

pos = get(gcf,'pos');
%Adjust width and height of figure:

set(gcf,'pos',[3 3 8 8])

txt1 = '\leftarrow entering target';
x1 = 3;
y1 = max(sta(:))/8;
text(x1,y1,txt1,'FontSize',14)
%SaveFig('C:\Users\djcald\SharedCode\Neuro528Project', 'any_target', 'png', '-r600');


%% correct
z = z + 1;
textprogressbar((z/num_plots)*100);

% Find spike events
%spikeEvent_idx = find(event_leave_target0)';

spikeEvent_idx = find(correct_target);

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

% single trials

figure

num_points = length(stimEventMat_idx(1,:));
t = [-num_points/2 : num_points/2-1];

for chan = 1:16
    stimValues = neuralSpikeFiringRates(chan,:);
    
    % Generate matrix of stimulus values in a given window
    stimEventMat = stimValues(stimEventMat_idx);
    
    % plot single trials
    subplot(8,2,chan)
    plot(t,stimEventMat)
    title(['Channel ' num2str(chan)])
    vline(0)
    
    %Calculate STA
    sta(chan,:) = mean(stimEventMat);
    set(gca,'FontSize',12)
end

xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')


figure('units','inches')
leg = {};
colorsChoices = distinguishable_colors(16);
for i = 1:size(sta,1)
    plot(t,sta(i,:),'linewidth',2,'Color',[colorsChoices(i,:)]);
    leg{i} = num2str(i);
    hold on
    
end

vline(0)
set(gca,'FontSize',12)

title({'Event-triggered average for all channels', 'entering a correct target'})
xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')
lgd = legend(leg,'Location','northwest');
title(lgd,'Channel')

%Get coordinates of figure:

pos = get(gcf,'pos');
%Adjust width and height of figure:

set(gcf,'pos',[3 3 8 8])

txt1 = '\leftarrow entering target';
x1 = 3;
y1 = max(sta(:))/8;
text(x1,y1,txt1,'FontSize',14)
%SaveFig('C:\Users\djcald\SharedCode\Neuro528Project', 'correct_target', 'png', '-r600');


%% incorrect
z = z + 1;
textprogressbar((z/num_plots)*100);

spikeEvent_idx = find(incorrect_target);

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

% single trials

figure


for chan = 1:16
    stimValues = neuralSpikeFiringRates(chan,:);
    
    % Generate matrix of stimulus values in a given window
    stimEventMat = stimValues(stimEventMat_idx);
    
    % plot single trials
    subplot(8,2,chan)
    plot(t,stimEventMat)
    title(['Channel ' num2str(chan)])
    vline(0)
    
    %Calculate STA
    sta(chan,:) = mean(stimEventMat);
    set(gca,'FontSize',12)
end

xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')


figure('units','inches')
leg = {};
colorsChoices = distinguishable_colors(16);
for i = 1:size(sta,1)
    plot(t,sta(i,:),'linewidth',2,'Color',[colorsChoices(i,:)]);
    leg{i} = num2str(i);
    hold on
end

vline(0)
set(gca,'FontSize',12)

title({'Event-triggered average for all channels', 'entering an incorrect target'})
xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')
lgd = legend(leg,'Location','northwest');
title(lgd,'Channel')

%Get coordinates of figure:

pos = get(gcf,'pos');
%Adjust width and height of figure:

set(gcf,'pos',[3 3 8 8])

txt1 = '\leftarrow entering target';
x1 = 3;
y1 = max(sta(:))/8;
text(x1,y1,txt1,'FontSize',14)
%SaveFig('C:\Users\djcald\SharedCode\Neuro528Project', 'incorrect_target', 'png', '-r600');

% save max value for subsequent plotting of random generated vectors 
max_value = max(sta(:));
%% baseline
z = z + 1;
textprogressbar((z/num_plots)*100);

num_spikeEvents = length(random_indices);

N = length(neuralSpikeFiringRates(1, :));
bin_size = 0.200;
% Calculate window size
bin_idx_size = floor(bin_size*samplingRate);
bin_idx = [0:bin_idx_size]-bin_idx_size/2;

% Generate matrix of all bin indices
mat_idx = repmat(bin_idx, [num_spikeEvents 1]);
% Generate matrix of all spike events in rows
stimEvent_mat = repmat(random_indices, [1 bin_idx_size+1]);

% Add matrices together for final indexing
stimEventMat_idx = stimEvent_mat + mat_idx;

% Remove invalide indices (either averages hanging off the front or back)
invalid_idx = any(stimEventMat_idx' < 1) | ...
    any(stimEventMat_idx' > N);
stimEventMat_idx(invalid_idx, :) = [];

sta = [];

% single trials

figure


for chan = 1:16
    stimValues = neuralSpikeFiringRates(chan,:);
    
    % Generate matrix of stimulus values in a given window
    stimEventMat = stimValues(stimEventMat_idx);
    
    % plot single trials
    subplot(8,2,chan)
    plot(t,stimEventMat)
    title(['Channel ' num2str(chan)])
    vline(0)
    
    %Calculate STA
    sta(chan,:) = mean(stimEventMat);
    set(gca,'FontSize',12)
end

xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')


figure('units','inches')
leg = {};
colorsChoices = distinguishable_colors(16);
for i = 1:size(sta,1)
    plot(t,sta(i,:),'linewidth',2,'Color',[colorsChoices(i,:)]);
    leg{i} = num2str(i);
    hold on
end

set(gca,'FontSize',12)
ylim([0 max_value])
vline(0)

title({'Random event-triggered average for all channels'})
xlabel('time (ms)')
ylabel('Firing Rate (Arbitrary Units)')
lgd = legend(leg,'Location','northwest');
title(lgd,'Channel')

%Get coordinates of figure:

pos = get(gcf,'pos');
%Adjust width and height of figure:

set(gcf,'pos',[3 3 8 8])

txt1 = '\leftarrow entering target';
x1 = 3;
y1 = 7*max_value/8;
text(x1,y1,txt1,'FontSize',14)
SaveFig('C:\Users\djcald\SharedCode\Neuro528Project', 'baseline', 'png', '-r600');

textprogressbar('  Finished.')

