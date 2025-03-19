function run_pca_across_space(file_path, output_path)
    % Load EEG data
    EEG = pop_loadset(file_path);
    fs = EEG.srate;  % Sampling frequency in Hz

    ic_data = EEG.icaact(:, :); 

    % Extract epochs
    odd_epochs = 1:2:EEG.trials;
    ic_data_odd = EEG.icaact(:, :, odd_epochs);
    
    % Bandpass filter beta band (13-30 Hz)
    beta_band = [13 30];
    beta_signal = zeros(size(ic_data_odd)); % Preallocate
    for epoch = 1:size(ic_data_odd, 3)
        beta_signal(:,:,epoch) = bandpass(ic_data_odd(:,:,epoch)', beta_band, fs)';
    end
    avg_ic_data = mean(beta_signal, 3); 

    % Define PCA parameters
    num_windows = 20;
    window_size = floor(size(avg_ic_data, 2) / num_windows);
    
    PCA_results = struct();
    all_scores = cell(1, num_windows);
    max_PCs = 0;

    % Loop over time windows
    for w = 1:num_windows
        start_idx = (w-1) * window_size + 1;
        end_idx = min(w * window_size, size(avg_ic_data, 2));
        window_data = avg_ic_data(:, start_idx:end_idx);

        % Perform PCA
        [coeff, score, latent] = pca(window_data');
        explained_variance = cumsum(latent) / sum(latent);
        num_components = find(explained_variance >= 0.85, 1);
        if isempty(num_components), num_components = 1; end
        num_components = min(num_components, size(score, 2));

        % Store results
        PCA_results(w).time_window = [start_idx, end_idx];
        PCA_results(w).scores = score(:, 1:num_components);
        PCA_results(w).explained_variance = explained_variance(1:num_components);
        all_scores{w} = score(:, 1:num_components);
        max_PCs = max(max_PCs, num_components);
    end

    % Normalize and prepare for plotting
    for w = 1:num_windows
        num_PCs = size(all_scores{w}, 2);
        if num_PCs < max_PCs
            all_scores{w} = [all_scores{w}, NaN(size(all_scores{w}, 1), max_PCs - num_PCs)];
        end
    end
    all_scores_matrix = cell2mat(all_scores);
    global_min = min(all_scores_matrix(:), [], 'omitnan');
    global_max = max(all_scores_matrix(:), [], 'omitnan');

    % Plot results
    figure;
    for w = 1:num_windows
        subplot(4, 5, w);
        imagesc(PCA_results(w).scores');
        colormap jet;
        caxis([global_min global_max]);
        colorbar;
        xlabel('Time (3.5 sec)');
        ylabel('PCs');
        title(['Window ' num2str(w)]);
    end

    % Extract filename token for saving
    [~, file_name, ~] = fileparts(file_path);
    last_token = regexp(file_name, '\s+', 'split');
    last_token = last_token{end};

    % Save outputs
    saveas(gcf, fullfile(output_path, ['PCA_Heatmaps_' last_token '.png']));
    saveas(gcf, fullfile(output_path, ['PCA_Heatmaps_' last_token '.fig']));
    save(fullfile(output_path, ['PCA_results_' last_token '.mat']), 'PCA_results');
    close(gcf);

    fprintf('Finished processing %s\n', file_name);
end