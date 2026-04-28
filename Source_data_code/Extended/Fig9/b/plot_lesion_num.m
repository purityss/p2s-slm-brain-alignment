clear
close all

% --- Setup Parameters ---
name = "qwen2_audio";

% Load lesion results for LibriSpeech test-clean dataset
% Data structure: Col 1 = Number of lesioned neurons, Col 4 = Error Rate
load(strcat(name, '_lesion_rank_results_librispeech_testclean_pho.mat'));
pho_lesion = lesion_results;

load(strcat(name, '_lesion_rank_results_librispeech_testclean_sem.mat'));
sem_lesion = lesion_results;

load(strcat(name, '_lesion_rank_results_librispeech_testclean_both.mat'));
both_lesion = lesion_results;

% Extract X coordinates (Number of lesioned neurons)
pho_x = pho_lesion(:, 1);
sem_x = sem_lesion(:, 1);
both_x = both_lesion(:, 1);

% Extract Performance values (Performance = 1 - Error Rate)
pho_perf = 1 - pho_lesion(:, 4);
sem_perf = 1 - sem_lesion(:, 4);
both_perf = 1 - both_lesion(:, 4);

% --- Plotting ---
gcf = figure;
set(gcf, 'Position', [100, 100, 260, 160]); 

% Define categorical colors
color_p = [180, 37, 35] / 255;      % Phonology (Red)
color_s = [34, 91, 142] / 255;      % Semantics (Blue)
color_both = [103, 38, 141] / 255;   % Both/Shared (Purple)

hold on;

% 1. Phonology: solid circle ('o')
plot(pho_x, pho_perf, '-o', 'LineWidth', 1, 'Color', color_p, ...
    'MarkerFaceColor', color_p, 'MarkerEdgeColor', 'none', 'MarkerSize', 4); 

% 2. Semantics: solid square ('s')
plot(sem_x, sem_perf, '-s', 'LineWidth', 1, 'Color', color_s, ...
    'MarkerFaceColor', color_s, 'MarkerEdgeColor', 'none', 'MarkerSize', 4);

% 3. Both/Shared: solid diamond ('d')
plot(both_x, both_perf, '-d', 'LineWidth', 1, 'Color', color_both, ...
    'MarkerFaceColor', color_both, 'MarkerEdgeColor', 'none', 'MarkerSize', 4);

hold off;

% --- Figure Aesthetics ---
xlim([0 4500]); 
set(gca, 'XTick', 0:1000:4000);

ylim([0 1]); 
set(gca, 'YTick', 0:0.2:1);

xlabel('Lesioned model neuron count', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k');
% Updated label to reflect LibriSpeech context based on the filename
ylabel('Model performance (LibriSpeech)', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k');

grid on;
set(gca, 'FontSize', 7, 'Box', 'off', 'TickDir', 'out', 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');