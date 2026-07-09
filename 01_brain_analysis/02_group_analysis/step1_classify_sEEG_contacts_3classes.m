clear all
close all

% Define subject list
subjects = {'Sub01','Sub02','Sub03','Sub04','Sub05','Sub06','Sub07','Sub08','Sub09','Sub10','Sub11','Sub12','Sub13','Sub14','Sub15','Sub16','Sub17'};

% Initialize storage structures
phonology_representation_005 = struct(); semantics_representation_005 = struct(); both_representation_005 = struct(); none_representation_005 = struct();
p_only_contact = struct(); s_only_contact = struct(); both_contact_p = struct(); both_contact_s = struct();
pho_only_contacts = {};
sem_only_contacts = {};
both_contacts_p = {};
both_contacts_s = {};

% Load and save paths
load_folder = 'C:\Path\To\Load_Folder\';
save_folder = 'C:\Path\To\Save_Folder\';
save_folder_2 = 'C:\Path\To\Save_Folder_2\';

for s = 1:length(subjects)
    name = subjects{s}
    
    % Load data
    rdm_files = dir(fullfile(load_folder, [name, '_nchan_HG_RDM_all*.mat']));
    contacts_files = dir(fullfile(load_folder, [name, '_resp_contacts_*.mat']));
    
    % Check if files exist
    if isempty(rdm_files) || isempty(contacts_files)
        warning(['Missing files for subject: ', name]);
        continue;
    end
    
    % Read files (since file names vary, select the first matched one)
    rdm_file = fullfile(load_folder, rdm_files(1).name);
    contacts_file = fullfile(load_folder, contacts_files(1).name);
    
    load(rdm_file);
    load(contacts_file);
    
    % Initialize variables
    p_only_nchan_005 = []; p_only_step_005 = []; p_only_t_005 = [];
    s_only_nchan_005 = []; s_only_step_005 = []; s_only_t_005 = [];
    p_s_both_nchan_005 = []; p_s_both_step_005 = []; p_s_both_pt_005 = []; p_s_both_st_005 = [];
    p_s_none_nchan_005 = []; p_s_none_step_005 = []; p_s_none_pt_005 = []; p_s_none_st_005 = [];
    
    for contact = 2:length(resp_contacts)
        nchan = resp_contacts(contact)
        
        % Iterate through time windows
        for k = 2:17
            % Extract RDM
            rdm = nchan_rdm{nchan,k};
            rdm(rdm == 0) = NaN;
            
            % Phonology processing
            elements_tongyin = []; % Similar-Phonology (only different semantics)
            elements_yiyin = [];   % Different-Phonology (different semantics + similar semantics)
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
            
            % Calculate mean values
            mean_tongyin = mean(elements_tongyin);
            mean_yiyin = mean(elements_yiyin);
            
            % Semantics processing
            elements_tongyi = [];  % Similar-Semantics (only different phonology)
            elements_yiyi = [];    % Different-Semantics (different phonology + similar phonology)
            for x = 2:26
                for y = 1:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 28:52
                for y = 27:(x-1)
                    elements_tongyi = [elements_tongyi, rdm(x, y)];
                end
            end
            for x = 27:52
                for y = 1:26
                    elements_yiyi = [elements_yiyi, rdm(x, y)];
                end
            end           
            
            % Calculate t-test
            [h1, p1, ~, stats1] = ttest2(elements_yiyin, elements_tongyin);
            [h2, p2, ~, stats2] = ttest2(elements_yiyi, elements_tongyi);
            
            % Record contact classification
            if p1 < 0.05 && stats1.tstat > 0 
                if p2 < 0.05 && stats2.tstat > 0
                    p_s_both_nchan_005 = [p_s_both_nchan_005, nchan];
                    p_s_both_step_005 = [p_s_both_step_005, k];
                    p_s_both_pt_005 = [p_s_both_pt_005, stats1.tstat];
                    p_s_both_st_005 = [p_s_both_st_005, stats2.tstat];
                else 
                    p_only_nchan_005 = [p_only_nchan_005, nchan];
                    p_only_step_005 = [p_only_step_005, k];
                    p_only_t_005 = [p_only_t_005, stats1.tstat];
                end
            else
                if p2 < 0.05 && stats2.tstat > 0  
                    s_only_nchan_005 = [s_only_nchan_005, nchan];
                    s_only_step_005 = [s_only_step_005, k];
                    s_only_t_005 = [s_only_t_005, stats2.tstat];
                else
                    p_s_none_nchan_005 = [p_s_none_nchan_005, nchan];
                    p_s_none_step_005 = [p_s_none_step_005, k];
                    p_s_none_pt_005 = [p_s_none_pt_005, stats1.tstat];
                    p_s_none_st_005 = [p_s_none_st_005, stats2.tstat];
                end
            end
        end
    end
    
    % Store results
    name_cell = repmat({name}, length(p_only_nchan_005), 1);
    phonology_representation_005.(name) = [name_cell, num2cell(p_only_nchan_005'), num2cell(p_only_step_005'), num2cell(p_only_t_005')];
    name_cell = repmat({name}, length(s_only_nchan_005), 1);
    semantics_representation_005.(name) = [name_cell, num2cell(s_only_nchan_005'), num2cell(s_only_step_005'), num2cell(s_only_t_005')];
    name_cell = repmat({name}, length(p_s_both_nchan_005), 1);
    both_representation_005.(name) = [name_cell, num2cell(p_s_both_nchan_005'), num2cell(p_s_both_step_005'), num2cell(p_s_both_pt_005'), num2cell(p_s_both_st_005')];
    name_cell = repmat({name}, length(p_s_none_nchan_005), 1);
    none_representation_005.(name) = [name_cell, num2cell(p_s_none_nchan_005'), num2cell(p_s_none_step_005'), num2cell(p_s_none_pt_005'), num2cell(p_s_none_st_005')];
    
    % Save results for each subject
%     save([save_folder, name, '_phonology_representation_005.mat'], 'phonology_representation_005');
%     save([save_folder, name, '_semantics_representation_005.mat'], 'semantics_representation_005');
%     save([save_folder, name, '_both_representation_005.mat'], 'both_representation_005');
%     save([save_folder, name, '_none_representation_005.mat'], 'none_representation_005');
    
    A = phonology_representation_005.(name);  % RDM representing phonology only
    B = semantics_representation_005.(name);  % RDM representing semantics only
    name_cell = repmat({name}, length(p_s_both_nchan_005), 1);
    C = [name_cell, num2cell(p_s_both_nchan_005'), num2cell(p_s_both_step_005'), num2cell(p_s_both_pt_005')];  % Representing both, phonology condition
    name_cell = repmat({name}, length(p_s_both_nchan_005), 1);
    D = [name_cell, num2cell(p_s_both_nchan_005'), num2cell(p_s_both_step_005'), num2cell(p_s_both_st_005')];  % Representing both, semantics condition
    
    % **Ensure A(:,2) and B(:,2) are strings**
    if isnumeric(A{1,2})
        A(:,2) = cellfun(@num2str, A(:,2), 'UniformOutput', false);
    end
    if isnumeric(B{1,2})
        B(:,2) = cellfun(@num2str, B(:,2), 'UniformOutput', false);
    end
    
    % Find elements with identical second columns in A and B (contact number nchan, subject name in first column is identical within loop)
    common_values = intersect(A(:,2), B(:,2));
    
    % Extract rows in A with second columns matching B, store in C
    for i = 1:length(common_values)
        matching_rows = strcmp(A(:,2), common_values{i}); % Use strcmp() for matching
        C = [C; A(matching_rows, :)];
    end
    
    % Extract rows in B with second columns matching A, store in D
    for i = 1:length(common_values)
        matching_rows = strcmp(B(:,2), common_values{i}); % Use strcmp() for matching
        D = [D; B(matching_rows, :)];
    end
    
    % Delete these rows from A and B
%     A(ismember(A(:,2), common_values), :) = [];
%     B(ismember(B(:,2), common_values), :) = [];
    
    % **Ensure C(:,1:2) and D(:,1:2) are strings** % Ensure C has at least 2 columns and is not empty
    if ~isempty(C) && size(C,2) >= 2
        if isnumeric(C{1,2})
            C(:,2) = cellfun(@num2str, C(:,2), 'UniformOutput', false);
        end
    end
    
    % Ensure D has at least 2 columns and is not empty
    if ~isempty(D) && size(D,2) >= 2
        if isnumeric(D{1,2})
            D(:,2) = cellfun(@num2str, D(:,2), 'UniformOutput', false);
        end
    end
    
    % **Ensure A(:,1:2) and B(:,1:2) are strings**
    if isnumeric(A{1,2})
        A(:,2) = cellfun(@num2str, A(:,2), 'UniformOutput', false);
    end
    if isnumeric(B{1,2})
        B(:,2) = cellfun(@num2str, B(:,2), 'UniformOutput', false);
    end
    
    % **Combine (subject name, contact number) as a unique identifier**
    A_identifiers = strcat(A(:,1), '_', A(:,2));
    B_identifiers = strcat(B(:,1), '_', B(:,2));
%     C_identifiers = strcat(C(:,1), '_', C(:,2));
%     D_identifiers = strcat(D(:,1), '_', D(:,2));
    
    % Ensure C has at least two columns
    if ~isempty(C) && size(C,2) >= 2
        C_identifiers = strcat(C(:,1), '_', C(:,2));
    else
        C_identifiers = {}; % Initialize as an empty array if empty
    end
    
    % Ensure D has at least two columns
    if ~isempty(D) && size(D,2) >= 2
        D_identifiers = strcat(D(:,1), '_', D(:,2));
    else
        D_identifiers = {}; % Initialize as an empty array if empty
    end
    
    % **Find (subject name, contact number) in C, D and delete them**
    A(ismember(A_identifiers, C_identifiers), :) = [];
    B(ismember(B_identifiers, D_identifiers), :) = [];
    
    p_only_contact.(name) = A;
    pho_only_contacts = [pho_only_contacts; A];
    s_only_contact.(name) = B;
    sem_only_contacts = [sem_only_contacts; B];
    both_contact_p.(name) = C;
    both_contacts_p = [both_contacts_p; C];
    both_contact_s.(name) = D;
    both_contacts_s = [both_contacts_s; D];
    
%     save([save_folder, name, '_p_only_contact.mat'], 'A');
%     save([save_folder, name, '_s_only_contact.mat'], 'B');
%     save([save_folder, name, '_both_contact_p.mat'], 'C');
%     save([save_folder, name, '_both_contact_s.mat'], 'D');
end

% Save the overall structure for all subjects
save([save_folder, 'all_subjects_phonology_representation_005.mat'], 'phonology_representation_005');
save([save_folder, 'all_subjects_semantics_representation_005.mat'], 'semantics_representation_005');
save([save_folder, 'all_subjects_both_representation_005.mat'], 'both_representation_005');
save([save_folder, 'all_subjects_none_representation_005.mat'], 'none_representation_005');
save([save_folder, 'all_subjects_p_only_contact.mat'], 'p_only_contact');
save([save_folder, 'all_subjects_s_only_contact.mat'], 's_only_contact');
save([save_folder, 'all_subjects_both_contact_p.mat'], 'both_contact_p');
save([save_folder, 'all_subjects_both_contact_s.mat'], 'both_contact_s');

save([save_folder_2, 'pho_only_contacts.mat'], 'pho_only_contacts');
save([save_folder_2, 'sem_only_contacts.mat'], 'sem_only_contacts');
save([save_folder_2, 'both_contacts_p.mat'], 'both_contacts_p');
save([save_folder_2, 'both_contacts_s.mat'], 'both_contacts_s');