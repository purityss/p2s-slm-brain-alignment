clear
close all

load('num_units.mat')

%% 1. Prepare model names
models = { ...
    'XLSR-53-ch', 'Whisper-large-v3', 'LLaSM', 'SALMONN', ...
    'Qwen-Audio', 'Qwen-Audio-Chat', 'Qwen2-Audio', 'Qwen2-Audio-Instruct', ...
    'GLM-4-Voice', 'Freeze-Omni', 'MiniCPM-o 2.6', 'Qwen2.5-Omni'};

%% 2. Extract data and calculate percentages
% Modification 1: Reorder to [shared, pho, sem, ns] to ensure purple is at the bottom
plot_data_raw = num_units(:, [4, 2, 3, 5]); 
row_totals = sum(plot_data_raw, 2);
percentages = (plot_data_raw ./ row_totals) * 100;

%% 3. Define colors
color_p = [180, 37, 35] / 255;       % pho (Red)
color_s = [34, 91, 142] / 255;       % sem (Blue)
color_both = [103, 38, 141] / 255;   % shared (Purple)
color_ns = [0.7 0.7 0.7];            % non-sensitive (Gray)

colors = [color_both; color_p; color_s; color_ns];

%% 4. Modification 2: Three-segment Y-axis stretch logic
% Define visual nodes for non-linear stretching:
% 0% corresponds to position 0
% 1% corresponds to position 15 (Stretched to make small values visible)
% 50% corresponds to position 50
% 100% corresponds to position 100
transform_y = @(x) ...
    (x <= 1) .* (x * 15) + ...
    (x > 1 & x <= 50) .* (15 + (x - 1) * (35 / 49)) + ...
    (x > 50) .* (50 + (x - 50) * (50 / 50));

% Apply transformation to the stacked data
cum_perc = cumsum(percentages, 2);
trans_cum = zeros(size(cum_perc));
for i = 1:size(cum_perc, 1)
    for j = 1:size(cum_perc, 2)
        trans_cum(i,j) = transform_y(cum_perc(i,j));
    end
end

% Calculate differences for the transformed stacked bar
trans_plot_data = [trans_cum(:, 1), diff(trans_cum, 1, 2)];

%% 5. Plot stacked bar chart
figure('Color', 'w', 'Position', [100, 100, 370, 160]);
b = bar(trans_plot_data, 'stacked', 'EdgeColor', 'none', 'BarWidth', 0.65);

for k = 1:4
    b(k).FaceColor = colors(k, :);
end

%% 6. Chart formatting and tick settings
set(gca, 'XTick', 1:12, 'XTickLabel', models, ...
    'TickLabelInterpreter', 'none', 'FontSize', 6);
xtickangle(45); 

% Only label 0, 1, 50, and 100 on the Y-axis
tick_values = [0, 1, 50, 100];
set(gca, 'YTick', [transform_y(0), transform_y(1), transform_y(50), transform_y(100)], ...
    'YTickLabel', {'0', '1', '50', '100'});
ylabel('Proportion (%)', 'FontSize', 6);
title('Proportion of Units Types per Model', 'FontSize', 6);

set(gca, 'FontSize', 6, 'Box', 'off', 'FontName', 'Arial', 'TickDir', 'out', ...
    'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k');
grid off;
set(gca, 'Layer', 'top');
ylim([0 100]);