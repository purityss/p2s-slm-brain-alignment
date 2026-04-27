clear all
close all

save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig5_part';
save_fig_name_1 = 'mds_sample_8';
save_fig_name_2 = 'distance_sample_8';

data_path = 'F:\code\Matlab work\code_for_SEEG_data\code_for_all_subjects\selective_contacts_step_rdm_not_control\all_sub_selective_contacts\MDS_RDM\both_rdm\'; % 数据文件存放路径
subject_files_pattern = 'time*_rdm.mat'; % 匹配所有subject的文件模式
height = 0.85;

% 获取所有subject的文件
subject_files = dir(fullfile(data_path, subject_files_pattern));

% 遍历每个subject的文件
for step = 1:length(subject_files)
    % 加载当前subject的mat文件
    subject_file = fullfile(data_path, subject_files(step).name);
    load(subject_file); % 假设文件中变量名与文件名一致
    % 提取文件名后缀的数字
    [~, file_name, ~] = fileparts(subject_files(step).name); % 分割文件名
    suffix_num = sscanf(file_name, 'time%d_rdm'); % 提取后缀数字
    k = suffix_num-1;
    data = rdm_data_all;
    
% 假设我们有一个 20x1 cell，每个元素是一个 52x52 的差异矩阵，代表20个电极点
num_electrodes = length(data); % 电极点数量
num_words = 52;       % 词语数量

mean_rdm = nanmean(cat(3, data{:,3}), 3);
mean_rdm_all = mean_rdm;

% 对称化矩阵：将左下部分对称到右上
for i = 1:num_words
    for j = i+1:num_words
        mean_rdm_all(i, j) = mean_rdm_all(j, i); % 上三角 = 下三角
    end
end

% 确保对角线为 0（余弦距离：完全相似的点应为 0）
mean_rdm_all(1:num_words+1:end) = 0;

distances = mean_rdm_all; 
% 使用 MDS 将距离矩阵降维到3维
% [Y, stress] = mdscale(distances, 3);
[Y, stress] = mdscale(distances, 2);

% 假设音频文件存储在 E:\Data\WordVocoder(160916) 文件夹中
folderPath = 'F:\data\01 Project_Speech_Comprehension\WordVocoder(160916)\';
input_texts = ["草莓", "带鱼", "蛋糕", "豆腐", "海带", "红薯", "鸡蛋", "煎饼", "荔枝", ...
    "龙虾", "萝卜", "绿豆", "芒果", "蜜桔", "面包", "蘑菇", "牛肉", "苹果", "软糖", ...
    "薯条", "西瓜", "香肠", "洋葱", "樱桃", "玉米", "猪蹄"];
numWords = numel(input_texts);
durationFirstSyllable = 0.25; % 前250ms

% STFT参数
frameLen = 256; 
frameOverlap = 128;
nfft = 512;

% 元音和辅音频率范围
vowelFreqRange = [200 1200]; % 元音频率范围
consonantFreqRange = [2000 8000]; % 辅音频率范围

% 特征权重（元音和辅音）
vowelWeight = 0.92;
consonantWeight = 0.08;

% 初始化特征矩阵
dummyAudio = rand(1, round(durationFirstSyllable * 16000)); % 模拟音频
stepSize = frameLen - frameOverlap;
numFrames = floor((length(dummyAudio) - frameOverlap) / stepSize);

% 频率索引计算
f = (0:(nfft/2)) * (16000 / nfft); % 频率轴
vowelFreqIdx = (f >= vowelFreqRange(1) & f <= vowelFreqRange(2));
consonantFreqIdx = (f >= consonantFreqRange(1) & f <= consonantFreqRange(2));

% 动态计算特征维度
numVowelFreqs = sum(vowelFreqIdx); % 元音频率数量
numConsonantFreqs = sum(consonantFreqIdx); % 辅音频率数量
numEnergyFrames = numFrames - 1; % 能量变化率的帧数
totalFeatures = (numVowelFreqs + numConsonantFreqs) * 2 + numEnergyFrames; % 平均频谱+标准差+能量变化率

