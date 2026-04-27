close all
clear all

load('pho_only_contacts_signal.mat')
load('sem_only_contacts_signal.mat')
load('shared_contacts_signal.mat')
% load('none_contacts_signal.mat')
% load('no_resp_contacts_signal.mat')
load('seeg_times.mat')

save_fig_path = 'G:\Research\Auditory model\Figure_AI\Fig2_part_update';
save_fig_name_1 = 'HGA_pho';
save_fig_name_2 = 'HGA_both';
save_fig_name_3 = 'HGA_sem';

% 提取第三列的所有信号
all_signals{1}= pho_only_contacts_signal(:,3);  % 210×1 cell，每个 cell 是 1×716 数组
all_signals{2} = sem_only_contacts_signal(:,3);  % 218×1 cell，每个 cell 是 1×716 数组
all_signals{3} = shared_contacts_signal(:,3);  % 43×1 cell，每个 cell 是 1×716 数组
% all_signals{4} = none_contacts_signal(:,3);  % 43×1 cell，每个 cell 是 1×716 数组
% all_signals{5} = no_resp_contacts_signal(:,3);  % 43×1 cell，每个 cell 是 1×716 数组

for k = 1:3

all_signals_k = all_signals{k};
% 转成 210×716 的矩阵
signal_matrix = cell2mat(all_signals_k);  % 自动按行堆叠成 210×716

% 对每一列求均值（得到 1×716）
% signal = mean(signal_matrix, 1);
signal = signal_matrix;

t = seeg_times;

%% Baseline correction / Normalization
disp(['Baseline correction ...']);

%%% get signal times (pnts in second)
signal_times = transpose(t);
             
%%% find onset timepoint
onset_pnts = find(signal_times==0);
srate = 512;
        
%%% get baseline per trial
signal_baseline = signal(:,1:onset_pnts-1);
        
% 计算 baseline 平均值和标准差
baseline_mean = nanmean(signal_baseline, 2);
baseline_std  = nanstd(signal_baseline, 0, 2);
baseline_std(baseline_std == 0) = eps;  % 避免除以0

% 扩展到每个时间点（716 列）→ 和 signal 维度匹配
signal_baseline_mean = repmat(baseline_mean, 1, size(signal,2));  % 43×716
signal_baseline_std  = repmat(baseline_std,  1, size(signal,2));  % 43×716

signal_zscore = ( signal - signal_baseline_mean ) ./ signal_baseline_std;
signal_absrel = ( signal - signal_baseline_mean ) ./ signal_baseline_mean;

Ave = mean(signal_zscore,1);
n = size(signal_zscore, 1);          % 获取样本数量（行数）
SE = std(signal_zscore, 0, 1) / sqrt(n);  % 对每一列求 std，然后除以 sqrt(n)

disp(['Baseline correction ... Done']);
disp('');

Ave_signal(k,:) = Ave;
SE_signal(k,:) = SE;
end
%% plot all
% f = figure();
% for k =1:5
% subplot(5,1,k)
% set(f, 'Position', [100, 100, 900, 900]);
%     shadedErrorBar(t,Ave_signal(k,:),SE_signal(k,:),'lineProps','b');hold on
%     h1=plot(t,Ave_signal(k,:),'b'); 
%     xlabel('Time(ms)','FontSize',13);
%     ylabel('Z-scored HGA (a.u.)','FontSize',13);
%     axis([-200 800 0 15]);
%     xticks(-200:100:800);
% %     yticks(-1:1:4);
%     set(gca, 'TickDir', 'out');
%     set(gca,'FontSize',13);
%     box off; 
% end


gcf1 = figure(1);
k=1;
set(gcf, 'Position', [100, 100, 170, 122]);  % 更合理比例
set(gcf, 'Color', 'w');  % 背景白色
shadedErrorBar(t,Ave_signal(k,:),SE_signal(k,:),'lineProps',{'-', 'color', [231/256, 126/256, 121/256]});hold on
h1=plot(t,Ave_signal(k,:),'color',[231/256, 126/256, 121/256]); 
xline(0, '-', 'Color', [0.6, 0.6, 0.6], 'LineWidth', 0.5);
    % xlabel('Time(ms)','FontSize',13);
    % ylabel('Z-Amplitude (z-score)','FontSize',13);
    axis([-200 800 -1 15]);
    xticks(0:400:800);
    yticks(0:5:15);
   set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'YColor', 'k','XColor', 'k');
   ylabel('Z-scored HGA (a.u.)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
    xlabel('Time(s)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% exportgraphics(gcf1, fullfile(save_fig_path,[save_fig_name_1,'.pdf']) ,'Resolution',600);

gcf2 = figure(2);
k=3;
set(gcf, 'Position', [100, 100, 170, 122]);  % 更合理比例
set(gcf, 'Color', 'w');  % 背景白色
shadedErrorBar(t,Ave_signal(k,:),SE_signal(k,:),'lineProps',{'-', 'color', [158/256, 137/256, 193/256]});hold on
h1=plot(t,Ave_signal(k,:),'color',[158/256, 137/256, 193/256]); 
xline(0, '-', 'Color', [0.6, 0.6, 0.6], 'LineWidth', 0.5);
    % xlabel('Time(ms)','FontSize',13);
    % ylabel('Z-Amplitude (z-score)','FontSize',13);
    axis([-200 800 -1 15]);
    xticks(0:400:800);
    yticks(0:5:15);
   set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'YColor', 'k','XColor', 'k');
   ylabel('Z-scored HGA (a.u.)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
    xlabel('Time(s)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% exportgraphics(gcf2, fullfile(save_fig_path,[save_fig_name_2,'.pdf']) ,'Resolution',600);

gcf3 = figure(3);
k=2;
set(gcf, 'Position', [100, 100, 170, 122]);  % 更合理比例
set(gcf, 'Color', 'w');  % 背景白色
shadedErrorBar(t,Ave_signal(k,:),SE_signal(k,:),'lineProps',{'-', 'color', [112/256, 166/256, 202/256]});hold on
h1=plot(t,Ave_signal(k,:),'color',[112/256, 166/256, 202/256]); 
xline(0, '-', 'Color', [0.6, 0.6, 0.6], 'LineWidth', 0.5);
    % xlabel('Time(ms)','FontSize',13);
    % ylabel('Z-Amplitude (z-score)','FontSize',13);
    axis([-200 800 -1 15]);
    xticks(0:400:800);
    yticks(0:5:15);
   set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'YColor', 'k','XColor', 'k');
   ylabel('Z-scored HGA (a.u.)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
    xlabel('Time(s)', 'FontSize', 8, 'FontName', 'Arial', 'Color', 'k');
% exportgraphics(gcf3, fullfile(save_fig_path,[save_fig_name_3,'.pdf']) ,'Resolution',600);





