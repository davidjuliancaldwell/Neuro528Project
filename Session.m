classdef Session
    % Each Training Session
    % 
    % Class Object
    %
    
    
    %% Public Get, Private Set Properties
    properties (GetAccess = public, SetAccess = private)
        NUMBER      = 1;
        
        VERSION     = 'V0.0.0';
        VERSION_INT = 0;
        DATE_STR    = '';
        FIELDS      = {};
        TRIAL_TYPE  = '';
        NUM_TARGETS = -1;
        
        DATA_RAW    = [];
        DATA_TEXT   = '';
        FILE_NAME   = '';
        
        DATA        = struct;
        
        TRIAL_OBJ   = Trial.empty();
        
        METADATA    = struct;
    end
    
    %% Public Functions
    methods
        
        % Constructor
        function obj = Session(num, raw_data, text_data, file_name)
            obj.NUMBER = num; 
            
            if nargin > 3
                obj.FILE_NAME  = file_name;
            end
            
            if nargin > 2
                obj.DATA_RAW   = raw_data;
            end

            if nargin > 1
                obj.DATA_TEXT  = text_data;
            end
            
            % Populate Class Object Fields
            obj = obj.processImportedData();
            obj = obj.processRawData();
            obj = obj.processTrialObjects();
            obj = obj.processMetaData();
            
            obj.DATA_RAW = [];
        end
        
        % Update All
        function obj = updateAll(obj, file_name)
            obj = updateNumTargets(obj);
            obj = updateSessionLength(obj);
            obj = updateTrialType(obj);
            obj = updateDataPath(obj, file_name);
        end
        
        % Update MetaData
        function obj = updateMetaData(obj)
            obj = obj.processMetaData();
        end
        
        % Update MetaData
        function obj = removeTrialData(obj)
            obj.TRIAL_OBJ = Trial.empty();
        end
        
        % Update Property
        function obj = updateNumTargets(obj)
            if ischar(obj.NUM_TARGETS)
                obj.NUM_TARGETS = str2double(obj.NUM_TARGETS);
            end
            
            ver = str2num(obj.VERSION_INT);
            if ver < 700,
                obj.NUM_TARGETS = 2;
            end
        end
        
        % Update Session Length
        function obj = updateSessionLength(obj)
            if (obj.METADATA.num_trials > 2)
                first_trial_idx = find(obj.DATA.GBL_STATE_MACHINE ~= 1, 1, 'first'); 
            else
                first_trial_idx = 1;
            end
            session_startTime = obj.DATA.time_tstamp_msec(first_trial_idx);
            session_endTime   = obj.DATA.time_tstamp_msec(end);
            session_trainTime = (session_endTime - session_startTime)/1000;
            
            obj.METADATA.session_train_time = session_trainTime;
        end
        
        % Update Property
        function obj = updateTrialType(obj)
            ver = str2num(obj.VERSION_INT);
            
            if ~strcmp(obj.TRIAL_TYPE, ''), 
            elseif ver == 364,               obj.TRIAL_TYPE = 'TRIAL_SIPPER_10'; 
            elseif ver == 365,               obj.TRIAL_TYPE = 'TRIAL_SIPPER_100';    
            elseif ver == 365,               obj.TRIAL_TYPE = 'TRIAL_SIPPER_100'; 
            
            elseif ver >= 400 && ver <= 420, obj.TRIAL_TYPE = 'TRIAL_HANDLE_20';
            elseif ver >= 421 && ver <= 424, obj.TRIAL_TYPE = 'TRIAL_MOVE_JYSTK';
            elseif ver >= 425 && ver <= 436, obj.TRIAL_TYPE = 'TRIAL_MOVE_JYSTK_LEFT_Timeout';
            elseif ver >= 437 && ver <= 451, obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_OVERT_NoTimeout';
            elseif ver == 452,               obj.TRIAL_TYPE = 'TRIAL_MOVE_JYSTK_LEFT_Timeout';
            
            elseif ver >= 500,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_NoTimeout';
            elseif ver >= 501,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_OVERT_Timeout';
            elseif ver >= 502,               obj.TRIAL_TYPE = 'TRIAL_MOVE_JYSTK_LEFT_Timeout';
            elseif ver >= 503,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step1';
            elseif ver >= 504,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_OVERT_Timeout';
            elseif ver >= 505,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step5';
            elseif ver >= 506,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_NoTimeout';
            elseif ver >= 507,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step1';
            elseif ver >= 508,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step5';
            elseif ver >= 510,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_EqualTimeout';
            elseif ver >= 511,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step6';     
            
            elseif ver >= 520,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step4';
            elseif ver >= 521,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step5';
            elseif ver >= 522,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_Timeout_Step6';
            elseif ver >= 523,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_EqualTimeout';
            
            elseif ver >= 530,               obj.TRIAL_TYPE = 'TRIAL_FIND_TARGET_HIDDEN_EqualTimeout';
            elseif ver >= 531,               obj.TRIAL_TYPE = 'TRIAL_SIPPER_10';
            elseif ver >= 532,               obj.TRIAL_TYPE = 'TRIAL_HANDLE_20';                                    
            else                             obj.TRIAL_TYPE = '';                
            end
            
            obj.METADATA.session_trial_types = obj.TRIAL_TYPE;
            
        end
                
        % Update Data Path
        function obj = updateDataPath(obj, file_name)
            file_name(1:4) = 'MLRT';                        
            obj.FILE_NAME = file_name;
        end
            
        % Print Function
        function printOutput(obj)

            % vars
            prcnt_all_tr = obj.METADATA.alltrials_prcnt*100;
            prcnt_valid_tr = obj.METADATA.rm_shortTrials*100;
            num_all_tr = obj.METADATA.num_trials;
            num_valid_tr = round(obj.METADATA.num_trials * mean(~obj.METADATA.short_rwd));
            
            com_str = strsplit(obj.FILE_NAME, {'_','.'});
            com_str = com_str{5};
            com_str = com_str(4:end);
            
            type_str = strsplit(obj.TRIAL_TYPE, '_');
            if any(cellfun(@(s) ~isempty(strfind('HIDDEN', s)), type_str))
                type_str = type_str{end};
            elseif any(cellfun(@(s) ~isempty(strfind('OVERT', s)), type_str))
                type_str = 'OVERT';
            elseif any(cellfun(@(s) ~isempty(strfind('MOVE', s)), type_str)) & ...
                (length(type_str) > 3)
                type_str = type_str{end-1};
            elseif any(cellfun(@(s) ~isempty(strfind('MOVE', s)), type_str))
                type_str = type_str{end};
            else
                type_str = 'SIP';
            end
            type_str = regexprep(type_str,'[aeio]','');
            
            % Print to cmdline
            fprintf(['Tr#:',               num2str(obj.NUMBER,'%2d') ]);
            fprintf([', COM:',             num2str(com_str,'%s') ]);
            fprintf([', ',                 sprintf('%10s', type_str) ]);
