clear
close all

name = "qwen_audio";

% Load Data
load(strcat(name, '_lesion_rank_results_pho_num.mat'));
pho_lesion = lesion_results;

load(strcat(name, '_lesion_rank_results_sem_num.mat'));
sem_lesion = lesion_results;

load(strcat(name, '_lesion_rank_results_both_num.mat'));
both_lesion = lesion_results;

% Extract X-axis (Column 1 is the lesion neuron count)
pho_x = pho_lesion(:, 1);
sem_x = sem_lesion(:, 1);
both_x = both_lesion(:, 1);

% Extract CER values (Column 4) and convert to accuracy/performance
pho_cer = 1 - pho_lesion(:, 4);
sem_cer = 1 - sem_lesion(:, 4);
both_cer = 1 - both_lesion(:, 4);

% Plotting
gcf = figure;
set(gcf, 'Position', [100, 100, 260, 160]);  % Set a more reasonable figure proportion

% Define colors
color_p = [180, 37, 35] / 255;       % pho (Red)
color_s = [34, 91, 142] / 255;       % sem (Blue)
color_both = [103, 38, 141] / 255;   % both (Purple)

% Draw curves
% 1. pho: Solid circle ('o')
plot(pho_x, pho_cer, '-o', 'LineWidth', 1, 'Color', color_p, ...
    'MarkerFaceColor', color_p, 'MarkerEdgeColor', 'none', 'MarkerSize', 4); 
hold on;

% 2. sem: Solid square ('s')
plot(sem_x, sem_cer, '-s', 'LineWidth', 1, 'Color', color_s, ...
    'MarkerFaceColor', color_s, 'MarkerEdgeColor', 'none', 'MarkerSize', 4);

% 3. both: Solid diamond ('d')
plot(both_x, both_cer, '-d', 'LineWidth', 1, 'Color', color_both, ...
    'MarkerFaceColor', color_both, 'MarkerEdgeColor', 'none', 'MarkerSize', 4);
hold off;

% Plot aesthetics
xlim([0 1400]); 
xticks(0:500:1400); % Corrected from yticks to xticks

ylim([0.4 1]); 
yticks(0.4:0.2:1);

xlabel('Lesioned model neuron count', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k');
ylabel('Model performance(Fleurs-zh)', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k');

grid on;
set(gca, 'FontSize', 7, 'Box', 'off', 'TickDir', 'out', 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');