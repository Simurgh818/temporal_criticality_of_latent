function run_pca_across_space(file_path, output_path, condition, excel_file_path)
    % Load EEG dataset
    EEG = pop_loadset(file_path);

    % Extract relevant parameters
    fs = EEG.srate; % Sampling rate
    time_vector = linspace(-0.5, 3, size(EEG.data, 2)); % Time axis (-500ms to 3000ms)

    % Select odd or even epochs based on condition
    if strcmp(condition, 'BLA') || strcmp(condition, 'P1') || strcmp(condition, 'P2') || strcmp(condition, 'P3')
        epoch_trials = 1:2:EEG.trials; % Odd epochs
    elseif strcmp(condition, 'BLT')
        epoch_trials = 2:2:EEG.trials; % Even epochs
    else
        error('Condition not recognized. Please specify "BLA" or "BLT".');
    end

    num_trials = length(epoch_trials);
    data = EEG.data(:, :, epoch_trials);

    % Bandpass filter beta band (13-30 Hz)
    beta_band = [13 30];
    beta_signal = zeros(size(data)); % Preallocate
    for epoch = 1:size(data, 3)
        beta_signal(:,:,epoch) = bandpass(data(:,:,epoch)', beta_band, fs)';
    end

    % Define pre- and post-stimulus time windows (400ms before and after stimulus onset at 500ms)
    pre_window = [-0.4, 0];  % Pre-stimulus window (-400ms to 0ms)
    % Initialize post-stimulus window variable
    post_window = [];

    % Convert time to indices
    pre_idx = find(time_vector >= pre_window(1) & time_vector <= pre_window(2));

    % Initialize results matrix (Trials x PCs)
    num_pcs = 32; % Number of Principal Components to extract
    pc_explained_variance = zeros(num_trials, num_pcs);
    pc_cumulative_variance = zeros(num_trials, num_pcs);

    % Initialize matrix for normalized values
    coeff_z = zeros(num_pcs,num_pcs, num_trials);  % Preallocate numeric matrix


    % Loop through each selected trial
    for i = 1:num_trials
        if strcmp(condition, 'BLA') || strcmp(condition, 'BLT')
            post_window = [0, 0.4];  % Post-stimulus window (0ms to +400ms)
        elseif strcmp(condition, 'P1')
            post_window = [0, 1.020];  % Post-stimulus window (0ms to +1020ms)
        elseif strcmp(condition, 'P2')
            % Read data for both conditions
            trials_500ms = readmatrix(excel_file_path, 'Sheet', 'Audio onset with 500 ms tactile');
            trials_2000ms = readmatrix(excel_file_path, 'Sheet', 'Audio onset with 2000 ms tactil');
            
            if ismember(epoch_trials(i), trials_500ms)
                post_window = [0, 1.020];  % 500ms condition
            elseif ismember(epoch_trials(i), trials_2000ms)
                post_window = [0, 2.400];  % 2000ms condition
            else
                continue; % Skip trials not in either list
            end        
            
        elseif strcmp(condition, 'P3')
            trials_500ms = readmatrix(excel_file_path, 'Sheet', 'Audio onset with 500 ms tactile');
            trials_missing = readmatrix(excel_file_path, 'Sheet', 'Audio onset with missing tactil');

            if ismember(epoch_trials(i), trials_500ms)
                post_window = [0, 1.020];  % 500ms condition
            elseif ismember(epoch_trials(i), trials_missing)
                post_window = [0, 1.020];  % missing condition
            else
                continue; % Skip trials not in either list
            end        
            
        end

        post_idx = find(time_vector >= post_window(1) & time_vector <= post_window(2));
        trial_data = squeeze(beta_signal(:, :, i)); % Channels x Time
        
        % PCA on the whole epoch
        [coeff, ~, ~, ~, explained ] = pca(trial_data(:, pre_idx:post_idx)');
        coeff_z(:,:,i) = zscore(coeff);
        pc_explained_variance(i,:) = explained;
        cumulative_variance = cumsum(explained,1);
        pc_cumulative_variance (i,:) = cumulative_variance; 
    end



    % Extract filename for saving
    [~, filename, ~] = fileparts(file_path);

    % Save squared differences matrix as .mat file
    save(fullfile(output_path, [filename 'coeff_z.mat']), 'coeff_z');
    save(fullfile(output_path, [filename 'pc_cumulative_variance.mat']), 'pc_cumulative_variance');
    
    threshold = 85;  % Target explained variance threshold

    % Preallocate result
    pc_at_85 = zeros(size(pc_explained_variance, 1), 1);
    
    for i = 1:size(pc_explained_variance, 1)
        cum_sum = cumsum(pc_explained_variance(i, :));  % Compute cumulative sum for this trial
        idx = find(cum_sum >= threshold, 1, 'first');     % Find first PC where cumulative sum ≥ 85
        if ~isempty(idx)
            pc_at_85(i) = idx;
        else
            pc_at_85(i) = NaN;  % If 85% is never reached
        end
    end

    if strcmp(condition, 'BLA') || strcmp(condition, 'BLT') || strcmp(condition, 'P1') 
        
        % Plot as heatmap
        figure('Position', [100, 100, 1200, 300]); % [x, y, width, height]
        t = tiledlayout(1, 4, 'TileSpacing', 'Compact', 'Padding', 'Compact');  % Use layout handle
        
        % Set overall title
        title(t, ['Normalized PCs that explain 85% of the variance ',filename], 'FontSize', 14, 'FontWeight', 'bold');
        
        for i = [1 4 8 25]
            nexttile;
            max_pc = pc_at_85(i);
            imagesc(coeff_z(:,1:max_pc,i));  % PCs on y-axis
            set(gca, 'YDir', 'normal');  % Ensure y-axis is oriented correctly
            colormap jet;
            colorbar;
            
            xlabel('PCs');
            ylabel('Channels');
            
            % Set individual subplot title
            title(['Trial# ', num2str(i)], 'FontSize', 12);
        end
    
        % Save figure
        savefig(fullfile(output_path, [filename '_pc_plot.fig'])); % Save as .fig
        saveas(gcf, fullfile(output_path, [filename '_pc_plot.png'])); % Save as .png
        close(gcf); % Close the figure to save memory
    elseif strcmp(condition, 'P2')
        % Plot heatmaps for 500ms and 2000ms trials separately

        % Identify indices of 500ms and 2000ms trials
        idx_500 = ismember(epoch_trials, trials_500ms);
        idx_2000 = ismember(epoch_trials, trials_2000ms);
        
        % Extract corresponding values
        coeff_z_500 = coeff_z(:, :, idx_500);
        coeff_z_2000 = coeff_z(:, :, idx_2000);
        
        % Plot in subplots
        figure('Position', [100, 100, 1200, 600]); % [x, y, width, height]
        t = tiledlayout(2, 4, 'TileSpacing', 'Compact', 'Padding', 'Compact');  % Use layout handle

        
        % Subplot for 500ms trials
        % Set overall title
        title(t, ['Normalized PCs that explain 85% of the variance ', filename], 'FontSize', 14, 'FontWeight', 'bold');
        
        for i = [1 4 8 25]
            nexttile;
            max_pc = pc_at_85(i);
            imagesc(coeff_z_500(:,1:max_pc,i));  % PCs on y-axis
            set(gca, 'YDir', 'normal');  % Ensure y-axis is oriented correctly
            colormap jet;
            colorbar;
            
            xlabel('PCs');
            ylabel('Channels');
            
            % Set individual subplot title
            title(['500ms Trial# ', num2str(i)], 'FontSize', 12);
        end

        % Subplot for 2000ms trials
         for i = [1 4 8 25]
            nexttile;
            max_pc = pc_at_85(i);
            imagesc(coeff_z_2000(:,1:max_pc,i));  % PCs on y-axis
            set(gca, 'YDir', 'normal');  % Ensure y-axis is oriented correctly
            colormap jet;
            colorbar;
            
            xlabel('PCs');
            ylabel('Channels');
            
            % Set individual subplot title
            title(['2000ms Trial# ', num2str(i)], 'FontSize', 12);
        end
                
        % Save figure
        savefig(fullfile(output_path, [filename '_pc_plot.fig'])); % Save as .fig
        saveas(gcf, fullfile(output_path, [filename '_pc_plot.png'])); % Save as .png
        close(gcf); % Close the figure to save memory

    elseif strcmp(condition, 'P3')
        % Plot heatmaps for 500ms and Missing trials separately

        % Identify indices of 500ms and 2000ms trials
        idx_500 = ismember(epoch_trials, trials_500ms);
        idx_missing = ismember(epoch_trials, trials_missing);
        
        % Extract corresponding values
        coeff_z_500 = coeff_z(:, :, idx_500);
        coeff_z_missing = coeff_z(:, :, idx_missing);
        
        % Plot in subplots
         % Plot in subplots
        figure('Position', [100, 100, 1200, 600]); % [x, y, width, height]
        t = tiledlayout(2, 4, 'TileSpacing', 'Compact', 'Padding', 'Compact');  % Use layout handle

        
        % Subplot for 500ms trials
        % Set overall title
        title(t, ['Normalized PCs that explain 85% of the variance ', filename], 'FontSize', 14, 'FontWeight', 'bold');
        
        for i = [1 4 8 25]
            nexttile;
            max_pc = pc_at_85(i);
            imagesc(coeff_z_500(:,1:max_pc,i));  % PCs on y-axis
            set(gca, 'YDir', 'normal');  % Ensure y-axis is oriented correctly
            colormap jet;
            colorbar;
            
            xlabel('PCs');
            ylabel('Channels');
            
            % Set individual subplot title
            title(['500ms Trial# ', num2str(i)], 'FontSize', 12);
        end
        
        % Subplot for Missing trials
         for i = [1 4 8 25]
            nexttile;
            max_pc = pc_at_85(i);
            imagesc(coeff_z_missing(:,1:max_pc,i));  % PCs on y-axis
            set(gca, 'YDir', 'normal');  % Ensure y-axis is oriented correctly
            colormap jet;
            colorbar;
            
            xlabel('PCs');
            ylabel('Channels');
            
            % Set individual subplot title
            title(['Missing tactile Trial# ', num2str(i)], 'FontSize', 12);
         end

        % Save figure
        savefig(fullfile(output_path, [filename '_pc_plot.fig'])); % Save as .fig
        saveas(gcf, fullfile(output_path, [filename '_pc_plot.png'])); % Save as .png
        close(gcf); % Close the figure to save memory

    end
    
    fprintf('Processing complete: %s\n', filename);

    close all;

    % Clear large variables to free memory
    clearvars -except file_path output_path condition excel_file_path;
end
