% 清理环境
clear; clc;

% ==========================================
% 1. 设置文件路径与参数
% ==========================================
excel_file = 'G:\Research\01 Speech_Comprehension\01 Data_results\MNI_3units_for_distance_HG.xlsx';

% 定义 pmHG (初级听皮层) 的 MNI 中心坐标
% 【⚠️注意】：以下为文献中常用的近似坐标，请替换为你课题组实际定义的 pmHG 坐标！
pmHG_L = [-44, -24, 8]; % 左侧 pmHG 的 MNI 坐标
pmHG_R = [ 46, -24, 6]; % 右侧 pmHG 的 MNI 坐标

% ==========================================
% 2. 定义距离计算函数
% ==========================================
% 考虑到电极可能分布在双侧，这里计算电极到左右两侧 pmHG 的距离，并取最小值（即同侧距离）
% coords 是一个 N x 3 的矩阵 (X, Y, Z)
calc_min_dist = @(coords) min( ...
    sqrt(sum((coords - pmHG_L).^2, 2)), ... % 到左侧 pmHG 的距离
    sqrt(sum((coords - pmHG_R).^2, 2))  ... % 到右侧 pmHG 的距离
);

% 💡 补充：如果你只研究单侧（例如全是左脑电极），可以直接用固定的中心点：
% pmHG_center = [-42, -18, 10];
% calc_dist = @(coords) sqrt(sum((coords - pmHG_center).^2, 2));

% ==========================================
% 3. 读取数据、计算并保存
% ==========================================
disp('正在读取 Excel 数据并计算距离...');

% ---- 1. Phonology (pho) ----
% 使用 'Range', 'B:D' 直接精准提取第 2-4 列 (X,Y,Z)，readmatrix 会自动跳过第一行的表头字母
coords_pho = readmatrix(excel_file, 'Sheet', 'pho', 'Range', 'B:D');
distance_pho = calc_min_dist(coords_pho); % 计算距离，结果为 Nx1 的列向量
save('distance_pho.mat', 'distance_pho');
fprintf('Pho 提取了 %d 个 contacts，已保存为 distance_pho.mat\n', length(distance_pho));

% ---- 2. Semantics (sem) ----
coords_sem = readmatrix(excel_file, 'Sheet', 'sem', 'Range', 'B:D');
distance_sem = calc_min_dist(coords_sem);
save('distance_sem.mat', 'distance_sem');
fprintf('Sem 提取了 %d 个 contacts，已保存为 distance_sem.mat\n', length(distance_sem));

% ---- 3. Both (p2s) ----
coords_p2s = readmatrix(excel_file, 'Sheet', 'p2s', 'Range', 'B:D');
distance_both = calc_min_dist(coords_p2s); % 按照你的要求，命名为 both
save('distance_both.mat', 'distance_both');
fprintf('P2S 提取了 %d 个 contacts，已保存为 distance_both.mat\n', length(distance_both));

disp('全部计算完成！');