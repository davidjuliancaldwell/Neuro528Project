
classdef Trial
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    
    %% Public Get, Private Set Properties
    properties (GetAccess = public, SetAccess = private)
        DATA        = struct;
        DATA_RAW    = [];
        FIELDS      = {};        
        
        ID_NUMBER   = -1;
        
        TARGET      = -1;
        SEL_TARGET  = -1;
        CORRECT     = -1;
        CATCH_TRIAL = -1;
        STIM_ONLY   = -1;
        SHORT_RWD   = -1;
        
        DWELL_IND     = [];
        DWELL_TIMES   = [];
        DWELL_TARGETS = [];
        
        LENGTH_TOTAL_SEC  = -1;
        LENGTH_ACTIVE_SEC = -1;
        TOTAL_TRAINING_TIME = -1;
        
        DWELL_MS   = [];
        TIMEOUT_MS = [];
    end
       
    
    %% Public Methods
    methods (Access = public)
        
        % Constructor
        function obj = Trial(trial_ID, raw_data, fields)
            if nargin > 1
                obj.ID_NUMBER = trial_ID;
            end
            
            if nargin > 1
                obj.FIELDS   = fields;
            end
            
            if nargin > 0
                obj.DATA_RAW = raw_data;
            end  
            
            obj = processRawData(obj);
            obj = processTrialProp(obj);
            obj = processTrialData(obj);
        end
        
    end

    
    %% Private Helper Functions
    methods (Access = private)
    
        % Create Vectors with Field Names 
        function obj = processRawData(obj)
            
            data = struct();
            for k = 1:length(obj.FIELDS),          % for each unique variable
                fld = obj.FIELDS{k};               % field name
                data.(fld) = obj.DATA_RAW(:,k);    % assign to field
            end
    
            obj.DATA = data;
            obj.DATA_RAW = [];
        end
               
        % Process Data About Trial
        function obj = processTrialData(obj)
            
            % Trial Starts at 0 ms
            if isfield(obj.DATA, 'time_tstamp_msec')
                time_start       = obj.DATA.time_tstamp_msec(1);
                temp_time_stamps = obj.DATA.time_tstamp_msec - time_start;
                obj.DATA.time_tstamp_msec = temp_time_stamps;
            end
            
            % Calculate Dwell Times (if VERSION < 7.0.0)
            if isfield(obj.DATA, 'GBL_JystkZone_DwellTime_LEFT_') && ...
               isfield(obj.DATA, 'GBL_JystkZone_DwellTime_RIGHT_') && ...
               isfield(obj.DATA, 'GBL_STATE_MACHINE')
           
                % Determine sequence of pulls and dwell times
                target_L_dwell = obj.DATA.GBL_JystkZone_DwellTime_LEFT_;
                target_R_dwell = obj.DATA.GBL_JystkZone_DwellTime_RIGHT_;
                
                mask_trial_running = obj.DATA.GBL_STATE_MACHINE == 1;
                start_trial_running_ind = find(obj.DATA.GBL_STATE_MACHINE == 1, 1, 'first');
                target_L_dwell_dur_trial = target_L_dwell(mask_trial_running);
                target_R_dwell_dur_trial = target_R_dwell(mask_trial_running);
                
                pull_zones_L = bwlabel(target_L_dwell_dur_trial);
                [~, pull_L_ind]     = unique(pull_zones_L, 'first');
                [~, pull_L_val_ind] = unique(pull_zones_L, 'last');
                pull_L_val = target_L_dwell_dur_trial(pull_L_val_ind);
                
                pull_zones_R = bwlabel(target_R_dwell_dur_trial);
                [~, pull_R_ind]     = unique(pull_zones_R, 'first');
                [~, pull_R_val_ind] = unique(pull_zones_R, 'last');
                pull_R_val = target_R_dwell_dur_trial(pull_R_val_ind);
                
                
                pull_ind = [pull_L_ind; pull_R_ind];
                pull_val = [pull_L_val; pull_R_val];
                pull_tID = [ones([length(pull_L_ind) 1])*0; ones([length(pull_R_ind) 1])*1];
                
                [pull_ind, sort_ind] = sort(pull_ind);
                pull_val = pull_val(sort_ind);
                pull_tID = pull_tID(sort_ind);
                
                pull_ind(pull_val == 0) = [];
                pull_tID(pull_val == 0) = [];
                pull_val(pull_val == 0) = [];
                
                obj.DWELL_IND     = pull_ind + start_trial_running_ind-1;
                obj.DWELL_TIMES   = pull_val;
                obj.DWELL_TARGETS = pull_tID;               
            end
            
            % Calculate Dwell Times (if VERSION > 7.0.0)
            if isfield(obj.DATA, 'GBL_Current_Target') && ...
               isfield(obj.DATA, 'GBL_JystkZone_DwellTime') && ...
               isfield(obj.DATA, 'GBL_STATE_MACHINE')
                
                % Create mask for when trial is running
                mask_trial_running = obj.DATA.GBL_STATE_MACHINE == 1;
                start_trial_running_ind = find(obj.DATA.GBL_STATE_MACHINE == 1, 1, 'first');
                
                % ID of target which is dwelled in
                target_id = obj.DATA.GBL_Current_Target;
                target_id_dur_trial = target_id(mask_trial_running);
                
                % Time of dwell in current target
                target_dwell = obj.DATA.GBL_JystkZone_DwellTime;
                target_dwell_dur_trial = target_dwell(mask_trial_running);
                
                % Label vector of all dwell times
                % Attempt 2
