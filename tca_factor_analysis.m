function tca_factor_analysis(base_output_path)
    conditions = {'BLA', 'BLT', 'P1', 'P2', 'P3'}; % Define the five conditions
    condition_colors = lines(length(conditions)); % Generate distinct colors for each condition
    
    % Dictionary to store data for each subject
    subject_data = struct();
    
    % Define sub-conditions for P2 and P3
    sub_conditions = {'pre', 'post', '500ms', '2000ms', 'missing'};
    
    % Loop through each condition
    for i = 1:length(conditions)
        condition = conditions{i};
        condition_path = fullfile(base_output_path, condition);
        
        % Get all explained variance .mat files
        if strcmp(condition, 'BLA') || strcmp(condition, 'BLT') || strcmp(condition, 'P1')
            % Standard conditions with pre/post
            pre_files = dir(fullfile(condition_path, '*_explained_variance_pre.mat'));
            post_files = dir(fullfile(condition_path, '*_explained_variance_post.mat'));
            
            % Process pre-stimulus files
            for j = 1:length(pre_files)
                file_path = fullfile(condition_path, pre_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(pre_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_pre', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_pre']) = data.explained_variance_pre;
            end
            
            % Process post-stimulus files
            for j = 1:length(post_files)
                file_path = fullfile(condition_path, post_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(post_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_post', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_post']) = data.explained_variance_post;
            end
            
        elseif strcmp(condition, 'P2')
            % P2 condition with 500ms and 2000ms subconditions
            pre_files = dir(fullfile(condition_path, '*_explained_variance_pre_p2.mat'));
            p2_500ms_files = dir(fullfile(condition_path, '*_explained_variance_post_p2_500ms.mat'));
            p2_2000ms_files = dir(fullfile(condition_path, '*_explained_variance_post_p2_2000ms.mat'));
            
            % Process pre-stimulus files
            for j = 1:length(pre_files)
                file_path = fullfile(condition_path, pre_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(pre_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_pre_p2', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_pre']) = data.explained_variance_pre;
            end
            
            % Process 500ms files
            for j = 1:length(p2_500ms_files)
                file_path = fullfile(condition_path, p2_500ms_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(p2_500ms_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_post_p2_500ms', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_500ms']) = data.explained_variance_post_p2_500ms;
            end
            
            % Process 2000ms files
            for j = 1:length(p2_2000ms_files)
                file_path = fullfile(condition_path, p2_2000ms_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(p2_2000ms_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_post_p2_2000ms', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_2000ms']) = data.explained_variance_post_p2_2000ms;
            end
            
        elseif strcmp(condition, 'P3')
            % P3 condition with 500ms and missing subconditions
            pre_files = dir(fullfile(condition_path, '*_explained_variance_pre_p3.mat'));
            p3_500ms_files = dir(fullfile(condition_path, '*_explained_variance_post_p3_500ms.mat'));
            p3_missing_files = dir(fullfile(condition_path, '*_explained_variance_post_p3_missing.mat'));
            
            % Process pre-stimulus files
            for j = 1:length(pre_files)
                file_path = fullfile(condition_path, pre_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(pre_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_pre_p3', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_pre']) = data.explained_variance_pre;
            end
            
            % Process 500ms files
            for j = 1:length(p3_500ms_files)
                file_path = fullfile(condition_path, p3_500ms_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(p3_500ms_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_post_p3_500ms', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_500ms']) = data.explained_variance_post_p3_500ms;
            end
            
            % Process missing files
            for j = 1:length(p3_missing_files)
                file_path = fullfile(condition_path, p3_missing_files(j).name);
                data = load(file_path);
                
                % Extract subject name
                [~, file_name, ~] = fileparts(p3_missing_files(j).name);
                subject_name = strrep(file_name, '_explained_variance_post_p3_missing', '');
                sanitized_subject_name = matlab.lang.makeValidName(subject_name);
                
                % Store data
                if ~isfield(subject_data, sanitized_subject_name)
                    subject_data.(sanitized_subject_name) = struct();
                end
                subject_data.(sanitized_subject_name).([condition '_missing']) = data.explained_variance_post_p3_missing;
            end
        end
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
            condition_field = [condition '_pre']; % Default field to check
            if isfield(subject_data.(subject_name), condition_field)
                plot(1:length(subject_data.(subject_name).(condition_field)), ...
                    subject_data.(subject_name).(condition_field), ...
                    'LineWidth', 2, 'Color', condition_colors(i, :), ...
                    'DisplayName', condition);
                valid_conditions{end+1} = condition_field; % Add to valid list
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
        
        % Save figure in each condition subfolder where this subject has data
        for i = 1:length(conditions)
            condition = conditions{i};
            condition_path = fullfile(base_output_path, condition);
                
            % Check if subject has data for this condition
            has_condition_data = false;
            condition_fields = fieldnames(subject_data.(subject_name));
            for f = 1:length(condition_fields)
                if startsWith(condition_fields{f}, condition)
                    has_condition_data = true;
                    break;
                end
            end
            
            if has_condition_data
                % Save in this condition's folder
                savefig(fullfile(condition_path, [subject_name '_cumulative_sum_vs_pcs.fig']));
                saveas(gcf, fullfile(condition_path, [subject_name '_cumulative_sum_vs_pcs.png']));
            end
        end
        close(gcf);
    end
    
    %% Create table for 85% variance threshold
    threshold = 0.85; % 85% variance threshold
    
    % Define all possible condition combinations
    all_conditions = {'BLA-pre', 'BLA-post', 'BLT-pre', 'BLT-post', 'P1-pre', 'P1-post', ...
                     'P2-pre', 'P2-500ms', 'P2-2000ms', 'P3-pre', 'P3-500ms', 'P3-missing'};
    
    % Initialize table data
    table_data = zeros(length(subject_names), length(all_conditions));
    
    % Fill in the table with the number of factors needed for 85% variance
    for s = 1:length(subject_names)
        subject_name = subject_names{s};
        for c = 1:length(all_conditions)
            condition = all_conditions{c};
            % Convert hyphen to underscore for field access since MATLAB struct fields use underscores
            condition_field = strrep(condition, '-', '_');
            if isfield(subject_data.(subject_name), condition_field)
                variance_data = subject_data.(subject_name).(condition_field);

                % Compute cumulative explained variance and find when it first reaches 85%
                cum_variance = cumsum(variance_data);              % cumulative sum across PCs
                factor_count = find(cum_variance >= threshold, 1); % first k such that cum_variance(k) >= 0.85
                if isempty(factor_count)
                    % if even all PCs don't reach 85%, use the maximum
                    factor_count = numel(variance_data);
                end

                table_data(s, c) = factor_count;
            end
        end
    end
    
    % Create table
    results_table = array2table(table_data, 'VariableNames', all_conditions, 'RowNames', subject_names);
    
    % Create a new summary table that shows stats for each condition type (BLA, BLT, etc.)
    % by filtering subjects that contain those condition prefixes
    
    % First, let's create data structures to store condition-specific summary stats
    condition_subjects = struct();
    condition_means = zeros(1, length(all_conditions));
    condition_stds = zeros(1, length(all_conditions));
    
    % For each condition, find subjects that contain that condition name
    for c = 1:length(all_conditions)
        condition = all_conditions{c};
        % Get the main condition name before the hyphen (e.g., BLA from BLA-pre)
        parts = strsplit(condition, '-');
        main_condition = parts{1};
        
        % Convert back to underscore for internal field naming
        condition_underscore = strrep(condition, '-', '_');
        
        % Find subjects with this condition in their name
        matching_subjects = false(length(subject_names), 1);
        for s = 1:length(subject_names)
            subject_name = subject_names{s};
            if contains(subject_name, main_condition)
                matching_subjects(s) = true;
            end
        end
        
        % Calculate mean and std only for matching subjects
        if any(matching_subjects)
            condition_data = table_data(matching_subjects, c);
            condition_data = condition_data(~isnan(condition_data)); % Remove NaNs
            if ~isempty(condition_data)
                condition_means(c) = mean(condition_data, 'omitnan');
                condition_stds(c) = std(condition_data, 0, 'omitnan');
            end
        end
        
        % Store which subjects are related to this condition for reference
        condition_subjects.(main_condition) = subject_names(matching_subjects);
    end
    
    % Create summary table with condition-specific stats only
    summary_table = array2table([condition_means; condition_stds], 'VariableNames', all_conditions, ...
                             'RowNames', {'Condition_Specific_Mean', 'Condition_Specific_StdDev'});
              
    % Save the main results table 
    writetable(results_table, fullfile(base_output_path, 'factors_at_85_percent.csv'), 'WriteRowNames', true);
    
    % Save the summary table 
    writetable(summary_table, fullfile(base_output_path, 'factors_at_85_percent_summary.csv'), 'WriteRowNames', true);
    
    % Create a text file that shows which subjects were used for each condition's stats
    fid = fopen(fullfile(base_output_path, 'condition_specific_subjects.txt'), 'w');
    if fid ~= -1
        main_conditions = {'BLA', 'BLT', 'P1', 'P2', 'P3'};
        for i = 1:length(main_conditions)
            cond = main_conditions{i};
            if isfield(condition_subjects, cond)
                fprintf(fid, '%s subjects: %s\n', cond, strjoin(condition_subjects.(cond), ', '));
            end
        end
        fclose(fid);
    end
    
    %  Create a single heatmap (subjects × all_conditions)
    figure('Position',[100,100,1200,800]);
    h = heatmap(all_conditions, subject_names, table_data);
    h.Title  = 'Number of Factors Required to Explain 85% of Variance';
    h.XLabel = 'Condition';
    h.YLabel = 'Subject';
    h.Colormap = parula;
    % Save to parent folder
    saveas(gcf, fullfile(base_output_path, 'factors_at_85_percent_heatmap.fig'));
    saveas(gcf, fullfile(base_output_path, 'factors_at_85_percent_heatmap.png'));
    close(gcf);

    % Removed overall bar chart as requested
    
    % Create a bar chart for condition-specific means
    figure('Position',[100,100,1200,600]);
    bar(condition_means);
    hold on;
    errorbar(1:length(condition_means), condition_means, condition_stds, 'k.', 'LineWidth', 1.5);
    xlabel('Condition');
    ylabel('Mean Number of Factors for 85% Explained Variance');
    title('Mean Number of Factors Required to Explain 85% of Variance');
    xticks(1:length(all_conditions));
    xticklabels(all_conditions);
    xtickangle(45);
    grid on;
    % Save to parent folder
    saveas(gcf, fullfile(base_output_path, 'factors_at_85_percent_barchart.fig'));
    saveas(gcf, fullfile(base_output_path, 'factors_at_85_percent_barchart.png'));
    close(gcf);

    % Final completion message
    fprintf('Analysis complete. Results saved to %s\n', base_output_path);
end