clear all
close all
name = 'qwen2_audio';
load(strcat(name, '_Cos_dist_rdm_conv_layer_neuron.mat'));
load(strcat(name, '_Cos_dist_rdm_audio_layer_neuron.mat'));
load(strcat(name, '_Cos_dist_rdm_transformer_layer_neuron.mat'));

% Set save path to a subfolder inside the current working directory
save_folder_2 = fullfile(pwd, 'all_layers_selective_neuron_token_t_label');
if ~exist(save_folder_2, 'dir')
    mkdir(save_folder_2); % Create the folder if it does not exist
end
save_folder_2 = [save_folder_2, filesep];

p_thresh = 0.05;
layer_num_conv = 2;
layer_num_audio = 32;
layer_num_transformer = 32;
neuron_conv = 1280;
neuron_audio = 1280;
neuron_transformer = 4096;
layer_num_conv_start = 1;
layer_num_conv_end = layer_num_conv;
layer_num_audio_start = layer_num_conv_end + 1;
layer_num_audio_end = layer_num_conv + layer_num_audio;
layer_num_transformer_start = layer_num_audio_end + 1;
layer_num_transformer_end = layer_num_audio_end + layer_num_transformer;

% Initialize storage structures
all_layer_neuron_token_phonology_t = {};
all_layer_neuron_token_semantics_t = {};
all_layer_neuron_token_p_s_t = {};
i_neuron = 0;

for layer = layer_num_conv_start:layer_num_conv_end
    layer = layer
    
        for neuron = 1:neuron_conv
        neuron = neuron;
        i_neuron = i_neuron + 1;
        
        for token = 1:2
            rdm = rdm_cell_conv{neuron,token,layer};
            
            % Phonology processing
            elements_tongyin = []; % Similar-Phonology (only different semantics)
            elements_yiyin = [];  % Different-Phonology (different semantics + similar semantics)
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
            elements_yiyi = [];   % Different-Semantics (different phonology + similar phonology)
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
             all_layer_neuron_token_phonology_t{i_neuron,token} = stats1.tstat; 
             all_layer_neuron_token_semantics_t{i_neuron,token} = stats2.tstat; 
          
            if stats1.tstat > 0 && stats2.tstat > 0
                if stats1.tstat > stats2.tstat
                    all_layer_neuron_token_p_s_t{i_neuron,token} = stats1.tstat; 
                else
                    all_layer_neuron_token_p_s_t{i_neuron,token} = -stats2.tstat;
                end
    
            elseif stats1.tstat > 0 && stats2.tstat <= 0  
                all_layer_neuron_token_p_s_t{i_neuron,token} = stats1.tstat;
    
            elseif stats1.tstat <= 0 && stats2.tstat > 0
                all_layer_neuron_token_p_s_t{i_neuron,token} = -stats2.tstat;
    
            else
                all_layer_neuron_token_p_s_t{i_neuron,token} = 0;
            end
            all_layer_neuron_token_p_s_t{i_neuron,3} = layer;
            all_layer_neuron_token_phonology_t{i_neuron,3} = layer;
            all_layer_neuron_token_semantics_t{i_neuron,3} = layer;
            
            all_layer_neuron_token_p_s_t{i_neuron,4} = neuron;
            all_layer_neuron_token_phonology_t{i_neuron,4} = neuron;
            all_layer_neuron_token_semantics_t{i_neuron,4} = neuron;
        
        end        
        end
end