%                 temp = bwlabel([0 diff(target_dwell_dur_trial') > 0]);
%                 temp_idx_b = find([0 diff(target_dwell_dur_trial') > 10]);
%                 temp_idx_e = find([0 diff(target_dwell_dur_trial') < 0]);
%                 temp(temp_idx_e) = temp(min(length(temp), temp_idx_e+1));
%                 pull_zones = temp';

                % Attempt 1
%                 pull_zones = bwlabel(target_dwell_dur_trial);
%                 [~, pull_ind]          = unique(pull_zones, 'first');
%                 [~, pull_val_ind]      = unique(pull_zones, 'last');
                
% target_id_dur_trial    = [-1 -1 -1 1  1  1  1 -1 -1 2  2  2  2  2  1  1 -1 -1 1 1 1 1 1 1 -1 -1];
% target_dwell_dur_trial = [ 0  0  0 10 20 30 40 0  0 10 20 30 40 50 10 20 0  0 0 0 0 0 0 0  0  0];
                
                % Attempt 3
%                 pull_ind = [1; find(abs(diff(target_id_dur_trial))>0)+1];
%                 pull_ind(target_id_dur_trial(pull_ind) == -1) = [];
%                 pull_ind(target_dwell_dur_trial(pull_ind) == 0) = [];
%                 
%                 pull_val_ind = [find(abs(diff(target_id_dur_trial))>0); length(target_id_dur_trial)];
%                 pull_val_ind(target_id_dur_trial(pull_val_ind) == -1) = [];
%                 pull_val_ind(target_dwell_dur_trial(pull_val_ind) == 0) = [];
                             
                % Attempt 4
                pull_ind = [1; find(abs(diff(target_id_dur_trial))>0)+1];
                pull_ind(target_id_dur_trial(pull_ind) == -1) = [];
                
                pull_val_ind = [find(abs(diff(target_id_dur_trial))>0); length(target_id_dur_trial)];
                pull_val_ind(target_id_dur_trial(pull_val_ind) == -1) = [];
                
                for i = 1:length(pull_val_ind)
                    if target_dwell_dur_trial(pull_val_ind(i)) == 0
                        temp_dw = target_dwell_dur_trial(pull_ind(i):pull_val_ind(i));
                        [~,pull_val_ind(i)] = max(temp_dw);
                        pull_val_ind(i) = pull_val_ind(i) + pull_ind(i) -1;
                    end
                end
                pull_ind(target_dwell_dur_trial(pull_val_ind) == 0) = [];
                pull_val_ind(target_dwell_dur_trial(pull_val_ind) == 0) = [];
                
                
                % Save Values
                pull_val_init = target_dwell_dur_trial(pull_ind);
                pull_val      = target_dwell_dur_trial(pull_val_ind);
                pull_tID      = target_id_dur_trial(pull_val_ind);
                pull_length   = pull_val_ind - pull_ind;
           
                % Remove all pulls where debouncer failed
                pull_ind(pull_val_init > 2000) = [];
                pull_val(pull_val_init > 2000) = [];
                pull_tID(pull_val_init > 2000) = [];
                
                % Remove all pulls where current target is invalid (-1)
                pull_ind(pull_tID == -1) = [];
                pull_val(pull_tID == -1) = [];
                pull_tID(pull_tID == -1) = [];

                % Save All Variables in current Trial Struct
                obj.DWELL_IND     = pull_ind + start_trial_running_ind-1;
                obj.DWELL_TIMES   = pull_val;
                obj.DWELL_TARGETS = pull_tID;
            end
            
            % Length of Trial
            if isfield(obj.DATA, 'time_tstamp_msec') && ...
               isfield(obj.DATA, 'GBL_STATE_MACHINE')
                [start_ind, ~] = find(obj.DATA.GBL_STATE_MACHINE == 1, 1, 'first');
                [end_ind, ~]   = find(obj.DATA.GBL_STATE_MACHINE == 1, 1, 'last');
                
                length_ms = obj.DATA.time_tstamp_msec(end_ind) - ...
                            obj.DATA.time_tstamp_msec(start_ind);
                     
                % Total Length of Trial Running State
                obj.LENGTH_TOTAL_SEC = length_ms/1000.0;
                
                % Get Active Length
                if any(obj.DWELL_TIMES ~= -1) && ~isempty(obj.DWELL_IND)
                    active_length_ms = obj.DATA.time_tstamp_msec(end_ind) - ...
                                obj.DATA.time_tstamp_msec(obj.DWELL_IND(1));
                    
                    obj.LENGTH_ACTIVE_SEC = active_length_ms/1000.0;
                end
            end
                        
        end
        
        % Set Properties
        function obj = processTrialProp(obj)
                        
            % Target
            if isfield(obj.DATA, 'GBL_TARGET')
                obj.TARGET = obj.DATA.GBL_TARGET(end);
            end
            
            % Selected Target
            if isfield(obj.DATA, 'GBL_Selected_Target')
                obj.SEL_TARGET = obj.DATA.GBL_Selected_Target(end);
            end
                            
            % Correct
            if obj.TARGET ~= -1 && obj.SEL_TARGET ~= -1
                obj.CORRECT = obj.TARGET == obj.SEL_TARGET;
            end
            
            % Catch Trial
            if isfield(obj.DATA, 'GBL_CATCH_TRIAL')
                obj.CATCH_TRIAL = boolean(obj.DATA.GBL_CATCH_TRIAL(end));
            end
            
            % Short RWD Trial
            if isfield(obj.DATA, 'GBL_SHORT_RWD_TRIAL')
                obj.SHORT_RWD = boolean(obj.DATA.GBL_SHORT_RWD_TRIAL(end));
            end
            
            if isfield(obj.DATA, 'GBL_cue_leds_enabled')
                obj.STIM_ONLY = ~any(obj.DATA.GBL_cue_leds_enabled(:));
            else
                obj.STIM_ONLY = mod(obj.ID_NUMBER, 10) == 0;
            end
            
            if isfield(obj.DATA, 'GBL_DWELL_TIME_MS')
                obj.DWELL_MS = obj.DATA.GBL_DWELL_TIME_MS(1);
            end
             
            if isfield(obj.DATA, 'GBL_TIMEOUT_TIME_MS')
                obj.TIMEOUT_MS = obj.DATA.GBL_TIMEOUT_TIME_MS(1);
            end
            
            if (isfield(obj.DATA, 'time_tstamp_msec'))
                trial_length_ms = obj.DATA.time_tstamp_msec(end) - ...
                      obj.DATA.time_tstamp_msec(1);
                                
                obj.TOTAL_TRAINING_TIME =  trial_length_ms/1000.0;
            end
        end
    end    
    
end

