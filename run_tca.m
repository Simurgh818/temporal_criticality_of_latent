function run_tca(file_path, output_path, condition, excel_file_path)
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
    post_window = cell(num_trials,1);

    % Convert time to indices
    pre_idx = find(time_vector >= pre_window(1) & time_vector <= pre_window(2));

    % TCA on pre-stimulus window
    pre_data = beta_signal(:, pre_idx,:); % ch x time x trial
    [num_ch,time_size,~] = size(pre_data);

    % Initialize results matrix (Trials x PCs)
    num_pcs = 59; % Number of Principal Components to extract
    post_data = [];
    post_data_p2_500ms = {};
    post_data_p2_2000ms = {};
    post_data_p3_500ms = {};
    post_data_p3_missing = {};

    if strcmp(condition, 'BLA') || strcmp(condition, 'BLT')
        post_window = [0, 0.4];  % Post-stimulus window (0ms to +400ms)
        post_idx = find(time_vector >= post_window(1) & time_vector <= post_window(2));
           
        % TCA on post-stimulus window
        post_data = beta_signal(:, post_idx,:); % ch x time x trial
    elseif strcmp(condition, 'P1')
        post_window = [0, 1.020];  % Post-stimulus window (0ms to +1020ms)
        post_idx = find(time_vector >= post_window(1) & time_vector <= post_window(2));
        
        % TCA on post-stimulus window
        post_data = beta_signal(:, post_idx,:); % ch x time x trial
    elseif strcmp(condition, 'P2')
        % Read data for both conditions
        trials_500ms = readmatrix(excel_file_path, 'Sheet', 'Audio onset with 500 ms tactile');
        trials_2000ms = readmatrix(excel_file_path, 'Sheet', 'Audio onset with 2000 ms tactil');
        
        for t = 1:num_trials
            if ismember(epoch_trials(t), trials_500ms)
                post_window = [0, 1.020];
                % Find indices within that window
                post_idx = find(time_vector >= post_window(1) & ...
                                  time_vector <= post_window(2));
                post_data_p2_500ms{end+1} = beta_signal(:, post_idx, t);  % ch x time

            elseif ismember(epoch_trials(t), trials_2000ms)
                post_window = [0, 2.400];
                post_idx = find(time_vector >= post_window(1) & ...
                          time_vector <= post_window(2));
                post_data_p2_2000ms{end+1} = beta_signal(:, post_idx, t);  % ch x time
            end
           
        end      
        % Now convert lists into 3D tensors
        post_data_p2_500ms = cat(3, post_data_p2_500ms{:});
        post_data_p2_2000ms = cat(3, post_data_p2_2000ms{:});
    elseif strcmp(condition, 'P3')
        trials_500ms = readmatrix(excel_file_path, 'Sheet', 'Audio onset with 500 ms tactile');
        trials_missing = readmatrix(excel_file_path, 'Sheet', 'Audio onset with missing tactil');

        for t = 1:num_trials
            if ismember(epoch_trials(t), trials_500ms)
                post_window = [0, 1.020];
                post_idx = find(time_vector >= post_window(1) & ...
                                  time_vector <= post_window(2));
                post_data_p3_500ms{end+1} = beta_signal(:, post_idx, t);  % ch x time
            elseif ismember(epoch_trials(t), trials_missing)
                post_window = [0, 1.0200];
                post_idx = find(time_vector >= post_window(1) & ...
                          time_vector <= post_window(2));
                post_data_p3_missing{end+1} = beta_signal(:, post_idx, t);  % ch x time
            end
        end         
        post_data_p3_500ms = cat(3, post_data_p3_500ms{:});
        post_data_p3_missing = cat(3, post_data_p3_missing{:}); 
    end

    % Define the range of components to test
    num_components = 1:59;  % Test 1 to 59 components
    reconstruction_errors_pre = zeros(size(num_components));
    explained_variance_pre = zeros(size(num_components));
    reconstruction_errors_post = zeros(size(num_components));
    explained_variance_post = zeros(size(num_components));
    
    [~, filename, ~] = fileparts(file_path);
    parts = split(filename, ' ');
    subject  = parts{end};
    for idx = 1:length(num_components)
        k = num_components(idx);
    
        [U_pre, ~] = cpd(pre_data, k, 'Display', 0);
        reconstructed_pre = cpdgen(U_pre);
        error_pre = norm(pre_data(:) - reconstructed_pre(:)) / norm(pre_data(:));
        reconstruction_errors_pre(idx) = error_pre;
        explained_variance_pre(idx) = 1 - error_pre^2;
        
        if strcmp(condition, 'BLA') || strcmp(condition, 'BLT') || strcmp(condition, 'P1')

            [U_post, ~] = cpd(post_data, k, 'Display', 0);
            reconstructed_post = cpdgen(U_post);
            error_post = norm(post_data(:) - reconstructed_post(:)) / norm(post_data(:));
            reconstruction_errors_post(idx) = error_post;
            explained_variance_post(idx) = 1 - error_post^2;
        elseif strcmp(condition, 'P2')
            [U_post_p2_500ms, ~] = cpd(post_data_p2_500ms, k, 'Display', 0);
            reconstructed_post_p2_500ms = cpdgen(U_post_p2_500ms);
            error_post_p2_500ms = norm(post_data_p2_500ms(:) - reconstructed_post_p2_500ms(:)) / norm(post_data_p2_500ms(:));
            reconstruction_errors_post_p2_500ms(idx) = error_post_p2_500ms;
            explained_variance_post_p2_500ms(idx) = 1 - error_post_p2_500ms^2;

            [U_post_p2_2000ms, ~] = cpd(post_data_p2_2000ms, k, 'Display', 0);
            reconstructed_post_p2_2000ms = cpdgen(U_post_p2_2000ms);
            error_post_p2_2000ms = norm(post_data_p2_2000ms(:) - reconstructed_post_p2_2000ms(:)) / norm(post_data_p2_2000ms(:));
            reconstruction_errors_post_p2_2000ms(idx) = error_post_p2_2000ms;
            explained_variance_post_p2_2000ms(idx) = 1 - error_post_p2_2000ms^2;

        elseif strcmp(condition, 'P3')
            [U_post_p3_500ms, ~] = cpd(post_data_p3_500ms, k, 'Display', 0);
            reconstructed_post_p3_500ms = cpdgen(U_post_p3_500ms);
            error_post_p3_500ms = norm(post_data_p3_500ms(:) - reconstructed_post_p3_500ms(:)) / norm(post_data_p3_500ms(:));
            reconstruction_errors_post_p3_500ms(idx) = error_post_p3_500ms;
            explained_variance_post_p3_500ms(idx) = 1 - error_post_p3_500ms^2;

            [U_post_p3_missing, ~] = cpd(post_data_p3_missing, k, 'Display', 0);
            reconstructed_post_p3_missing = cpdgen(U_post_p3_missing);
            error_post_p3_missing = norm(post_data_p3_missing(:) - reconstructed_post_p3_missing(:)) / norm(post_data_p3_missing(:));
            reconstruction_errors_post_p3_missing(idx) = error_post_p3_missing;
            explained_variance_post_p3_missing(idx) = 1 - error_post_p3_missing^2;

        end

    end
    
    if strcmp(condition, 'BLA') || strcmp(condition, 'BLT') || strcmp(condition, 'P1')

        % Plot reconstruction error
        figure('Position', [100, 100, 1500, 1000]); % [x, y, width, height]
        subplot(2,2,1)
        plot(num_components, reconstruction_errors_pre, 'o-', 'LineWidth', 2);
        xlabel('Number of Components');
        ylabel('Reconstruction Error (Relative)');
        title('Reconstruction Error Pre stim vs. Number of Components');
        grid on;
        
        % Plot explained variance
        subplot(2,2,2)
        plot(num_components, explained_variance_pre, 's-', 'LineWidth', 2);
        xlabel('Number of Components');
        ylabel('Explained Variance');
        title('Explained Variance Pre stim vs. Number of Components');
        grid on;
        
        subplot(2,2,3)
        plot(num_components, reconstruction_errors_post, 'o-', 'LineWidth', 2);
        xlabel('Number of Components');
        ylabel('Reconstruction Error (Relative)');
        title('Reconstruction Error Post stim vs. Number of Components');
        grid on;
        
        % Plot explained variance
        subplot(2,2,4)
        plot(num_components, explained_variance_post, 's-', 'LineWidth', 2);
        xlabel('Number of Components');
        ylabel('Explained Variance');
        title('Explained Variance Post stim vs. Number of Components');
        grid on;
    
        sgtitle([subject ' Reconstruction Error and Explained Variance']);
        
    
        % Save squared differences matrix as .mat file
        save(fullfile(output_path, [subject '_reconstruction_errors_pre.mat']), 'reconstruction_errors_pre');
        save(fullfile(output_path, [subject '_reconstruction_errors_post.mat']), 'reconstruction_errors_post');
        save(fullfile(output_path, [subject '_explained_variance_pre.mat']), 'explained_variance_pre');
        save(fullfile(output_path, [subject '_explained_variance_post.mat']), 'explained_variance_post');
        saveas(gcf, fullfile(output_path, [subject '_reconstruction_error_and_explained_variance.fig']));
        saveas(gcf, fullfile(output_path, [subject '_reconstruction_error_and_explained_variance.png']));
    
        threshold = 0.85;  % Target explained variance threshold    
        pc_at_85_pre = find(round(explained_variance_pre,2) >= threshold, 1, 'first');
        pc_at_85_post = find(round(explained_variance_post,2) >= threshold, 1, 'first');

        if isempty(pc_at_85_pre)
            [U_pre, ~] = cpd(pre_data, num_pcs);
        else
            [U_pre, ~] = cpd(pre_data, pc_at_85_pre);
        end
        
        if isempty(pc_at_85_post)
            [U_post, ~] = cpd(post_data, num_pcs);
        else
            [U_post, ~] = cpd(post_data, pc_at_85_post);
        end  
                
        save(fullfile(output_path, [subject '_U_pre.mat']), 'U_pre');
        save(fullfile(output_path, [subject '_U_post.mat']), 'U_post');
    
        figure('Position', [100, 100, 1200, 1800]);  % Adjust size for vertical layout
        for comp = 1:9
            row = comp;
        
            % Neuron factor (Column 1)
            subplot(9, 3, (row - 1)*3 + 1);
            bar(U_pre{1}(:, comp));
            title(['Neuron - Comp ' num2str(comp)]);
            xlabel('EEG Channel');
            ylabel('Loading');
            grid on;
        
            % Temporal factor (Column 2)
            subplot(9, 3, (row - 1)*3 + 2);
            plot(time_vector(pre_idx), U_pre{2}(:, comp), 'LineWidth', 2);
            title(['Temporal - Comp ' num2str(comp)]);
            xlabel('Time (s)');
            ylabel('Loading');
            grid on;
        
            % Trial factor (Column 3)
            subplot(9, 3, (row - 1)*3 + 3);
            stem(U_pre{3}(:, comp), 'filled');
            title(['Trial - Comp ' num2str(comp)]);
            xlabel('Trial');
            ylabel('Loading');
            grid on;
        end
        sgtitle([subject ' Neuron, Temporal, and Trial Factor Loadings (Pre-Stimulus)']);
        saveas(gcf, fullfile(output_path, [subject '_pre_stimulus_factors_loadings.fig']));
        saveas(gcf, fullfile(output_path, [subject '_pre_stimulus_factors_loadings.png']));
    
        figure('Position', [100, 100, 1200, 1800]);  % Adjust size for vertical layout
        for comp = 1:9
            row = comp;
        
            % Neuron factor (Column 1)
            subplot(9, 3, (row - 1)*3 + 1);
            bar(U_post{1}(:, comp));
            title(['Neuron - Comp ' num2str(comp)]);
            xlabel('EEG Channel');
            ylabel('Loading');
            grid on;
        
            % Temporal factor (Column 2)
            subplot(9, 3, (row - 1)*3 + 2);
            plot(time_vector(post_idx), U_post{2}(:, comp), 'LineWidth', 2);
            title(['Temporal - Comp ' num2str(comp)]);
            xlabel('Time (s)');
            ylabel('Loading');
            grid on;
        
            % Trial factor (Column 3)
            subplot(9, 3, (row - 1)*3 + 3);
            stem(U_post{3}(:, comp), 'filled');
            title(['Trial - Comp ' num2str(comp)]);
            xlabel('Trial');
            ylabel('Loading');
            grid on;
        end
        sgtitle([subject ' Neuron, Temporal, and Trial Factor Loadings (Post-Stimulus)']);
        saveas(gcf, fullfile(output_path, [subject '_post_stimulus_factors_loadings.fig']));
        saveas(gcf, fullfile(output_path, [subject '_post_stimulus_factors_loadings.png']));

    % Continuation for condition 'P2'
    elseif strcmp(condition, 'P2')
        figure('Position', [100, 100, 1500, 1000]);
        subplot(2,2,1)
        plot(num_components, reconstruction_errors_post_p2_500ms, 'o-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Reconstruction Error');
        title('Post-Stimulus 500ms Trials'); grid on;
    
        subplot(2,2,2)
        plot(num_components, explained_variance_post_p2_500ms, 's-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Explained Variance');
        title('Explained Variance 500ms Trials'); grid on;
    
        subplot(2,2,3)
        plot(num_components, reconstruction_errors_post_p2_2000ms, 'o-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Reconstruction Error');
        title('Post-Stimulus 2000ms Trials'); grid on;
    
        subplot(2,2,4)
        plot(num_components, explained_variance_post_p2_2000ms, 's-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Explained Variance');
        title('Explained Variance 2000ms Trials'); grid on;
        sgtitle([subject ' Reconstruction Error and Explained Variance']);
        saveas(gcf, fullfile(output_path, [subject '_p2_reconstruction_error_and_explained_variance.fig']));
        saveas(gcf, fullfile(output_path, [subject '_p2_reconstruction_error_and_explained_variance.png']));
    
        % Save errors and variances
        save(fullfile(output_path, [subject '_reconstruction_errors_pre_p2.mat']), 'reconstruction_errors_pre');
        save(fullfile(output_path, [subject '_reconstruction_errors_post_p2_500ms.mat']), 'reconstruction_errors_post_p2_500ms');
        save(fullfile(output_path, [subject '_reconstruction_errors_post_p2_2000ms.mat']), 'reconstruction_errors_post_p2_2000ms');
        save(fullfile(output_path, [subject '_explained_variance_pre_p2.mat']), 'explained_variance_pre');
        save(fullfile(output_path, [subject '_explained_variance_post_p2_500ms.mat']), 'explained_variance_post_p2_500ms');
        save(fullfile(output_path, [subject '_explained_variance_post_p2_2000ms.mat']), 'explained_variance_post_p2_2000ms');
     

        % Save CPD for top 9 components for each condition
        [U_post_500ms, ~] = cpd(post_data_p2_500ms, num_pcs);
        [U_post_2000ms, ~] = cpd(post_data_p2_2000ms, num_pcs);
        save(fullfile(output_path, [subject '_U_post_p2_500ms.mat']), 'U_post_500ms');
        save(fullfile(output_path, [subject '_U_post_p2_2000ms.mat']), 'U_post_2000ms');
    
        for group = {'500ms', '2000ms'}
            tag = group{1};
            if strcmp(tag, '500ms')
                U = U_post_500ms;
                idx = find(time_vector >= 0 & time_vector <= 1.020);
            else
                U = U_post_2000ms;
                idx = find(time_vector >= 0 & time_vector <= 2.400);
            end
    
            figure('Position', [100, 100, 1200, 1800]);
            for comp = 1:9
                subplot(9, 3, (comp-1)*3 + 1);
                bar(U{1}(:, comp));
                title(['Neuron - Comp ' num2str(comp)]);
                xlabel('EEG Channel'); ylabel('Loading'); grid on;
    
                subplot(9, 3, (comp-1)*3 + 2);
                plot(time_vector(idx), U{2}(:, comp), 'LineWidth', 2);
                title(['Temporal - Comp ' num2str(comp)]);
                xlabel('Time (s)'); ylabel('Loading'); grid on;
    
                subplot(9, 3, (comp-1)*3 + 3);
                stem(U{3}(:, comp), 'filled');
                title(['Trial - Comp ' num2str(comp)]);
                xlabel('Trial'); ylabel('Loading'); grid on;
            end
            sgtitle([subject ' Neuron, Temporal, Trial Factor Loadings - ' tag]);
            saveas(gcf, fullfile(output_path, [subject '_p2_factors_loadings_' tag '.fig']));
            saveas(gcf, fullfile(output_path, [subject '_p2_factors_loadings_' tag '.png']));
        end

    % Continuation for condition 'P3'
    elseif strcmp(condition, 'P3')
        figure('Position', [100, 100, 1500, 1000]);
        subplot(2,2,1)
        plot(num_components, reconstruction_errors_post_p3_500ms, 'o-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Reconstruction Error');
        title('Post-Stimulus 500ms Trials'); grid on;
    
        subplot(2,2,2)
        plot(num_components, explained_variance_post_p3_500ms, 's-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Explained Variance');
        title('Explained Variance 500ms Trials'); grid on;
    
        subplot(2,2,3)
        plot(num_components, reconstruction_errors_post_p3_missing, 'o-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Reconstruction Error');
        title('Post-Stimulus Missing Trials'); grid on;
    
        subplot(2,2,4)
        plot(num_components, explained_variance_post_p3_missing, 's-', 'LineWidth', 2);
        xlabel('Number of Components'); ylabel('Explained Variance');
        title('Explained Variance Missing Trials'); grid on;
        sgtitle([subject ' Reconstruction Error and Explained Variance']);

        saveas(gcf, fullfile(output_path, [subject '_p3_reconstruction_error_and_explained_variance.fig']));
        saveas(gcf, fullfile(output_path, [subject '_p3_reconstruction_error_and_explained_variance.png']));

        save(fullfile(output_path, [subject '_reconstruction_errors_pre_p3.mat']), 'reconstruction_errors_pre');
        save(fullfile(output_path, [subject '_reconstruction_errors_post_p3_500ms.mat']), 'reconstruction_errors_post_p3_500ms');
        save(fullfile(output_path, [subject '_reconstruction_errors_post_p3_missing.mat']), 'reconstruction_errors_post_p3_missing');
         save(fullfile(output_path, [subject '_explained_variance_pre_p3.mat']), 'explained_variance_pre');
        save(fullfile(output_path, [subject '_explained_variance_post_p3_500ms.mat']), 'explained_variance_post_p3_500ms');
        save(fullfile(output_path, [subject '_explained_variance_post_p3_missing.mat']), 'explained_variance_post_p3_missing');
    
        [U_post_500ms, ~] = cpd(post_data_p3_500ms, num_pcs);
        [U_post_missing, ~] = cpd(post_data_p3_missing, num_pcs);
        save(fullfile(output_path, [subject '_U_post_p3_500ms.mat']), 'U_post_500ms');
        save(fullfile(output_path, [subject '_U_post_p3_missing.mat']), 'U_post_missing');
    
        for group = {'500ms', 'missing'}
            tag = group{1};
            if strcmp(tag, '500ms')
                U = U_post_500ms;
                idx = find(time_vector >= 0 & time_vector <= 1.020);
            else
                U = U_post_missing;
                idx = find(time_vector >= 0 & time_vector <= 1.020);
            end
    
            figure('Position', [100, 100, 1200, 1800]);
            for comp = 1:9
                subplot(9, 3, (comp-1)*3 + 1);
                bar(U{1}(:, comp));
                title(['Neuron - Comp ' num2str(comp)]);
                xlabel('EEG Channel'); ylabel('Loading'); grid on;
    
                subplot(9, 3, (comp-1)*3 + 2);
                plot(time_vector(idx), U{2}(:, comp), 'LineWidth', 2);
                title(['Temporal - Comp ' num2str(comp)]);
                xlabel('Time (s)'); ylabel('Loading'); grid on;
    
                subplot(9, 3, (comp-1)*3 + 3);
                stem(U{3}(:, comp), 'filled');
                title(['Trial - Comp ' num2str(comp)]);
                xlabel('Trial'); ylabel('Loading'); grid on;
            end
            sgtitle([subject ' Neuron, Temporal, Trial Factor Loadings - ' tag]);
            saveas(gcf, fullfile(output_path, [subject '_p3_factors_loadings_' tag '.fig']));
            saveas(gcf, fullfile(output_path, [subject '_p3_factors_loadings_' tag '.png']));
        end
    end

    fprintf('Processing complete: %s\n', filename);

    close all;

    % Clear large variables to free memory
    clearvars -except file_path output_path condition excel_file_path;


end