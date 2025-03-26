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
    post_idx = [];
    % Initialize results matrix (Trials x PCs)
    num_pcs = 32; % Number of Principal Components to extract
    allTrial_score = zeros(num_trials, length(time_vector), num_pcs);
    allTrial_pre_pcs = zeros(num_trials, length(pre_idx), num_pcs);
    allTrial_post_pcs = cell(num_trials, 1);
%     allTrial_post_pcs = zeros(num_trials, length(pre_idx)+1, num_pcs);
    allTrial_coeff = zeros(num_trials, num_pcs, num_pcs);
    allTrial_varExpl = zeros(num_pcs, num_trials);
    allTrial_scorepre = zeros(num_trials, length(pre_idx), num_pcs);
    allTrial_coeffpre = zeros(num_trials, num_pcs, num_pcs);
    allTrial_varExplpre =zeros(num_pcs, num_trials);
%     allTrial_scorepost = zeros(num_trials, length(pre_idx)+1,num_pcs);
    allTrial_scorepost = cell(num_trials,1);
    allTrial_coeffpost = zeros(num_trials, num_pcs, num_pcs);
    allTrial_varExplpost =zeros(num_pcs, num_trials);

    pc_diff_squared = zeros(num_trials, num_pcs);
    pc_cumulative_explained = zeros( num_pcs, num_trials);

    % Initialize matrix for normalized values
    pc_diff_squared_z = zeros(size(pc_diff_squared));

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
        [allTrial_coeff(i,:,:), allTrial_score(i,:,:), ~, ~, allTrial_varExpl(:, i)] = pca(trial_data');
        allTrial_pre_pcs(i,:,:) = allTrial_score(i, pre_idx, :);
%         allTrial_post_pcs(i,:,:) = allTrial_score(i, post_idx, :);
        allTrial_post_pcs{i} = allTrial_score(i, post_idx, :);

        % PCA on pre-stimulus window
        pre_data = trial_data(:, pre_idx)';
        [allTrial_coeffpre(i,:,:), allTrial_scorepre(i,:,:), ~, ~, allTrial_varExplpre(:, i)] = pca(pre_data);
        
        % PCA on post-stimulus window
        post_data = trial_data(:, post_idx)';
        [allTrial_coeffpost(i,:,:), allTrial_scorepost{i}, ~, ~, allTrial_varExplpost(:, i)] = pca(post_data);
    
        % Compute difference of sum, and square
        pc_diff = sum(allTrial_scorepost{i}, 1) - sum(squeeze(allTrial_scorepre(i,:,:)), 1); % Sum across time, subtract pre from post

        pc_diff_squared(i,:) = pc_diff.^2; % Square
    
        pc_mean = mean(pc_diff_squared(i, :));  % Mean across PCs for this trial
        pc_std = std(pc_diff_squared(i, :));   % Standard deviation across PCs for this trial
        
        % Avoid division by zero
        if pc_std == 0
            pc_std = 1;
        end
        
        % Compute z-score normalized values within the trial
        pc_diff_squared_z(i, :) = (pc_diff_squared(i, :) - pc_mean) / pc_std;
        
        % Compute cumulative sum of explained variance
        cumulative_explained_pre = cumsum(allTrial_varExplpre(:,i));
        cumulative_explained_post = cumsum(allTrial_varExplpost(:, i));
        pc_cumulative_explained (:, i) = cumulative_explained_post - cumulative_explained_pre; 

    end



    % Extract filename for saving
    [~, filename, ~] = fileparts(file_path);

    % Save squared differences matrix as .mat file
    save(fullfile(output_path, [filename '_pc_diff_squared_z.mat']), 'pc_diff_squared_z');
    save(fullfile(output_path, [filename 'pc_cumulative_explained.mat']), 'pc_cumulative_explained');
    
    if strcmp(condition, 'BLA') || strcmp(condition, 'BLT') || strcmp(condition, 'P1') 
        
        % Plot as heatmap
        figure;
        imagesc(1:length(epoch_trials)-1, 1:(length(pc_diff)), pc_diff_squared_z'); % Transpose so PCs are on the y-axis
        colorbar;
        xlabel('Trial Number');
        ylabel('Principal Component');
        title(['Squared Differences of PCs: ', filename]);
        set(gca, 'YDir', 'normal'); % Ensure correct orientation
        colormap jet;
    
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
        pc_diff_squared_z_500 = pc_diff_squared_z(idx_500, :);
        pc_diff_squared_z_2000 = pc_diff_squared_z(idx_2000, :);
        
        % Plot in subplots
        figure('Position', [100, 100, 1000, 400]); % [x, y, width, height]
        
        % Subplot for 500ms trials
        subplot(1, 2, 1);
        imagesc(1:size(pc_diff_squared_z_500, 1), 1:(length(pc_diff_squared_z_500)), pc_diff_squared_z_500');
        colorbar;
        xlabel('Trial Number');
        ylabel('Principal Component');
        title('500ms Trials: Normalized Squared Differences');
        set(gca, 'YDir', 'normal');
        colormap jet;
        
        % Subplot for 2000ms trials
        subplot(1, 2, 2);
        imagesc(1:size(pc_diff_squared_z_2000, 1), 1:(length(pc_diff_squared_z_2000)), pc_diff_squared_z_2000');
        colorbar;
        xlabel('Trial Number');
        ylabel('Principal Component');
        title('2000ms Trials: Normalized Squared Differences');
        set(gca, 'YDir', 'normal');
        colormap jet;
        
        % Ensure proper layout
        sgtitle('Comparison of 500ms vs 2000ms Trials');
                
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
        pc_diff_squared_z_500 = pc_diff_squared_z(idx_500, :);
        pc_diff_squared_z_missing = pc_diff_squared_z(idx_missing, :);
        
        % Plot in subplots
        figure('Position', [100, 100, 1000, 400]); % [x, y, width, height]
        
        % Subplot for 500ms trials
        subplot(1, 2, 1);
        imagesc(1:size(pc_diff_squared_z_500, 1), 1:(length(pc_diff_squared_z_500)), pc_diff_squared_z_500');
        colorbar;
        xlabel('Trial Number');
        ylabel('Principal Component');
        title('500ms Trials: Normalized Squared Differences');
        set(gca, 'YDir', 'normal');
        colormap jet;
        
        % Subplot for 2000ms trials
        subplot(1, 2, 2);
        imagesc(1:size(pc_diff_squared_z_missing, 1), 1:(length(pc_diff_squared_z_missing)), pc_diff_squared_z_missing');
        colorbar;
        xlabel('Trial Number');
        ylabel('Principal Component');
        title('Missing Trials: Normalized Squared Differences');
        set(gca, 'YDir', 'normal');
        colormap jet;
        
        % Ensure proper layout
        sgtitle('Comparison of 500ms vs Missing Trials');
        
        % Save figure
        savefig(fullfile(output_path, [filename '_pc_plot.fig'])); % Save as .fig
        saveas(gcf, fullfile(output_path, [filename '_pc_plot.png'])); % Save as .png
        close(gcf); % Close the figure to save memory

    end

    figure('Position', [100, 100, 1200, 800]); % [x, y, width, height]
    tiledlayout(4, 6)
    sgtitle([filename 'Comparison of pre and post stimulus PCs']);
    % Audrey's plot to compare selected PCs in trial1,4,8 and 60
    for i = [1 4 8 num_trials]
        % add the if statements for different conditions post_idx 
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

        nexttile
        plot(time_vector(pre_idx), squeeze(allTrial_pre_pcs(i,:,:)) )
        hold on
        plot(time_vector(pre_idx), squeeze(allTrial_scorepre(i,:, :)), '.-', 'linewidth', 1)
        title(['trial ' num2str(i) ', pre'])
        ylabel('components (pre)')
        xlabel('time')
        
        nexttile
        plot(time_vector(post_idx), squeeze(allTrial_post_pcs{i}))
        hold on
        plot(time_vector(post_idx), squeeze(allTrial_scorepost{i}), '.-', 'linewidth', 1)
        title(['trial ' num2str(i) ', post'])
        ylabel('components (post)')
        xlabel('time')
        
        nexttile
        imagesc(squeeze(allTrial_coeff (i, :,1:4)))
        ylabel('channels')
        xlabel('PC#')
        title('channel weights, full')
        
        nexttile
        imagesc(squeeze(allTrial_coeffpre(i, :, 1:4)))
        ylabel('channels')
        xlabel('PC#')
        title('channel weights, pre')
        
        nexttile
        imagesc(squeeze(allTrial_coeffpost(i, :, 1:4)))
        ylabel('channels')
        xlabel('PC#')
        title('channel weights, post')
        
        nexttile
        hold on
        plot(allTrial_varExpl(:,i), 'o-')
        plot(allTrial_varExplpre(:,i), '*-')
        plot(allTrial_varExplpost(:,i), '^-')
        xlim([0 6])
        ylabel('PC VarExpl')
        legend({'full', 'pre', 'post'})
    end

    % Save figure
    savefig(fullfile(output_path, [filename '_pc_prePost_plot.fig'])); % Save as .fig
    saveas(gcf, fullfile(output_path, [filename '_pc_prePost_plot.png'])); % Save as .png
    close(gcf); % Close the figure to save memory
    
    fprintf('Processing complete: %s\n', filename);

    close all;

    % Clear large variables to free memory
    clearvars -except file_path output_path condition excel_file_path;
end
