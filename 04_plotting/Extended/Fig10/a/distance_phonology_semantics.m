clear all
close all

% Set data paths to current directory
data_path = './'; 
subject_files_pattern = 'time*_rdm.mat'; 
height = 0.85;

% Get all subject files matching the pattern
subject_files = dir(fullfile(data_path, subject_files_pattern));

% Iterate through each subject file
for step = 1:length(subject_files)
    % Load current subject's mat file
    subject_file = fullfile(data_path, subject_files(step).name);
    load(subject_file); 
    
    % Extract the numeric suffix from the file name
    [~, file_name, ~] = fileparts(subject_files(step).name); 
    suffix_num = sscanf(file_name, 'time%d_rdm'); 
    k = suffix_num - 1;
    data = rdm_data_all;
    
    % Calculate mean RDM across electrodes (assuming column 3 contains the RDM matrices)
    mean_rdm = nanmean(cat(3, data{:,3}), 3);
    rdm = mean_rdm;
    
    %% ========== Normalize Data ==========
    % Normalize the RDM values to a 0-1 range
    rdm_min = min(rdm(:));
    rdm_max = max(rdm(:));
    rdm_norm = (rdm - rdm_min) / (rdm_max - rdm_min);

    %% ========== Extract Normalized Data: Phonology ==========
    elements_tongyin = []; % Homophones (different meaning)
    elements_yiyin = [];   % Non-homophones (different meaning + same meaning)
    
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
    
    % Calculate means and standard errors for normalized phonology data
    mean_tongyin = mean(elements_tongyin);
    SE_tongyin = std(elements_tongyin)/sqrt(length(elements_tongyin));
    mean_yiyin = mean(elements_yiyin);
    SE_yiyin = std(elements_yiyin)/sqrt(length(elements_yiyin));
    
    % Statistical test (Two-sample t-test)
    [h_phon, p_phon] = ttest2(elements_tongyin, elements_yiyin);
    
    % Print statistical results to console
    if h_phon == 1
        fprintf('Subject %d (Phonology): Significant difference, p-value: %f\n', k, p_phon);
    else
        fprintf('Subject %d (Phonology): No significant difference, p-value: %f\n', k, p_phon);
    end

    %% ========== Extract Normalized Data: Semantics ==========
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
    
    % Calculate means and standard errors for normalized semantic data
    mean_tongyi = mean(elements_tongyi);
    SE_tongyi = std(elements_tongyi)/sqrt(length(elements_tongyi));
    mean_yiyi = mean(elements_yiyi);
    SE_yiyi = std(elements_yiyi)/sqrt(length(elements_yiyi));
    
    % Statistical test (Two-sample t-test)
    [h_sem, p_sem] = ttest2(elements_tongyi, elements_yiyi);

    %% ========== Plot Single Y-axis Bar Chart ==========
    gcf = figure(20+k); clf;
    set(gcf, 'Position', [500, 300, 100, 100]); 
    hold on;
    
    % Bar configuration parameters
    bar_width = 0.5;
    bar_spacing = 0.65;
    x1 = 1; 
    x2 = x1 + bar_spacing;
    x3 = x2 + bar_spacing + 0.13; % Gap between phonology and semantic groups
    x4 = x3 + bar_spacing;
    
    % Plot Phonology group
    bar(x1, mean_tongyin, bar_width, 'FaceColor', [203/255, 43/255, 35/255], 'EdgeColor', 'none');
    errorbar(x1, mean_tongyin, SE_tongyin, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);
    
    bar(x2, mean_yiyin, bar_width, 'FaceColor', [234/255, 139/255, 134/255], 'EdgeColor', 'none');
    errorbar(x2, mean_yiyin, SE_yiyin, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);
    
    % Plot Semantics group
    bar(x3, mean_tongyi, bar_width, 'FaceColor', [2/255, 88/255, 166/255], 'EdgeColor', 'none');
    errorbar(x3, mean_tongyi, SE_tongyi, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);
    
    bar(x4, mean_yiyi, bar_width, 'FaceColor', [112/255, 166/255, 202/255], 'EdgeColor', 'none');
    errorbar(x4, mean_yiyi, SE_yiyi, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);
    
    % Draw significance markers (Phonology)
    line([x1, x2], [height, height], 'Color', 'k', 'LineWidth', 0.5);
    if h_phon == 1
        if p_phon < 0.001, txt = '***'; elseif p_phon < 0.01, txt = '**'; else, txt = '*'; end
        text((x1+x2)/2, height + 0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    else
        text((x1+x2)/2, height + 0.1, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
    end
    
    % Draw significance markers (Semantics)
    line([x3, x4], [height, height], 'Color', 'k', 'LineWidth', 0.5);
    if h_sem == 1
        if p_sem < 0.001, txt = '***'; elseif p_sem < 0.01, txt = '**'; else, txt = '*'; end
        text((x3+x4)/2, height+0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    else
        text((x3+x4)/2, height + 0.06, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
    end
    
    % Chart formatting
    ylabel('Normalized distance', 'FontSize', 7, 'FontName', 'Arial');
    set(gca, 'YTick', 0:0.5:1, 'YLim', [0, 1]); 
    set(gca, 'XTick', [], 'XTickLabel', [], 'Box', 'off', 'TickDir', 'out', 'LineWidth', 0.5);
    set(gca, 'FontSize', 7, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');
    xlim([0.45, 3.65]);
end