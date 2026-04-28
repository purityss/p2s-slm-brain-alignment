% Clean environment
clear; clc;

% ==========================================
% 1. Set file path and parameters
% ==========================================
% Path set to current directory
excel_file = 'MNI_3units_for_distance_HG.xlsx';

% Define MNI center coordinates for pmHG (primary auditory cortex)
% [Warning]: These are approximate coordinates. Replace with your lab's specific pmHG coordinates!
pmHG_L = [-44, -24, 8]; % Left pmHG MNI
pmHG_R = [ 46, -24, 6]; % Right pmHG MNI

% ==========================================
% 2. Define distance calculation function
% ==========================================
% Calculates distance to both hemispheres and takes the minimum (ipsilateral distance)
% coords is an N x 3 matrix (X, Y, Z)
calc_min_dist = @(coords) min( ...
    sqrt(sum((coords - pmHG_L).^2, 2)), ... % Distance to left pmHG
    sqrt(sum((coords - pmHG_R).^2, 2))  ... % Distance to right pmHG
);

% ==========================================
% 3. Read data, calculate, and save
% ==========================================
disp('Reading Excel data and calculating distances...');

% ---- 1. Phonology (pho) ----
% Extract columns 2-4 (X,Y,Z). readmatrix automatically skips the header.
coords_pho = readmatrix(excel_file, 'Sheet', 'pho', 'Range', 'B:D');
distance_pho = calc_min_dist(coords_pho); 
save('distance_pho.mat', 'distance_pho');
fprintf('Extracted %d Pho contacts, saved as distance_pho.mat\n', length(distance_pho));

% ---- 2. Semantics (sem) ----
coords_sem = readmatrix(excel_file, 'Sheet', 'sem', 'Range', 'B:D');
distance_sem = calc_min_dist(coords_sem);
save('distance_sem.mat', 'distance_sem');
fprintf('Extracted %d Sem contacts, saved as distance_sem.mat\n', length(distance_sem));

% ---- 3. Both (p2s) ----
coords_p2s = readmatrix(excel_file, 'Sheet', 'p2s', 'Range', 'B:D');
distance_both = calc_min_dist(coords_p2s); 
save('distance_both.mat', 'distance_both');
fprintf('Extracted %d P2S contacts, saved as distance_both.mat\n', length(distance_both));

disp('All calculations complete!');