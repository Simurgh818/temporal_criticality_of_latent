clear; 
% Define conditions
conditions = {'BLA','BLT'}; % , 'P1', 'P2', 'P3'  

% Set input and output paths based on system
if exist('H:\', 'dir')
    base_input_path = 'H:\My Drive\Data\New Data\EEG epoched';
    base_output_path = 'C:\Users\sinad\OneDrive - Georgia Institute of Technology\Dr. Sederberg MaTRIX Lab\temporal_criticality_of_latent_results';
elseif exist('G:\', 'dir')
    base_input_path = 'G:\My Drive\Data\New Data\EEG epoched';
    base_output_path = 'C:\Users\sdabiri\OneDrive - Georgia Institute of Technology\Dr. Sederberg MaTRIX Lab\temporal_criticality_of_latent_results';
else
    error('Unknown system: Cannot determine input and output paths.');
end

% Loop over each condition
for i = 1:length(conditions)
    condition = conditions{i};
    input_path = fullfile(base_input_path, condition);
    output_path = fullfile(base_output_path, condition);
    
    if ~exist(output_path, 'dir')
        mkdir(output_path);
    end
    
    % Get all .set files in the directory
    set_files = dir(fullfile(input_path, '*.set'));
    
    % Loop over each subject's dataset
    for j = 1:length(set_files)
        file_path = fullfile(input_path, set_files(j).name);
        fprintf('Processing %s...\n', file_path);
        run_pca_across_space(file_path, output_path, condition);
    end
end
