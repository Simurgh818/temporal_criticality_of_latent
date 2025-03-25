function plot_cumulative_sum_vs_pcs(base_output_path)
    % Plot trial median cumulative sum vs. PCs for each subject across all five conditions.
    
    conditions = {'BLA', 'BLT', 'P1', 'P2', 'P3'}; % Define the five conditions
    condition_colors = lines(length(conditions)); % Generate distinct colors for each condition
    
    % Dictionary to store data for each subject
    subject_data = struct();
    
    % Loop through each condition
    for i = 1:length(conditions)
        condition = conditions{i};
        condition_path = fullfile(base_output_path, condition);
        
        % Get all cumulative sum .mat files
        mat_files = dir(fullfile(condition_path, '*pc_cumulative_explained.mat'));
        
        % Process each subject
        for j = 1:length(mat_files)
            file_path = fullfile(condition_path, mat_files(j).name);
            data = load(file_path);
            
            % Check if the variable exists
            if isfield(data, 'pc_cumulative_explained')
                pc_cumulative_explained = data.pc_cumulative_explained;
            else
                warning('Missing variable in %s', file_path);
                continue;
            end

            % Compute trial median across rows (trials)
            median_cumulative_explained = median(pc_cumulative_explained, 1); % Median along trials
            
            % Extract and sanitize subject name
            [~, subject_name, ~] = fileparts(mat_files(j).name);
            subject_name = erase(subject_name, '_pc_cumulative_explained'); % Remove suffix
            sanitized_subject_name = matlab.lang.makeValidName(subject_name);
            
            % Store data
            if ~isfield(subject_data, sanitized_subject_name)
                subject_data.(sanitized_subject_name) = struct();
            end
            subject_data.(sanitized_subject_name).(condition) = median_cumulative_explained;
        end
    end
    
    % Create PCA output directory
    pca_output_path = fullfile(base_output_path, 'PCA');
    if ~exist(pca_output_path, 'dir')
        mkdir(pca_output_path);
    end
    
    % Generate plots for each subject
    subject_names = fieldnames(subject_data);
    for s = 1:length(subject_names)
        subject_name = subject_names{s};
        figure;
        hold on;
        
        valid_conditions = {}; % Track conditions with valid data
        
        % Plot data for each condition
        for i = 1:length(conditions)
            condition = conditions{i};
            if isfield(subject_data.(subject_name), condition)
                plot(1:length(subject_data.(subject_name).(condition)), ...
                     subject_data.(subject_name).(condition), ...
                     'LineWidth', 2, 'Color', condition_colors(i, :), ...
                     'DisplayName', condition);
                valid_conditions{end+1} = condition; % Add to valid list
            end
        end
        
        % Check if there is any valid data before setting limits
        if ~isempty(valid_conditions)
            first_condition = valid_conditions{1}; % Use first valid condition for x-axis limits
            xlim([1, length(subject_data.(subject_name).(first_condition))]);
        end
        
        xlabel('Principal Component');
        ylabel('Median Cumulative Explained Variance (Post-Pre stimulus)');
        title(sprintf('Cumulative Sum vs. PCs: %s', strrep(subject_name, '_', ' '))); % Readable title
        grid on;
        legend('show', 'Location', 'best');
        
        % Save figure in PCA subfolder
        savefig(fullfile(pca_output_path, [subject_name '_cumulative_sum_vs_pcs.fig']));
        saveas(gcf, fullfile(pca_output_path, [subject_name '_cumulative_sum_vs_pcs.png']));
        close(gcf);
    end
end