features = zeros(numWords, totalFeatures);

for i = 1:numWords
    % 读取音频文件
    audioFile = fullfile(folderPath, [char(input_texts(i)) '.wav']);
    [audio, fs] = audioread(audioFile);
    
    % 截取前250ms音频
    numSamples = round(durationFirstSyllable * fs);
    audioSegment = audio(1:numSamples);
    
    % 手动实现 STFT
    numFrames = floor((length(audioSegment) - frameOverlap) / stepSize);
    stftMatrix = zeros(nfft, numFrames);
    window = hamming(frameLen, 'periodic');
    
    for j = 1:numFrames
        startIdx = (j-1) * stepSize + 1;
        endIdx = startIdx + frameLen - 1;
        frame = audioSegment(startIdx:endIdx) .* window; % 加窗
        fftResult = fft(frame, nfft); % FFT
        stftMatrix(:, j) = fftResult;
    end
    
    % 提取正频部分
    f = (0:(nfft/2)) * (fs / nfft);
    stftMatrix = stftMatrix(1:nfft/2+1, :);
    magnitude = abs(stftMatrix); % 幅值谱
    
    % 提取元音特征
    vowelMagnitude = magnitude(vowelFreqIdx, :);
    vowelMeanSpectrum = mean(vowelMagnitude, 2); % 平均频谱
    vowelStdSpectrum = std(vowelMagnitude, 0, 2); % 标准差频谱
    
    % 提取辅音特征
    consonantMagnitude = magnitude(consonantFreqIdx, :);
    consonantMeanSpectrum = mean(consonantMagnitude, 2); % 平均频谱
    consonantStdSpectrum = std(consonantMagnitude, 0, 2); % 标准差频谱
    
    % 提取能量变化率
    frameEnergy = sum(consonantMagnitude.^2, 1); % 短时能量
    energyDerivative = diff(frameEnergy); % 能量变化率
    
    % 融合元音和辅音特征
    combinedFeatures = [
        vowelWeight * vowelMeanSpectrum', vowelWeight * vowelStdSpectrum', ...
        consonantWeight * consonantMeanSpectrum', consonantWeight * consonantStdSpectrum', ...
        consonantWeight * energyDerivative
    ];
    
    % 赋值到特征矩阵
    features(i, :) = combinedFeatures;
end

% 计算相似性矩阵
Distances = pdist(features, 'euclidean');
similarityMatrix = squareform(Distances);

% 使用MDS降维到1维
YY = mdscale(similarityMatrix, 1);

% 定义颜色映射：从红到白到蓝
% startColor = [200/256, 0, 0];    % 红
startColor = [180/255, 0, 0];    % 红
endColor = [252/255, 229/255, 228/255];      % 浅粉
% endColor = [155/256, 46/256, 41/256];    % 红 startColor
% startColor = [243/256, 211/256, 209/256];      % 浅粉 endColor
% endColor = [160/256, 24/256, 24/256];    % 红 startColor
% startColor = [249/256, 219/256, 219/256];      % 浅粉 endColor
numColors = 256;

customColormap = [
    linspace(startColor(1), endColor(1), numColors)', ...
    linspace(startColor(2), endColor(2), numColors)', ...
    linspace(startColor(3), endColor(3), numColors)'
];

% 对Y值进行归一化，用于颜色映射
Y_normalized = (YY - min(YY)) / (max(YY) - min(YY));

% 应用自定义颜色映射
colormap(customColormap);

% 初始化词语的颜色矩阵
word_colors = zeros(num_words, 3);

% 将1-26号词语和27-52号词语设置为相同的颜色
for i = 1:26
    % 获取每个词语的颜色
    colorIdx = round(Y_normalized(i) * (numColors - 1)) + 1;  % 映射到颜色索引
%     colorIdx = round(Y_expanded_normalized(i) * (numColors - 1)) + 1;  % 映射到颜色索引
    word_colors(i, :) = customColormap(colorIdx, :);           % 设置1-26号词语的颜色
    word_colors(i+26, :) = customColormap(colorIdx, :);        % 设置27-52号词语的颜色
