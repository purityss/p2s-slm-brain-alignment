% Clean environment
clear; clc; close all;

% ==========================================
% 1. Data Preparation
% ==========================================
models = {'Xlsr-53-ch', 'Whisper-large-v3', 'LLaSM', 'SALMONN', 'Qwen-Audio', ...
          'Qwen-Audio-Chat', 'Qwen2-Audio', 'Qwen2-Audio-Instruct', ...
          'GLM-4-Voice', 'Freeze-Omni', 'Minicpm-o 2.6', 'Qwen2.5-Omni'};

% Baseline performance values
baselines = [76.15; 81.71; 4.84; 52.61; 84.33; 91.14; 90.90; 89.86; 74.49; 68.37; 93.22; 93.69];

% Performance after specific lesions
pho = [76.12; 81.60; 4.37; 52.33; 77.57; 91.19; 89.37; 86.52; 32.55; 67.95; 92.43; 93.11];
sem = [76.12; 81.60; 4.57; 51.46; 74.71; 90.95; 74.31; 88.14; 74.15; 77.00; 92.87; 93.45];
p2s = [76.14; 81.42; 4.75; 49.16; 47.23; 87.24; 60.72; 84.87; 64.49; 71.26; 93.42; 93.25];

% Calculate change in performance (Lesion - Baseline)
change_pho = pho - baselines;
change_sem = sem - baselines;
change_p2s = p2s - baselines;

% ==========================================
% 2. Visual Settings
% ==========================================
% Define categorical colors (Normalized RGB)
colors = [
    180/255, 37/255, 35/255;   % Phonology lesion
    34/255, 91/255, 142/255;   % Semantics lesion
    103/255, 38/255, 141/255   % P2S-transfer lesion
];

% ==========================================
% 3. Plotting
% ==========================================
figure('Position', [100, 100, 700, 450], 'Color', 'w');
t = tiledlayout(3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:12
    nexttile;
    
    % Current model data
    data = [change_pho(i), change_sem(i), change_p2s(i)];
    
    % Draw bar chart with specific width and no edges
    b = bar(1:3, data, 'FaceColor', 'flat', 'EdgeColor', 'none', 'BarWidth', 0.5);
    b.CData = colors;
    
    hold on;
    % Add reference line at zero
    yline(0, 'k-', 'LineWidth', 0.5);
    hold off;
    
    % Clean up X-axis
    xticks([]); 
    
    % Grid and aesthetic settings
    grid on;
    set(gca, 'FontName', 'Arial', ...
        'XGrid', 'off', 'YGrid', 'on', ...
        'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.5, ...
        'FontSize', 8, 'XColor', 'k', 'YColor', 'k');
    box off;
    
    % Minimalist axis styling
    ax = gca;
    ax.XRuler.Axle.LineStyle = 'none';
    ax.YRuler.Axle.LineStyle = 'none';
    ax.TickDir = 'out';
    
    % Set title per subplot
    title(models{i}, 'Interpreter', 'none', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k');
end

% Global Y-axis label
ylabel(t, 'Change in model performance (%)', 'FontName', 'Arial', 'FontSize', 8);