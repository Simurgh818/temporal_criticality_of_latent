function  run_pca_across_conditions(input_path, output_path, conditions, subject)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
   % Determine system paths
    % if exist('H:\', 'dir')
    %     input_path = 'H:\My Drive\Data\New Data\EEG epoched\';
    %     output_path = 'C:\Users\sinad\OneDrive - Georgia Institute of Technology\Dr. Sederberg MaTRIX Lab\temporal_criticality_of_latent_results';
    % elseif exist('G:\', 'dir')
    %     input_path = 'G:\My Drive\Data\New Data\EEG epoched\';
    %     output_path = 'C:\Users\sdabiri\OneDrive - Georgia Institute of Technology\Dr. Sederberg MaTRIX Lab\temporal_criticality_of_latent_results';
    % else
    %     error('Unknown system: Cannot determine input and output paths.');
    % end
    % 
    % conditions = {'BLA','BLT', 'P1', 'P2', 'P3'};
    num_ch = 32; 
    num_time_samples = 1792;
    num_trials = 60;
    num_conditions = length(conditions);
    beta_signal_giant = zeros(num_ch, num_time_samples * num_trials * num_conditions);
    col_start = 1;
    trials_to_plot = [1, 4, 8, 60];
    channel_to_plot = 18;
    num_plot_trials = length(trials_to_plot);
    

    for i = 1:length(conditions)
        condition = conditions{i};
        input_path_condition = fullfile(input_path, condition);
        % output_path_condition = fullfile(output_path, condition);
        % if strcmp(condition, 'P2')
        %     excel_file_path = fullfile(input_path, 'Indexes for P2.xlsx');
        % elseif strcmp(condition, 'P3')
        %     excel_file_path = fullfile(input_path, 'Indexes for P3.xlsx');
        % else
        %     excel_file_path = '';
        % end

        % if ~exist(output_path_condition, 'dir')
        %     mkdir(output_path_condition);
        % end
        
        %TODO: find the .set file for the specific subject and condition
        
        set_files = dir(fullfile(input_path_condition, '*.set'));
        % Find index of the file whose name contains 'Bos2'
        idx = find(contains({set_files.name}, [condition 'Avg' char(subject) '.set']));

        % Access the matched file(s)
        if ~isempty(idx)
            selected_file = set_files(idx(1));  % If multiple matches, select the first one
            disp(['Selected file: ' selected_file.name]);
        else
            error('No file containing %s found in the name field.', subject);
        end

        file_path = fullfile(input_path_condition, set_files(idx(1)).name);
        fprintf('Processing %s...\n', file_path);
        EEG = pop_loadset(file_path);

        fs = EEG.srate;
        time_vector = (0:num_time_samples-1) / fs;

        if ismember(condition, {'BLA', 'P1', 'P2', 'P3'})
            epoch_trials = 1:2:EEG.trials;
        elseif strcmp(condition, 'BLT')
            epoch_trials = 2:2:EEG.trials;
        else
            error('Condition not recognized.');
        end

        data = EEG.data(:, :, epoch_trials);
        beta_signal = zeros(size(data));
        for epoch = 1:size(data, 3)
            beta_signal(:,:,epoch) = bandpass(data(:,:,epoch)', [13 30], fs)';
        end

        beta_signal_reshape = reshape(beta_signal, num_ch, num_time_samples*num_trials);
        beta_signal_giant(:, col_start:col_start + size(beta_signal_reshape, 2) - 1) = beta_signal_reshape;
        col_start = col_start + size(beta_signal_reshape, 2);
        
        figure('Position', [100, 100, 1400, 800]);
        t = tiledlayout(num_plot_trials, 2, 'TileSpacing', 'compact');
        for j = 1:num_plot_trials
            trial_idx = trials_to_plot(j);
    
            raw_signal = squeeze(data(channel_to_plot, :, trial_idx));
            filtered_signal = squeeze(beta_signal(channel_to_plot, :, trial_idx));
    
            nexttile;
            plot(time_vector, raw_signal, 'k');
            title(sprintf('Raw - Trial %d', trial_idx));
            xlabel('Time (s)'); ylabel('Amplitude (\muV)');
            grid on;
    
            nexttile;
            plot(time_vector, filtered_signal, 'b');
            title(sprintf('Beta Filtered - Trial %d', trial_idx));
            xlabel('Time (s)'); ylabel('Amplitude (\muV)');
            grid on;
        end
        title(t, sprintf('Raw and Beta-Filtered EEG Signals for subject %s (Channel %d) - Condition: %s', subject, channel_to_plot, condition), 'FontWeight', 'bold');
        saveas(gcf, fullfile(output_path, [condition '_example_raw_vs_filtered_channel18.fig']));
        saveas(gcf, fullfile(output_path, [condition '_example_raw_vs_filtered_channel18.png']));
        close all;
    end
    
    % Create time vector in seconds
    n_samples = size(beta_signal_giant, 2);
    time_vector_sec = (0:n_samples - 1) / fs;
    
    figure('Name', 'Beta Signal Giant (Concatenated)', 'Position', [100, 100, 1200, 400]);
    plot(time_vector_sec, beta_signal_giant(channel_to_plot, :), 'b');
    title(sprintf('Concatenated Beta Band Signal for subject %s - Channel %d', subject, channel_to_plot));
    xlabel('Time (s)');
    ylabel('Amplitude (\muV)');
    grid on;
    
    % Save figure
    saveas(gcf, fullfile(output_path, sprintf('beta_signal_giant_channel%d.fig', channel_to_plot)));
    saveas(gcf, fullfile(output_path, sprintf('beta_signal_giant_channel%d.png', channel_to_plot)));


    % PCA computation
    [coeff, score, ~, ~, varExpl] = pca(beta_signal_giant');
    cum_sum_varExpl = cumsum(varExpl);
    threshold = 85;
    pc_at_85 = find(cum_sum_varExpl >= threshold, 1, 'first');
    coeff_z = zscore(coeff);

    % Plot explained variance and heatmap of PCs
    figure('Position', [100, 100, 1200, 500]);
    subplot(1,2,1);
    plot(varExpl, 'k', 'LineWidth', 1.5);
    xlabel('PC Index'); ylabel('Variance Explained (%)');
    title(sprintf('Explained Variance by PCs for subject %s', subject)); grid on;

    subplot(1,2,2);
    imagesc(coeff_z(:,1:pc_at_85)); set(gca, 'YDir', 'normal');
    xlabel('PCs'); ylabel('Channels'); title('PC Weights (Z-scored)');
    colormap jet; colorbar;

    saveas(gcf, fullfile(output_path, 'explained_variance_and_PC_heatmap.fig'));
    saveas(gcf, fullfile(output_path, 'explained_variance_and_PC_heatmap.png'));

    % Plot projections
    figure('Position', [100, 100, 1200, 1200]);
    t = tiledlayout(3,3); pc_colors = lines(pc_at_85);
    idx_range = time_vector>0.5 & time_vector<=2.4;

    for i = 1:pc_at_85
        nexttile;
        plot(time_vector(idx_range), score(idx_range,i), '-', 'LineWidth', 1, 'Color', pc_colors(i,:));
        title(['PC ', num2str(i)]); xlabel('time (s)'); ylabel('Score');
    end
    title(t, sprintf('EEG Data Projected onto First PCs for subject %s', subject));
    saveas(gcf, fullfile(output_path, 'PC_projections.fig'));
    saveas(gcf, fullfile(output_path, 'PC_projections.png'));

    % Reconstruction using first 9 PCs
    reconstructed = score(:, 1:pc_at_85) * coeff(:, 1:pc_at_85)';
    original_data = beta_signal_giant';
    reconstruction_error = mean((original_data(:) - reconstructed(:)).^2);
    fprintf('Reconstruction error using first %d PCs: %.4f\n', pc_at_85, reconstruction_error);

    % Channel 18 reconstruction
    example_channel = 18;
    figure('Position', [100, 100, 1000, 600]);
    plot(original_data(1:1792, example_channel), 'b'); hold on;
    plot(reconstructed(1:1792, example_channel), 'r--');
    legend('Original', 'Reconstructed');
    title(sprintf('Channel %d: Original vs Reconstructed (First %d PCs)', example_channel, pc_at_85));
    xlabel('Sample Index'); ylabel('Amplitude'); grid on;

    saveas(gcf, fullfile(output_path, 'reconstruction_channel18.fig'));
    saveas(gcf, fullfile(output_path, 'reconstruction_channel18.png'));
    close all;

    % Clear large variables to free memory
    clearvars -except input_path output_path conditions subject;
end