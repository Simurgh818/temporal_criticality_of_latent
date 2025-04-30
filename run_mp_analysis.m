function [latent_chan, lambda_max_chan, lambda_min_chan, n_sig_chan, ...
          latent_time, lambda_max_time, lambda_min_time, n_sig_time, ...
          latent_trial, lambda_max_trial, lambda_min_trial, n_sig_trial] = ...
    run_mp_analysis(data)
    
    [channels, time_points, trials] = size(data);
    
    %% 1. CHANNEL MODE ANALYSIS
    % Reshape to [channels × (time * trials)]
    X_chan = reshape(data, channels, []);   % [channels × (time*trial)]
    
    % Z-score each row (normalize each channel)
    X_chan = zscore(X_chan, 0, 2);  % zero mean, unit variance along rows
    
    % Do PCA on the covariance of X_chan
    [~, ~, latent_chan] = pca(X_chan', 'Algorithm', 'eig');  % gives channels eigenvalues
    
    % Compute MP bounds
    c_chan = channels / size(X_chan, 2);
    lambda_max_chan = (1 + sqrt(c_chan))^2;
    lambda_min_chan = (1 - sqrt(c_chan))^2;
    
    % Count significant components
    n_sig_chan = sum(latent_chan > lambda_max_chan);
    
    %% 2. TIME MODE ANALYSIS
    % Reshape to [time × (channels * trials)]
    X_time = reshape(permute(data, [2, 1, 3]), time_points, []);  % [time × (ch*trial)]
    
    % Z-score
    X_time = zscore(X_time, 0, 2);  % normalize each time point
    
    % PCA
    [~, ~, latent_time] = pca(X_time', 'Algorithm', 'eig');  % gives time_points eigenvalues
    
    % Compute MP bounds
    c_time = time_points / size(X_time, 2);
    lambda_max_time = (1 + sqrt(c_time))^2;
    lambda_min_time = (1 - sqrt(c_time))^2;
    
    % Count significant components
    n_sig_time = sum(latent_time > lambda_max_time);
    
    %% 3. TRIAL MODE ANALYSIS
    % Reshape to [trials × (channels * time)]
    X_trial = reshape(permute(data, [3, 1, 2]), trials, []);  % [trials × (ch*time)]
    
    % Z-score
    X_trial = zscore(X_trial, 0, 2);  % normalize each trial
    
    % PCA
    [~, ~, latent_trial] = pca(X_trial', 'Algorithm', 'eig');  % gives trials eigenvalues
    
    % Compute MP bounds
    c_trial = trials / size(X_trial, 2);
    lambda_max_trial = (1 + sqrt(c_trial))^2;
    lambda_min_trial = (1 - sqrt(c_trial))^2;
    
    % Count significant components
    n_sig_trial = sum(latent_trial > lambda_max_trial);
end