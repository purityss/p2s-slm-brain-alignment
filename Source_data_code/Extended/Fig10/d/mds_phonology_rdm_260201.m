clear all
close all

% save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202601\Fig5_part';
save_fig_path = 'G:\Research\01 Speech_Comprehension\02 Figure_AI\Fig_sup_update_202604\ED10_part';
% save_fig_name_1 = 'mds_pho_sample_4';
save_fig_name_2 = 'sem_rdm_4';
% save_fig_name_2 = 'gyn_rdm_sample_2';
% save_fig_name_2 = 'hs_rdm_sample_4';


data_path = 'F:\code\Matlab work\code_for_SEEG_data\code_for_all_subjects\selective_contacts_step_rdm_not_control\all_sub_selective_contacts\MDS_RDM\sem_rdm_all_time\'; % 数据文件存放路径
subject_files_pattern = 'time*_rdm.mat'; % 匹配所有subject的文件模式

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
% mean_rdm = data{17,3}   %gyn 5
% mean_rdm = data{22,3}   %hs 95
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
% startColor = [200/255, 0, 0];    % 红
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
    
% 可视化降维结果，降为2维
figure(k);clf
set(gcf, 'Position', [500, 300, 115, 110]); 
hold on;

% % 绘制所有52个点
% scatter(Y(:,1), Y(:,2), 150, word_colors, 'filled'); % 点的大小设置为150

% 绘制1-26号点，并为它们设置标签
for i = 1:26
    scatter(Y(i,1), Y(i,2), 22, word_colors(i, :), 'filled'); % 绘制1-26号点
end

% 绘制27-52号点，但不添加标签
for i = 27:52
    scatter(Y(i,1), Y(i,2), 22, word_colors(i, :), 'filled'); % 绘制27-52号点
end

% 为前26个点设置图例标签（1到26）
legend_labels = arrayfun(@(x) num2str(x), 1:26, 'UniformOutput', false); % 生成1到26的标签
% legend(legend_labels, 'Location', 'bestoutside');  % 仅为前26个点生成图例

% 标题和标签
xlabel('Dimension 1');
ylabel('Dimension 2');
set(gca, 'FontSize', 8, 'FontName', 'Arial', 'TickDir', 'out', 'LineWidth', 0.5, 'XColor', 'k', 'YColor', 'k', 'XTick', [], 'YTick', []);    
axis equal;
set(gcf, 'Color', 'w');
xlim padded
ylim padded
% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_1,'.pdf']) ,'Resolution',600);


%% Plot RDM
similarityMatrix = mean_rdm;
% 确保 Y_normalized 维度正确
if length(Y_normalized) ~= 26
    error('Y_normalized 长度应为 26，但得到的是 %d，请检查 MDS 计算是否正确', length(Y_normalized));
end

% **复制 Y_normalized，使其变为 52×1**
Y_normalized_52 = [Y_normalized; Y_normalized]; 

% **获取新顺序**
[~, sortedIdx1] = sort(Y_normalized_52(1:26));  %升序，从小到大
[~, sortedIdx2] = sort(Y_normalized_52(27:52)); 
% [~, sortedIdx1] = sort(Y_normalized_52(1:26), 'descend');   %降序，从大到小
% [~, sortedIdx2] = sort(Y_normalized_52(27:52), 'descend'); 
newOrder = [sortedIdx1; sortedIdx2 + 26];

% **创建一个新 RDM**
reorderedRDM = NaN(52, 52); % 先填充 NaN

% **遍历原 `RDM` 的下三角部分**
for i = 2:52
    for j = 1:i-1  % 只操作下三角部分 (i > j)
        % 获取原来的 `RDM(i, j)`
        original_value = similarityMatrix(i, j);
        
        % 获取 `i, j` 在新排序中的索引
        new_i = find(newOrder == i);
        new_j = find(newOrder == j);
        
        % 确保 `new_i > new_j`，才能放到下三角
        if new_i > new_j
            reorderedRDM(new_i, new_j) = original_value;
        else
            reorderedRDM(new_j, new_i) = original_value;
        end
    end
end

reorderedRDM_all = reorderedRDM;

% 绘制对称平均差异矩阵的热图
figure_handle = figure(20+k); clf;
set(gcf, 'Position', [300, 300, 125, 120]); 
% colormap(figure_handle, jet);  % ✅ 强制设置当前 figure 的 colormap 为 jet
h = imagesc(reorderedRDM_all); % 绘制热图
% colormap parula; 
% colormap winter; 
% colormap viridis; 
% 1. 定义颜色节点 (从下往上提取颜色)
color1 = [50, 28, 90] / 255;   % 深蓝色 (底部)
color2 = [40, 100, 120] / 255;  % 紫色
color3 = [45, 175, 120] / 255;   % 粉红/珊瑚色
color4 = [170, 215, 60] / 255;  % 橙色
color5 = [252, 245, 65] / 255;  % 亮黄色 (顶部)
% 2. 组合控制点
control_colors = [color1; color2; color3; color4; color5];
% 3. 生成 256 级的平滑渐变
n = 256;
x = linspace(1, 5, size(control_colors, 1)); % 5个原始颜色节点的位置
xi = linspace(1, 5, n);                     % 插值后的 256 个位置
custom_map = interp1(x, control_colors, xi);
% 应用 colormap
colormap(custom_map);
% colorbar; % 显示颜色条预览效果

% 显示颜色条并为其命名
% colorbar;  % 显示颜色条并自动应用到图像
% 显示颜色条并取消刻度
% colorbar('Ticks', [], 'TickLabels', []);
% title('Symmetric Average Phonology RDM');
% xlabel('Words');
% ylabel('Words');
% 设置 NaN 的透明度
% 将 NaN 值的区域设置为透明
set(h, 'AlphaData', ~isnan(reorderedRDM_all)); 
set(gca, 'FontSize', 16);
set(gca, 'TickDir', 'out');
box off;

% **隐藏横纵坐标轴**
set(gca, 'XColor', 'none', 'YColor', 'none'); 
% **隐藏刻度**
set(gca, 'XTick', [], 'YTick', []); 
% **去掉轴标签**
xlabel('');
ylabel('');
% **去掉边框**
axis off;
hold off;
exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_2,'.pdf']) ,'Resolution',600);
% exportgraphics(gcf, fullfile(save_fig_path,[save_fig_name_2,'.png']) ,'Resolution',600);


end
