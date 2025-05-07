clear;
% Define conditions
conditions = {'BLA', 'BLT', 'P1', 'P2', 'P3'}; %
subjects ={'BOS2','BOS3','BOS5','BOS6','BOS7','BOS8','BOS9','BOS10',...
'BOS11','BOS12','BOS13','BOS15','BOS16','BOS17'};

% Set input and output paths based on system
if exist('H:\', 'dir')
    base_input_path = 'H:\My Drive\Data\New Data\EEG epoched';
    base_output_path = 'C:\Users\sinad\OneDrive - Georgia Institute of Technology\Dr. Sederberg MaTRIX Lab\temporal_criticality_of_latent_results\TCA';
elseif exist('G:\', 'dir')
    base_input_path = 'G:\My Drive\Data\New Data\EEG epoched';
    base_output_path = 'C:\Users\sdabiri\OneDrive - Georgia Institute of Technology\Dr. Sederberg MaTRIX Lab\temporal_criticality_of_latent_results\TCA';
else
    error('Unknown system: Cannot determine input and output paths.');
end

% Start the parallel pool once at the beginning
try
    poolobj = gcp('nocreate'); % Get current parallel pool without creating one
    if isempty(poolobj)
        poolobj = parpool(); % Create a parallel pool with default settings
    end
catch err
    warning('Could not create parallel pool');
    warning('Running in serial mode instead');
end

% Loop over each condition
for i = 1:length(conditions)
    condition = conditions{i};
    input_path = fullfile(base_input_path, condition);
    output_path = fullfile(base_output_path, condition);
    
    if strcmp(condition, 'P2')
        excel_file_path = fullfile(base_input_path,'Indexes for P2.xlsx');
    elseif strcmp(condition, 'P3')
        excel_file_path = fullfile(base_input_path,'Indexes for P3.xlsx');
    else
        excel_file_path = '';
    end
    
    if ~exist(output_path, 'dir')
        mkdir(output_path);
    end
    
    % Get all .set files in the directory
    set_files = dir(fullfile(input_path, '*.set'));
    
    % Loop over each subject's dataset
    parfor j = 1:length(set_files)
        file_path = fullfile(input_path, set_files(j).name);
        fprintf('Processing %s...\n', file_path);
        run_tca(file_path, output_path, condition, excel_file_path);
        % clear EEG beta_signal;
    end
end

tca_factor_analysis(base_output_path);