%             fprintf([' [%%Cr/NumTr]']);
            fprintf([' | Valid: [',        num2str(prcnt_valid_tr,'%2.2f'), '%%' ]);
            fprintf([', '                  sprintf('%3s', num2str(num_valid_tr, '%3d')) ]);
            
            fprintf(['] | All: [',          num2str(prcnt_all_tr, '%2.2f'), '%%' ]);
            fprintf([', '                  sprintf('%3s', num2str(num_all_tr, '%3d')) ]);
            fprintf('] \n');
            
%             fprintf(['Tr#:',               num2str(obj.NUMBER,'%2d')]);
%             fprintf([' -> Correct: ',      num2str(obj.METADATA.alltrials_prcnt*100,'%2.2f'), '%%']); 
%             fprintf([' | w/o EasyDwTr: ',  num2str(obj.METADATA.rm_shortTrials*100,'%2.2f'), '%%']);
%             fprintf([' | Discrd: ',        num2str((mean(obj.METADATA.short_rwd))*100,'%2.0f'), '%%']); 
%             fprintf([' | #(Tr): ',         num2str(obj.METADATA.num_trials,'%2d')]); 
%             fprintf('\n');

            % fprintf([' | Catch: ',     num2str(plot_data(i).catch_trial_prcnt*100,'%2.2f'), '%']);
            % fprintf([' | Stim-Only: ', num2str(plot_data(i).stimonly_prcnt*100,'%2.2f'), '%']);
            % fprintf([' | All: ',       num2str(plot_data(i).alltrials_prcnt*100,'%2.2f'), '%']);
            % fprintf([' | No/Sniff: ',  num2str(plot_data(i).no_sniff*100,'%2.2f'), '%%']);
            % fprintf([' | Discarded: ',  num2str((1-mean(temp_logic_idx))*100,'%2.0f'), '%%']);
        end
        
    end

    %% Private Helper Functions
    methods (Access = private)
        
        % Set Global Variables of Session
        function obj = processImportedData(obj)
            
            header_line1 = obj.DATA_TEXT(1,:);
            header_line2 = obj.DATA_TEXT(2,:);
            
            % Process Fields
            field_names         = header_line2;
            field_header_strip  = regexp ( header_line2{1}, ':', 'split' );
            field_names{1}      = field_header_strip{2};
            field_names         = strtrim(field_names);
            field_names         = strrep(field_names, '[', '_');
            field_names         = strrep(field_names, ']', '_');
            obj.FIELDS          = field_names;
            
            % Date String and Version
            header_line1_strip  = regexp ( header_line1{1}, ':', 'split' );
            header_line1_split  = regexp ( header_line1_strip{2}, ',', 'split' );
            header_line1_split  = strtrim(header_line1_split);
            
            if (length(header_line1_split) == 5)
                obj.VERSION     = header_line1_split{2};
                obj.VERSION_INT = regexprep(obj.VERSION, '[V.]', '');
                obj.TRIAL_TYPE  = header_line1_split{3};
                obj.NUM_TARGETS = str2double(header_line1_split{4});
                obj.DATE_STR    = header_line1_split{5};
            
            elseif (length(header_line1_split) == 4)
                obj.VERSION     = header_line1_split{2};
                obj.VERSION_INT = regexprep(obj.VERSION, '[V.]', '');
                obj.TRIAL_TYPE  = header_line1_split{3};
                obj.DATE_STR    = header_line1_split{4};
                obj = obj.updateNumTargets();
                
            else %if (length(header_line1_split) == 3)
                obj.VERSION     = header_line1_split{2};
                obj.VERSION_INT = regexprep(obj.VERSION, '[V.]', '');
                obj.DATE_STR    = header_line1_split{3};
                obj = obj.updateTrialType();
                obj = obj.updateNumTargets();
            end
        end
        
        % Create Vectors with Field Names 
        function obj = processRawData(obj)
            
            % If Any Data Fields are Invalid, Remove them
            invalid_datapnts = isnan(obj.DATA_RAW);
            invalid_packets = any(invalid_datapnts,2);
            if any(invalid_packets)
                obj.DATA_RAW(invalid_packets,:) = [];
                for invalid_packet = find(invalid_packets)'
                    warning(['Removing Invalid Data Packets, Index: ' int2str(invalid_packet)])
                end
            end
            
            data = struct();
            for k = 1:length(obj.FIELDS),          % for each unique variable
                fld        = obj.FIELDS{k};        % field name
                data.(fld) = obj.DATA_RAW(:,k);    % assign to field
            end
    
            obj.DATA = data;
        end
        
        % Create Trial Objects
        function obj = processTrialObjects(obj)
            
            % Get Trial ID vector
            if isfield(obj.DATA, 'GBL_trial_number')
                trial_ID = obj.DATA.GBL_trial_number;
            elseif isfield(obj.DATA, 'GBL_counter_reward')
                trial_ID = obj.DATA.GBL_counter_reward;
            end

            [~, trial_indices_start] = unique(trial_ID, 'first');
            [~, trial_indices_end]   = unique(trial_ID, 'last');

            num_trials = length(trial_indices_end);
            
            % If many trials are present, discard trailing and leading
            % trials, otherwise, keep all
            if num_trials < 5,
                trial_indices = 1:num_trials;
            else
                trial_indices = 2:num_trials-2;
            end
            
            % For Each Trial
            for trial_index = trial_indices,
                ind_start = trial_indices_start(trial_index);
                ind_end   = trial_indices_end(trial_index);
                trial_data = obj.DATA_RAW(ind_start:ind_end,:);
                
                % Check if Trial Data is Valid
                valid_trial = true;
                if isfield(obj.DATA, 'GBL_TARGET')
                    if obj.DATA.GBL_TARGET(ind_start) < 0
                        valid_trial = false;
                    end
                end
                
                if isfield(obj.DATA, 'GBL_STATE_MACHINE')
                    if all(obj.DATA.GBL_STATE_MACHINE(ind_start:ind_end) ~= 1)
                        valid_trial = false;
                    end
                end
                                
                % If Trial Data is Valid, Create Obj
                if valid_trial
                    next_index = length(obj.TRIAL_OBJ) + 1;
                    obj.TRIAL_OBJ(next_index) = Trial(trial_ID(ind_start), trial_data, obj.FIELDS);
                end
            end           
        end
        
        % Process MetaData
        function obj = processMetaData(obj)
            
            metadata = struct();
            
            metadata.num_trials    = [length([obj.TRIAL_OBJ])];
            metadata.trial_ID      = [obj.TRIAL_OBJ.ID_NUMBER];
            metadata.session_trial_types = obj.TRIAL_TYPE;

            % Correct
            metadata.correct       = [obj.TRIAL_OBJ.CORRECT];
            metadata.catch_trials  = [obj.TRIAL_OBJ.CATCH_TRIAL] > 0;
            metadata.stim_only     = [obj.TRIAL_OBJ.STIM_ONLY] > 0;
            metadata.target        = [obj.TRIAL_OBJ.TARGET];
            metadata.short_rwd     = [obj.TRIAL_OBJ.SHORT_RWD]==1;
            metadata.first_20      = [1:metadata.num_trials] <= 20;

            metadata.catch_trial_prcnt = mean(metadata.catch_trials);
            metadata.alltrials_prcnt   = mean(metadata.correct);
            metadata.correct_prcnt     = mean(metadata.correct(~metadata.catch_trials));
            metadata.chance_prcnt      = mean(metadata.correct( metadata.catch_trials));
            metadata.stimonly_prcnt    = mean(metadata.correct( metadata.stim_only));

            metadata.rm_shortTrials    = mean(metadata.correct( ~metadata.short_rwd & ...
                                                                ~metadata.first_20 ) );

            metadata.chance_level      = mean(metadata.target(metadata.catch_trials));

            metadata.trgt_dwell_ind   = {obj.TRIAL_OBJ.DWELL_IND};
            metadata.trgt_dwell_times = {obj.TRIAL_OBJ.DWELL_TIMES};
            metadata.trgt_dwell_ids   = {obj.TRIAL_OBJ.DWELL_TARGETS};

            % Number of Pulls
            dwell_times = {obj.TRIAL_OBJ.DWELL_TIMES};
            metadata.num_pulls = cellfun(@(i) length(i), dwell_times);
            metadata.dwell_time_total = cellfun(@(i) sum(i), dwell_times);

            % Number of Pulls to Correct Target
            dwell_targets = {obj.TRIAL_OBJ.DWELL_TARGETS};
            temp = [obj.TRIAL_OBJ.TARGET];
            correct_target = mat2cell(temp,1,ones(1,size(temp,2)));
            correct_pulls = cellfun(@(i,j) sum(i == j), dwell_targets, correct_target);
            metadata.num_correct_pulls = correct_pulls;

            % Session Length
            if (metadata.num_trials > 2)
                first_trial_idx = find(obj.DATA.GBL_STATE_MACHINE ~= 1, 1, 'first'); 
            else
                first_trial_idx = 1;
            end
            session_startTime = obj.DATA.time_tstamp_msec(end);
            session_endTime   = obj.DATA.time_tstamp_msec(first_trial_idx);
            session_trainTime = (session_endTime - session_startTime)/1000;
            metadata.session_train_time = session_trainTime;
            
            % Training Length
            metadata.total_train_time = [obj.TRIAL_OBJ.TOTAL_TRAINING_TIME];
            metadata.length_total     = [obj.TRIAL_OBJ.LENGTH_TOTAL_SEC];
            metadata.length_active    = [obj.TRIAL_OBJ.LENGTH_ACTIVE_SEC];

            metadata.mean_trial_length = mean(metadata.length_total);
            metadata.std_trial_length  =  std(metadata.length_total);

            metadata.mean_trial_active_length = mean(metadata.length_active);
            metadata.std_trial_active_length  =  std(metadata.length_active);

            % Dwell Times
            metadata.dwell_time = [obj.TRIAL_OBJ.DWELL_MS];
            metadata.timeout_time = [obj.TRIAL_OBJ.TIMEOUT_MS];    
            
            
            obj.METADATA = metadata;
        end
        
    end
    
    
end