end

gcf = figure(k); clf;
% set(gcf, 'Position', [500, 300, 130, 125]); 
set(gcf, 'Position', [500, 300, 115, 110]); 
hold on;

% 设置边框颜色（你指定的绿色系）
% light_green = [172/255, 225/255, 67/255];
% dark_green = [47/255, 169/255, 41/255];
% light_green = [166/255, 199/255, 222/255];
% dark_green = [53/255, 104/255, 139/255];
light_green = [149/255, 180/255, 243/255];
dark_green = [17/255, 67/255, 167/255];

% 绘制前 26 个点（浅绿边框）
for i = 1:26
    scatter(Y(i,1), Y(i,2), 26, ...
        'MarkerFaceColor', word_colors(i, :), ...
        'MarkerEdgeColor', light_green, ...
        'LineWidth', 1.15);
end

% 绘制后 26 个点（深绿边框）
for i = 27:52
    scatter(Y(i,1), Y(i,2), 26, ...
        'MarkerFaceColor', word_colors(i, :), ...
        'MarkerEdgeColor', dark_green, ...
        'LineWidth', 1.15);
end

% 图形美化
xlabel('Dimension 1');
ylabel('Dimension 2');
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k', 'XTick', [], 'YTick', []);    
axis equal;
set(gcf, 'Color', 'w');
xlim padded
ylim padded
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_1,'.pdf']) ,'Resolution',600);


