function run_pca_across_space(file_path, output_path, condition)
    % Load EEG dataset
    EEG = pop_loadset(file_path);

    % Extract relevant parameters
    fs = EEG.srate; % Sampling rate
    time_vector = linspace(-0.5, 3, size(EEG.data, 2)); % Time axis (-500ms to 3000ms)

    % Select odd or even epochs based on condition
    if strcmp(condition, 'BLA') || strcmp(condition, 'P1')
        epoch_trials = 1:2:EEG.trials; % Odd epochs
    elseif strcmp(condition, 'BLT')
        epoch_trials = 2:2:EEG.trials; % Even epochs
    else
        error('Condition not recognized. Please specify "BLA" or "BLT".');
    end

    num_trials = length(epoch_trials);

    % Define pre- and post-stimulus time windows (400ms before and after stimulus onset at 500ms)
    if strcmp(condition, 'BLA') || strcmp(condition, 'BLT')
        pre_window = [-0.4, 0];  % Pre-stimulus window (-400ms to 0ms)
        post_window = [0, 0.4];  % Post-stimulus window (0ms to +400ms)
    elseif strcmp(condition, 'P1')
        pre_window = [-0.4, 0];  % Pre-stimulus window (-400ms to 0ms)
        post_window = [0, 1.020];  % Post-stimulus window (0ms to +1020ms)
    end

    % Convert time to indices
    pre_idx = find(time_vector >= pre_window(1) & time_vector <= pre_window(2));
    post_idx = find(time_vector >= post_window(1) & time_vector <= post_window(2));

    % Initialize results matrix (Trials x PCs)
    num_pcs = 32; % Number of Principal Components to extract
    pc_diff_squared = zeros(num_trials, num_pcs);

    % Loop through each selected trial
    for i = 1:num_trials
        trial_idx = epoch_trials(i);
        trial_data = squeeze(EEG.data(:, :, trial_idx)); % Channels x Time

        % Perform PCA on the trial
        [coeff, score, ~] = pca(trial_data'); % Time x Channels -> PCA

        % Extract PCs within time windows
        pre_pcs = score(pre_idx, :); % Pre-stimulus PCs
        post_pcs = score(post_idx, :); % Post-stimulus PCs

        % Compute difference, then square
        pc_diff = sum(post_pcs, 1) - sum(pre_pcs, 1); % Sum across time, subtract pre from post
        pc_diff_squared(i, :) = pc_diff.^2; % Square each PC difference
    end

    % Extract filename for saving
    [~, filename, ~] = fileparts(file_path);

    % Save squared differences matrix as .mat file
    save(fullfile(output_path, [filename '_pc_diff_squared.mat']), 'pc_diff_squared');

    % Plot as heatmap
    figure;
    imagesc(1:length(epoch_trials)-1, 1:10, pc_diff_squared(:, 1:10)'); % Transpose so PCs are on the y-axis
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

    fprintf('Processing complete: %s\n', filename);
end
