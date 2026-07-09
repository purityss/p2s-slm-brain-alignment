clear all
close all
load('pho_only_contacts.mat')
load('sem_only_contacts.mat')
load('both_contacts_p.mat')
load('both_contacts_s.mat')

save_folder = [pwd, filesep];
 
% 1. Convert to 'table' for deduplication
T = cell2table(pho_only_contacts, 'VariableNames', {'Subject', 'Electrode', 'Time', 'Col4', 'Col5', 'Col6'});
% 2. Group by (Subject, Electrode) and select the row with the earliest time
T_sorted = sortrows(T, {'Subject', 'Electrode', 'Time'}); % Sort first to ensure the earliest time index is at the top
[~, idx] = unique(T_sorted(:, {'Subject', 'Electrode'}), 'rows', 'stable'); % Get the row indices of the earliest times
T_filtered = T_sorted(idx, :); % Select the rows with the earliest times
% 3. Convert back to cell array
start_pho_only_contacts = table2cell(T_filtered);

% 1. Convert to 'table' for deduplication
T = cell2table(sem_only_contacts, 'VariableNames', {'Subject',  'Electrode', 'Time','Col4', 'Col5', 'Col6'});
% 2. Group by (Subject, Electrode) and select the row with the earliest time
T_sorted = sortrows(T, {'Subject', 'Electrode', 'Time'}); % Sort first to ensure the earliest time index is at the top
[~, idx] = unique(T_sorted(:, {'Subject', 'Electrode'}), 'rows', 'stable'); % Get the row indices of the earliest times
T_filtered = T_sorted(idx, :); % Select the rows with the earliest times
% 3. Convert back to cell array
start_sem_only_contacts = table2cell(T_filtered);

% 1. Convert to 'table' for deduplication
T = cell2table(both_contacts_p, 'VariableNames', {'Subject','Electrode', 'Time',  'Col4', 'Col5', 'Col6'});
% 2. Group by (Subject, Electrode) and select the row with the earliest time
T_sorted = sortrows(T, {'Subject', 'Electrode', 'Time'}); % Sort first to ensure the earliest time index is at the top
[~, idx] = unique(T_sorted(:, {'Subject', 'Electrode'}), 'rows', 'stable'); % Get the row indices of the earliest times
T_filtered = T_sorted(idx, :); % Select the rows with the earliest times
% 3. Convert back to cell array
start_both_contacts_p = table2cell(T_filtered);

% 1. Convert to 'table' for deduplication
T = cell2table(both_contacts_s, 'VariableNames', {'Subject', 'Electrode', 'Time','Col4', 'Col5',  'Col6'});
% 2. Group by (Subject, Electrode) and select the row with the earliest time
T_sorted = sortrows(T, {'Subject', 'Electrode', 'Time'}); % Sort first to ensure the earliest time index is at the top
[~, idx] = unique(T_sorted(:, {'Subject', 'Electrode'}), 'rows', 'stable'); % Get the row indices of the earliest times
T_filtered = T_sorted(idx, :); % Select the rows with the earliest times
% 3. Convert back to cell array
start_both_contacts_s = table2cell(T_filtered);

save([save_folder,'start_pho_only_contacts','.mat'],'start_pho_only_contacts');
save([save_folder,'start_sem_only_contacts','.mat'],'start_sem_only_contacts');
save([save_folder,'start_both_contacts_p','.mat'],'start_both_contacts_p');
save([save_folder,'start_both_contacts_s','.mat'],'start_both_contacts_s');