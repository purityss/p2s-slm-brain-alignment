close all
clear all

load('pho_sem_shared_signals.mat')
load('seeg_times.mat')

% Extract all signals from the third column
% all_signals{1} = pho_only_contacts_signal(:,3);  % 210x1 cell, each cell is a 1x716 array
% all_signals{2} = sem_only_contacts_signal(:,3);  % 218x1 cell, each cell is a 1x716 array
% all_signals{3} = shared_contacts_signal(:,3);    % 43x1 cell, each cell is a 1x716 array

for k = 1:3
    all_signals_k = all_signals{k};
    
    % Convert to a matrix (Automatically stack by row)
    signal_matrix = cell2mat(all_signals_k);  
    signal = signal_matrix;
    t = seeg_times;
    
    %% Baseline correction / Normalization
    disp('Baseline correction ...');
    
    %%% get signal times (pnts in second)
    signal_times = transpose(t);
                 
    %%% find onset timepoint
    onset_pnts = find(signal_times == 0);
    srate = 512;
            
    %%% get baseline per trial
    signal_baseline = signal(:, 1:onset_pnts-1);
            
    % Calculate baseline mean and standard deviation
    baseline_mean = nanmean(signal_baseline, 2);
    baseline_std  = nanstd(signal_baseline, 0, 2);
    baseline_std(baseline_std == 0) = eps;  % Avoid division by zero
    
    % Expand to each time point to match the signal dimensions
    signal_baseline_mean = repmat(baseline_mean, 1, size(signal,2));
    signal_baseline_std  = repmat(baseline_std,  1, size(signal,2));
    
    signal_zscore = (signal - signal_baseline_mean) ./ signal_baseline_std;
    signal_absrel = (signal - signal_baseline_mean) ./ signal_baseline_mean;
    
    Ave = mean(signal_zscore, 1);
    n = size(signal_zscore, 1);               % Get the number of samples (rows)
    SE = std(signal_zscore, 0, 1) / sqrt(n);  % Calculate standard error
    
    disp('Baseline correction ... Done');
    disp('');
    
    Ave_signal(k,:) = Ave;
    SE_signal(k,:) = SE;
end

%% Plot Figures
gcf1 = figure(1);
k = 1;
set(gcf, 'Position', [100, 100, 170, 122]);  % Set a more reasonable figure proportion
set(gcf, 'Color', 'w');  % Set background color to white
shadedErrorBar(t, Ave_signal(k,:), SE_signal(k,:), 'lineProps', {'-', 'color', [231/256, 126/256, 121/256]}); hold on
h1 = plot(t, Ave_signal(k,:), 'color', [231/256, 126/256, 121/256]); 
xline(0, '-', 'Color', [0.6, 0.6, 0.6], 'LineWidth', 0.5);
axis([-200 800 -1 15]);
xticks(0:400:800);
yticks(0:5:15);
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'YColor', 'k', 'XColor', 'k');
ylabel('Z-scored HGA (a.u.)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
xlabel('Time(s)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');

gcf2 = figure(2);
k = 3;
set(gcf, 'Position', [100, 100, 170, 122]);  % Set a more reasonable figure proportion
set(gcf, 'Color', 'w');  % Set background color to white
shadedErrorBar(t, Ave_signal(k,:), SE_signal(k,:), 'lineProps', {'-', 'color', [158/256, 137/256, 193/256]}); hold on
h1 = plot(t, Ave_signal(k,:), 'color', [158/256, 137/256, 193/256]); 
xline(0, '-', 'Color', [0.6, 0.6, 0.6], 'LineWidth', 0.5);
axis([-200 800 -1 15]);
xticks(0:400:800);
yticks(0:5:15);
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'YColor', 'k', 'XColor', 'k');
ylabel('Z-scored HGA (a.u.)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
xlabel('Time(s)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');

gcf3 = figure(3);
k = 2;
set(gcf, 'Position', [100, 100, 170, 122]);  % Set a more reasonable figure proportion
set(gcf, 'Color', 'w');  % Set background color to white
shadedErrorBar(t, Ave_signal(k,:), SE_signal(k,:), 'lineProps', {'-', 'color', [112/256, 166/256, 202/256]}); hold on
h1 = plot(t, Ave_signal(k,:), 'color', [112/256, 166/256, 202/256]); 
xline(0, '-', 'Color', [0.6, 0.6, 0.6], 'LineWidth', 0.5);
axis([-200 800 -1 15]);
xticks(0:400:800);
yticks(0:5:15);
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'YColor', 'k', 'XColor', 'k');
ylabel('Z-scored HGA (a.u.)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
xlabel('Time(s)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');