for layer = layer_num_audio_start:layer_num_audio_end
    layer = layer
    
    % Initialize variables
    p_only_layer_005 = []; p_only_neuron_005 = []; p_only_token_005 = []; p_only_t_005 = [];
    s_only_layer_005 = []; s_only_neuron_005 = []; s_only_token_005 = []; s_only_t_005 = [];
    p_s_both_layer_005 = []; p_s_both_neuron_005 = []; p_s_both_token_005 = []; p_s_both_pt_005 = []; p_s_both_st_005 = [];
    p_s_none_layer_005 = []; p_s_none_neuron_005 = []; p_s_none_token_005 = []; p_s_none_pt_005 = []; p_s_none_st_005 = [];
        for neuron = 1:neuron_audio
        neuron = neuron;
        i_neuron = i_neuron + 1;
        
        for token = 1:2
            rdm = rdm_cell_audio{neuron,token,layer};
            
            % Phonology processing
            elements_tongyin = []; % Similar-Phonology (only different semantics)
            elements_yiyin = [];  % Different-Phonology (different semantics + similar semantics)
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
            elements_yiyi = [];   % Different-Semantics (different phonology + similar phonology)
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
             all_layer_neuron_token_phonology_t{i_neuron,token} = stats1.tstat; 
             all_layer_neuron_token_semantics_t{i_neuron,token} = stats2.tstat; 
          
            if stats1.tstat > 0 && stats2.tstat > 0
                if stats1.tstat > stats2.tstat
                    all_layer_neuron_token_p_s_t{i_neuron,token} = stats1.tstat; 
                else
                    all_layer_neuron_token_p_s_t{i_neuron,token} = -stats2.tstat;
                end
    
            elseif stats1.tstat > 0 && stats2.tstat <= 0  
                all_layer_neuron_token_p_s_t{i_neuron,token} = stats1.tstat;
    
            elseif stats1.tstat <= 0 && stats2.tstat > 0
                all_layer_neuron_token_p_s_t{i_neuron,token} = -stats2.tstat;
    
            else
                all_layer_neuron_token_p_s_t{i_neuron,token} = 0;
            end
            all_layer_neuron_token_p_s_t{i_neuron,3} = layer;
            all_layer_neuron_token_phonology_t{i_neuron,3} = layer;
            all_layer_neuron_token_semantics_t{i_neuron,3} = layer;
            
            all_layer_neuron_token_p_s_t{i_neuron,4} = neuron;
            all_layer_neuron_token_phonology_t{i_neuron,4} = neuron;
            all_layer_neuron_token_semantics_t{i_neuron,4} = neuron;
        end
        end
end

for layer = layer_num_transformer_start:layer_num_transformer_end
    layer = layer
    
    % Initialize variables
    p_only_layer_005 = []; p_only_neuron_005 = []; p_only_token_005 = []; p_only_t_005 = [];
    s_only_layer_005 = []; s_only_neuron_005 = []; s_only_token_005 = []; s_only_t_005 = [];
    p_s_both_layer_005 = []; p_s_both_neuron_005 = []; p_s_both_token_005 = []; p_s_both_pt_005 = []; p_s_both_st_005 = [];
    p_s_none_layer_005 = []; p_s_none_neuron_005 = []; p_s_none_token_005 = []; p_s_none_pt_005 = []; p_s_none_st_005 = [];
        for neuron = 1:neuron_transformer
        neuron = neuron;
        i_neuron = i_neuron + 1;
        
        for token = 1:2
            rdm = rdm_cell_transformer{neuron,token,layer};
            
            % Phonology processing
            elements_tongyin = []; % Similar-Phonology (only different semantics)
            elements_yiyin = [];  % Different-Phonology (different semantics + similar semantics)
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
            elements_yiyi = [];   % Different-Semantics (different phonology + similar phonology)
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
             all_layer_neuron_token_phonology_t{i_neuron,token} = stats1.tstat; 
             all_layer_neuron_token_semantics_t{i_neuron,token} = stats2.tstat; 
          
            if stats1.tstat > 0 && stats2.tstat > 0
                if stats1.tstat > stats2.tstat
                    all_layer_neuron_token_p_s_t{i_neuron,token} = stats1.tstat; 
                else
                    all_layer_neuron_token_p_s_t{i_neuron,token} = -stats2.tstat;
                end
    
            elseif stats1.tstat > 0 && stats2.tstat <= 0  
                all_layer_neuron_token_p_s_t{i_neuron,token} = stats1.tstat;
    
            elseif stats1.tstat <= 0 && stats2.tstat > 0
                all_layer_neuron_token_p_s_t{i_neuron,token} = -stats2.tstat;
    
            else
                all_layer_neuron_token_p_s_t{i_neuron,token} = 0;
            end
            all_layer_neuron_token_p_s_t{i_neuron,3} = layer;
            all_layer_neuron_token_phonology_t{i_neuron,3} = layer;
            all_layer_neuron_token_semantics_t{i_neuron,3} = layer;
            
            all_layer_neuron_token_p_s_t{i_neuron,4} = neuron;
            all_layer_neuron_token_phonology_t{i_neuron,4} = neuron;
            all_layer_neuron_token_semantics_t{i_neuron,4} = neuron;
        end
        end
end

% Save the overall structure for all layers
save([save_folder_2, num2str(name), '_all_layer_neuron_token_phonology_t.mat'], 'all_layer_neuron_token_phonology_t');
save([save_folder_2, num2str(name), '_all_layer_neuron_token_semantics_t.mat'], 'all_layer_neuron_token_semantics_t');
save([save_folder_2, num2str(name), '_all_layer_neuron_token_p_s_t.mat'], 'all_layer_neuron_token_p_s_t');