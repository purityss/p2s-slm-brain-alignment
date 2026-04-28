clear all
close all

%% 1. Data Loading
name = 'llasm';

% Load data file containing token RDMs
load(strcat(name, '_pho_avg_token_rdm.mat'));

token = 1;  % Select token {1, 2}
data = pho_avg_token_rdm{token};
mean_rdm = data;

%% 2. Normalization (Map max/min of RDM to 0-1)
rdm_min = min(mean_rdm(:));
rdm_max = max(mean_rdm(:));
rdm_norm = (mean_rdm - rdm_min) / (rdm_max - rdm_min);

%% 3. Extract Normalized Data: Phonology
elements_tongyin = []; % Homophones
elements_yiyin = [];   % Non-homophones

for x = 27:52
    for y = 1:26
        if x == y + 26
            elements_tongyin = [elements_tongyin, rdm_norm(x, y)];
        end
    end
end

for x = 2:52
    for y = 1:x-1
        if x ~= y + 26
            elements_yiyin = [elements_yiyin, rdm_norm(x, y)];
        end
    end
end

% Calculate means and standard errors
mean_tongyin = nanmean(elements_tongyin);
SE_tongyin = std(elements_tongyin)/sqrt(length(elements_tongyin));
mean_yiyin = nanmean(elements_yiyin);
SE_yiyin = std(elements_yiyin)/sqrt(length(elements_yiyin));

% Statistical test
[h_phon, p_phon] = ttest2(elements_tongyin, elements_yiyin);

%% 4. Extract Normalized Data: Semantics
elements_tongyi = [];  % Synonyms
elements_yiyi = [];    % Non-synonyms

for x = 2:26
    for y = 1:(x-1)
        elements_tongyi = [elements_tongyi, rdm_norm(x, y)];
    end
end
for x = 28:52
    for y = 27:(x-1)
        elements_tongyi = [elements_tongyi, rdm_norm(x, y)];
    end
end
for x = 27:52
    for y = 1:26
        elements_yiyi = [elements_yiyi, rdm_norm(x, y)];
    end
end           

% Calculate means and standard errors
mean_tongyi = nanmean(elements_tongyi);
SE_tongyi = std(elements_tongyi)/sqrt(length(elements_tongyi));
mean_yiyi = nanmean(elements_yiyi);
SE_yiyi = std(elements_yiyi)/sqrt(length(elements_yiyi));

% Statistical test
[h_sem, p_sem] = ttest2(elements_tongyi, elements_yiyi);

%% 5. Plot Single Y-axis Bar Chart
figure(2); clf;
set(gcf, 'Position', [500, 300, 100, 100]); 
hold on;

% Layout parameters
bar_width = 0.5;
bar_spacing = 0.65;
height_line = 0.85; % Significance line height

x1 = 1; 
x2 = x1 + bar_spacing;
x3 = x2 + bar_spacing + 0.13; 
x4 = x3 + bar_spacing;

% Phonology (Red colormap)
bar(x1, mean_tongyin, bar_width, 'FaceColor', [203/255, 43/255, 35/255], 'EdgeColor', 'none');
errorbar(x1, mean_tongyin, SE_tongyin, 'k', 'LineWidth', 0.5, 'CapSize', 0);

bar(x2, mean_yiyin, bar_width, 'FaceColor', [234/255, 139/255, 134/255], 'EdgeColor', 'none');
errorbar(x2, mean_yiyin, SE_yiyin, 'k', 'LineWidth', 0.5, 'CapSize', 0);

% Semantics (Blue colormap)
bar(x3, mean_tongyi, bar_width, 'FaceColor', [2/255, 88/255, 166/255], 'EdgeColor','none');
errorbar(x3, mean_tongyi, SE_tongyi, 'k', 'LineWidth', 0.5, 'CapSize', 0);

bar(x4, mean_yiyi, bar_width, 'FaceColor', [112/255, 166/255, 202/255], 'EdgeColor','none');
errorbar(x4, mean_yiyi, SE_yiyi, 'k', 'LineWidth', 0.5, 'CapSize', 0);

% Significance marker - Phonology
line([x1, x2], [height_line, height_line], 'Color', 'k', 'LineWidth', 0.5);
if h_phon == 1
    if p_phon < 0.001, txt = '***'; elseif p_phon < 0.01, txt = '**'; else, txt = '*'; end
    text((x1+x2)/2, height_line + 0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center');
else
    text((x1+x2)/2, height_line + 0.06, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
end

% Significance marker - Semantics
line([x3, x4], [height_line, height_line], 'Color', 'k', 'LineWidth', 0.5);
if h_sem == 1
    if p_sem < 0.001, txt = '***'; elseif p_sem < 0.01, txt = '**'; else, txt = '*'; end
    text((x3+x4)/2, height_line + 0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center');
else
    text((x3+x4)/2, height_line + 0.06, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
end

% Chart formatting
ylabel('Normalized distance', 'FontSize', 7, 'FontName', 'Arial');
set(gca, 'YTick', 0:0.5:1, 'YLim', [0, 1]); % Leave space at the top
set(gca, 'XTick', [], 'XTickLabel', [], 'Box', 'off', 'TickDir', 'out', 'LineWidth', 0.5);
set(gca, 'FontSize', 7, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');
xlim([0.45, 3.65]); % Reduce edge margins