%% Plot Phonology Distance
rdm = mean_rdm;
elements_tongyin = []; %同音(只有不同义）
elements_yiyin = [];  %不同音（不同义+同义）
            for x = 27:52
                for y = 1:26
                    if x == y + 26
                        elements_tongyin = [elements_tongyin, rdm(x, y)];
                    end
                end
            end
            for x = 2:52
                for y = 1:x-1
                    if x ~= y + 26
                        elements_yiyin = [elements_yiyin, rdm(x, y)];
                    end
                end
            end
            
% 计算平均值
mean_tongyin = mean(elements_tongyin);
SE_tongyin = std(elements_tongyin)/(length(elements_tongyin))^0.5;
mean_yiyin = mean(elements_yiyin);
SE_yiyin = std(elements_yiyin)/(length(elements_yiyin))^0.5;

% Step 3: 进行双样本t检验
[h, p, ci, stats] = ttest2(elements_tongyin, elements_yiyin);
if h == 1
    fprintf('组内和组间距离有显著差异，p值为 %f\n', p);
else
    fprintf('组内和组间距离无显著差异，p值为 %f\n', p);
end

% Step 4: 绘制柱状图
gcf = figure(20+k); clf;
set(gcf, 'Position', [500, 300, 135, 109]);  % 原来是 720x600，缩紧一点

% 公共参数
bar_width = 0.52;
bar_spacing = 0.62;
%% ========== 归一化处理 ==========
rdm = mean_rdm;
% 排除对角线的 0 值（如果是计算距离，对角线通常不参与范围计算，或者视你的需求而定）
% 如果需要包含对角线，直接用 min(rdm(:))
rdm_min = min(rdm(:));
rdm_max = max(rdm(:));
rdm_norm = (rdm - rdm_min) / (rdm_max - rdm_min);

%% ========== 提取归一化后的数据：Phonology ==========
elements_tongyin = []; % 同音
elements_yiyin = [];   % 不同音
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

% 计算均值和标准误
mean_tongyin = mean(elements_tongyin);
SE_tongyin = std(elements_tongyin)/sqrt(length(elements_tongyin));
mean_yiyin = mean(elements_yiyin);
SE_yiyin = std(elements_yiyin)/sqrt(length(elements_yiyin));

% 统计检验
[h_phon, p_phon] = ttest2(elements_tongyin, elements_yiyin);

%% ========== 提取归一化后的数据：Semantics ==========
elements_tongyi = [];  % 同义
elements_yiyi = [];    % 不同义
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

% 计算均值和标准误
mean_tongyi = mean(elements_tongyi);
SE_tongyi = std(elements_tongyi)/sqrt(length(elements_tongyi));
mean_yiyi = mean(elements_yiyi);
SE_yiyi = std(elements_yiyi)/sqrt(length(elements_yiyi));

% 统计检验
[h_sem, p_sem] = ttest2(elements_tongyi, elements_yiyi);

%% ========== 绘制单 Y 轴柱状图 ==========
gcf = figure(20+k); clf;
set(gcf, 'Position', [500, 300, 100, 100]); % 宽度稍微调宽一点以容纳4根柱子
hold on;

% 公共参数
bar_width = 0.5;
bar_spacing = 0.65;
x1 = 1; 
x2 = x1 + bar_spacing;
x3 = x2 + bar_spacing + 0.13; % 语音和语义组之间稍微留个间隙
x4 = x3 + bar_spacing;

% 绘制 Phonology 组
% bar(x1, mean_tongyin, bar_width, 'FaceColor', [147/255, 37/255, 29/255], 'EdgeColor', 'none');
bar(x1, mean_tongyin, bar_width, 'FaceColor', [203/255, 43/255, 35/255], 'EdgeColor', 'none');
errorbar(x1, mean_tongyin, SE_tongyin, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);
% bar(x2, mean_yiyin, bar_width, 'FaceColor', [231/255, 126/255, 121/255], 'EdgeColor', 'none');
bar(x2, mean_yiyin, bar_width, 'FaceColor', [234/255, 139/255, 134/255], 'EdgeColor', 'none');
errorbar(x2, mean_yiyin, SE_yiyin, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);

% 绘制 Semantics 组
% bar(x3, mean_tongyi, bar_width, 'FaceColor', [2/255, 72/255, 137/255], 'EdgeColor','none');
bar(x3, mean_tongyi, bar_width, 'FaceColor', [2/255, 88/255, 166/255], 'EdgeColor','none');
errorbar(x3, mean_tongyi, SE_tongyi, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);
bar(x4, mean_yiyi, bar_width, 'FaceColor', [112/255, 166/255, 202/255], 'EdgeColor','none');
errorbar(x4, mean_yiyi, SE_yiyi, 'k', 'LineStyle', '-', 'LineWidth', 0.5, 'CapSize', 0);

% 动态计算显著性标记高度
h_max_phon = max(mean_tongyin + SE_tongyin, mean_yiyin + SE_yiyin);
h_max_sem = max(mean_tongyi + SE_tongyi, mean_yiyi + SE_yiyi);
mark_h_phon = h_max_phon + 0.05;
mark_h_sem = h_max_sem + 0.05;

% 绘制显著性标记 (Phonology)
line([x1, x2], [height, height], 'Color', 'k', 'LineWidth', 0.5);
if h_phon == 1
    if p_phon < 0.001, txt = '***'; elseif p_phon < 0.01, txt = '**'; else, txt = '*'; end
    text((x1+x2)/2, height + 0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
else
    text((x1+x2)/2, height + 0.1, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
end

% 绘制显著性标记 (Semantics)
line([x3, x4], [height, height], 'Color', 'k', 'LineWidth', 0.5);
if h_sem == 1
    if p_sem < 0.001, txt = '***'; elseif p_sem < 0.01, txt = '**'; else, txt = '*'; end
    text((x3+x4)/2, height+0.01, txt, 'FontSize', 10, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
else
    text((x3+x4)/2, height + 0.06, 'n.s.', 'FontSize', 7, 'HorizontalAlignment', 'center');
end

% 图表美化
ylabel('Normalized distance', 'FontSize', 7, 'FontName', 'Arial');
set(gca, 'YTick', 0:0.5:1, 'YLim', [0, 1]); % 归一化后统一到 0-1
set(gca, 'XTick', [], 'XTickLabel', [], 'Box', 'off', 'TickDir', 'out', 'LineWidth', 0.5);
set(gca, 'FontSize', 7, 'FontName', 'Arial', 'XColor', 'k', 'YColor', 'k');
xlim([0.45, 3.65]);

% 导出图片
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_2,'.pdf']) ,'Resolution',600);

end