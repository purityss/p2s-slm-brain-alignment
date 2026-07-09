clear all
close all

% Define subject list
subjects = {'Sub01','Sub02','Sub03','Sub04','Sub05','Sub06','Sub07','Sub08','Sub09','Sub10','Sub11','Sub12','Sub13','Sub14','Sub15','Sub16','Sub17'};
% subjects = {'Sub01','Sub02'}

% Initialize storage structures
nchan_step_phonology_t = struct();  nchan_step_semantics_t = struct(); 
nchan_step_p_s_t = struct();
all_sub_nchan_step_phonology_t = {};
all_sub_nchan_step_semantics_t = {};
all_sub_nchan_step_p_s_t = {};

% Load and save paths
load_folder = 'C:\Path\To\Load_Folder\';
save_folder = 'C:\Path\To\Save_Folder\';
save_folder_2 = 'C:\Path\To\Save_Folder_2\';
i_contact = 0;

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
    
    for contact = 2:length(resp_contacts)
        nchan = resp_contacts(contact)
        i_contact = i_contact + 1;
        
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
            
          %% 
             nchan_step_phonology_t.name(contact-1,k-1) = stats1.tstat; 
             all_sub_nchan_step_phonology_t{i_contact,k-1} = stats1.tstat; 
             nchan_step_semantics_t.name(contact-1,k-1) = stats2.tstat;
             all_sub_nchan_step_semantics_t{i_contact,k-1} = stats2.tstat; 
          
            if stats1.tstat > 0 && stats2.tstat > 0
                if stats1.tstat > stats2.tstat
                    nchan_step_p_s_t.name(contact-1,k-1) = stats1.tstat; 
                    all_sub_nchan_step_p_s_t{i_contact,k-1} = stats1.tstat; 
                else
                    nchan_step_p_s_t.name(contact-1,k-1) = -stats2.tstat; 
                    all_sub_nchan_step_p_s_t{i_contact,k-1} = -stats2.tstat;
                end
    
            elseif stats1.tstat > 0 && stats2.tstat <= 0  
                nchan_step_p_s_t.name(contact-1,k-1) = stats1.tstat;
                all_sub_nchan_step_p_s_t{i_contact,k-1} = stats1.tstat;
    
            elseif stats1.tstat <= 0 && stats2.tstat > 0
                nchan_step_p_s_t.name(contact-1,k-1) = -stats2.tstat;
                all_sub_nchan_step_p_s_t{i_contact,k-1} = -stats2.tstat;
    
            else
                nchan_step_p_s_t.name(contact-1,k-1) = 0;
                all_sub_nchan_step_p_s_t{i_contact,k-1} = 0;
            end
            
            % Store results
            all_sub_nchan_step_p_s_t{i_contact,17} = name;
            all_sub_nchan_step_phonology_t{i_contact,17} = name;
            all_sub_nchan_step_semantics_t{i_contact,17} = name;
            
            all_sub_nchan_step_p_s_t{i_contact,18} = nchan;
            all_sub_nchan_step_phonology_t{i_contact,18} = nchan;
            all_sub_nchan_step_semantics_t{i_contact,18} = nchan;
            
        end
    end
end

% Save the overall structure for all subjects
save([save_folder, 'nchan_step_phonology_t.mat'], 'nchan_step_phonology_t');
save([save_folder, 'nchan_step_semantics_t.mat'], 'nchan_step_semantics_t');
save([save_folder, 'nchan_step_p_s_t.mat'], 'nchan_step_p_s_t');

save([save_folder_2, 'all_sub_nchan_step_phonology_t.mat'], 'all_sub_nchan_step_phonology_t');
save([save_folder_2, 'all_sub_nchan_step_semantics_t.mat'], 'all_sub_nchan_step_semantics_t');
save([save_folder_2, 'all_sub_nchan_step_p_s_t.mat'], 'all_sub_nchan_step_p_s_t');