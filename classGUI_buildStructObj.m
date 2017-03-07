

%% Build Class Struct Objects
function sessionObjects = classGUI_buildStructObj(data_path, subject_number, session_number, updateMetaData)


    %% Find all raw data text files
    data_file_path     = [data_path '/SUBJECT_' num2str(subject_number)];
    
    data_files       = dir(data_file_path);   
    valid_data_files = strfind({data_files.name}, 'MLRT_DATA');
    valid_ind        = ~cellfun(@isempty, valid_data_files);
    data_files       = data_files(valid_ind);
    num_data_files   = length(data_files);
    
    
    %% Find all metadata mat files  
    metadata_file_path = [data_file_path '/METADATA'];

    metadata_files       = dir(metadata_file_path);
    valid_metadata_files = strfind({metadata_files.name}, 'META_DATA');
    valid_ind            = ~cellfun(@isempty, valid_metadata_files);
    metadata_files       = metadata_files(valid_ind);
    num_metadata_files   = length(metadata_files);
    
        
    %% Identity Files to Update/Load/Save
    data_filenames     = cellfun(@(x) x(11:end-3), {data_files.name}, 'un', 0);
    metadata_filenames = cellfun(@(x) x(11:end-3), {metadata_files.name}, 'un', 0);
    
    update_indices = ~ismember(data_filenames, metadata_filenames);
    file_indices   = find(update_indices);
    
    if (updateMetaData == 1)
        file_indices = 1:length(update_indices);
    end
    
    
    %% Load Single Session Override
    if (session_number ~= -1)
        file_indices = session_number;
    end
        
    
    %% Load Data Files
    sessionObjects = Session.empty();

    if ~isempty(file_indices),
        
        textprogressbar('Loading Sessions into Objects:  ')
        for index = file_indices,

            % File Name Path
            file_name = data_files(index).name;
            full_data_path = [data_file_path '/' file_name];

            % Import Data
            delimiterIn = ',';
            headerlinesIn = 2;
            importedDataStruct = importdata(full_data_path, delimiterIn, headerlinesIn);

            % Session Obj
            raw_data  = importedDataStruct.data;
            text_data = importedDataStruct.textdata;

            session_index = length(sessionObjects) + 1;
            sessionObjects(session_index) = Session(index, raw_data, text_data, file_name);

            % Update Progress Bar
            textprogressbar(find(index == file_indices)/length(file_indices)*100);

        end
        textprogressbar('  Finished.')   
    
        
        %% Save Meta Data Objects
        for i = 1:length(sessionObjects)

            % Generate Filename/path
            fileIdx = sessionObjects(i).NUMBER;
            [~, name, ~] = fileparts(data_files(fileIdx).name);
            metadata_filename = ['META_DATA' name(10:end)];
            metadata_filenamepath = [metadata_file_path '\' metadata_filename '.mat'];

            sessionObject = sessionObjects(i);
            sessionObject = sessionObject.removeTrialData();

            if ~exist(metadata_file_path, 'dir')
                mkdir(data_file_path, 'METADATA'); 
            end

            if ~exist(metadata_filenamepath) | updateMetaData == 1
                save(metadata_filenamepath, 'sessionObject');
            end
        end


        %% Print to CMD Line
        fprintf('\n')
        fprintf('------------------------------------------------------------------------\n');

        for i = 1:length(sessionObjects)
            sessionObjects(i).printOutput();
        end

        fprintf('------------------------------------------------------------------------\n');
    
    end
    
    return;
end