close all
clear all
name = 'Subject_ID'; % Anonymized subject/patient name
folder_path = 'C:\Path\To\Your\Data_Folder'; % Anonymized data folder path
file_name_NB = fullfile(folder_path, [num2str(name),  '_NB_150.mat']);
load(file_name_NB)
file_name_chanlocs = fullfile(folder_path, [num2str(name),  '_chanlocs.mat']);
load(file_name_chanlocs)
%%
resp_contacts = 0;
%for nchan=[6:9 15 27 28 42:46 49:57 81 110:113]
for nchan = [1:length(chanlocs)]
count_cohend = 0;
%for idx_condition = 1:length(ALLEEG)
for idx_condition = [1:52]
t = ALLEEG(idx_condition).times;
    
%% Baseline correction / Normalization
disp(['Baseline correction ...']);
%%% get signal times (pnts in second)
signal_times = transpose(t);
        
%%% get signal data
signal = ALLEEG(idx_condition).data(nchan,:,:);
signal = double(squeeze(signal));   
        
%%% find onset timepoint
onset_pnts = find(signal_times==0);
srate = ALLEEG.srate;
        
%%% get baseline per trial
signal_baseline = signal(1:onset_pnts-1,:);
        
%%% get mean baseline across pnts
signal_baseline_mean_pnts = nanmean(signal_baseline,1); 
%%% zscore to the baseline of each trial
signal_baseline_mean = repmat(nanmean(signal_baseline, 1), size(signal,1), 1);
signal_baseline_std = repmat(nanstd(signal_baseline, 1), size(signal,1), 1);
%signal_zscore(idx_condition,:,:) = ( signal - signal_baseline_mean ) ./ signal_baseline_std;
%signal_absrel(idx_condition,:,:) = ( signal - signal_baseline_mean ) ./ signal_baseline_mean;
%ALLEEG(idx_condition).data_abs(nchan,:,:) = signal;
ALLEEG(idx_condition).data_zscore(nchan,:,:) = ( signal - signal_baseline_mean ) ./ signal_baseline_std;
%ALLEEG(idx_condition).data_absrel(nchan,:,:) = ( signal - signal_baseline_mean ) ./ signal_baseline_mean;
disp(['Baseline correction ... Done']);
disp('');
%% responsiveness
%%% get signal data (abs or zscore or absrel)
Signal = ALLEEG(idx_condition).data_zscore(nchan,:,:);
Signal = double(squeeze(Signal)); 
%%% get baseline per trial
Signal_baseline = Signal(1:onset_pnts-1,:);
%%% get mean baseline across pnts
Signal_baseline_mean = repmat(nanmean(Signal_baseline, 1), size(Signal,1), 1);
Signal_baseline_mean_pnts = nanmean(Signal_baseline,1); 
%% responsiveness cohen's d
disp(['responsiveness (examplar)...']);
%%% === resp_pairedt: num_consecutive_pnts,  time_consecutive_pnts===
num_consecutive_pnts = 10;
srate = ALLEEG.srate;
time_consecutive_pnts = num_consecutive_pnts*1000*1/srate; %(in milisec)
%%% ===============
resp_cohend = zeros( size(signal_times,1), 1);
resp_cohend(1:onset_pnts, 1) = nan;
%response_start_pnts = onset_pnts + round(512/10);
response_start_pnts = onset_pnts;
response_end_pnts = onset_pnts + round(512/2)+ round(512/10);
%for npnts = onset_pnts:size(signal_times,1) % from onset_pnts to size(signal_times,1) (i.e. the index of the epoch end pnts)
 for npnts = response_start_pnts:response_end_pnts
    Signal_response_pnts = Signal(npnts,:);
    
        resp_stats_cohen_d(npnts,1) = computeCohen_d(Signal_baseline_mean_pnts, Signal_response_pnts, 'paired');
    
    
    if resp_stats_cohen_d (npnts,1) < -0.5 
        resp_cohend(npnts,1) = 1;
    end
       
end
resp_cohend_consec = find_consecutive_binary_sequences(resp_cohend, num_consecutive_pnts);
ALLEEG(idx_condition).resp_cohend_consec = size(resp_cohend_consec,1);
%(nchan,:)
if ALLEEG(idx_condition).resp_cohend_consec > 0
    count_cohend = count_cohend + 1;
end
disp(['responsiveness (examplar)... Done']);
disp('');
end
ALLEEG(1).chanlocs(nchan).cohend = count_cohend;
if count_cohend >= 5
    resp_contacts = [resp_contacts, nchan];
end
end
resp_contacts = resp_contacts';
disp('The number of responsive contacts: '); % Fixed a small typo here ("cantacts" -> "contacts")
disp(length(resp_contacts)-1);