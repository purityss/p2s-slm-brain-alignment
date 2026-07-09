# Human sEEG analysis

This directory contains the example participant-level pipeline and the anonymized intermediate data and scripts used for group analyses. Raw clinical sEEG recordings are excluded because of participant privacy.

The manuscript reports 17 right-handed native-Mandarin-speaking patients with drug-resistant epilepsy (9 male, ages 13–42), yielding 1,909 contacts, of which 962 were speech responsive. Recordings were acquired at 512 Hz with a Nicolet video-EEG system, forehead reference/ground, no online filtering, and impedances below 50 kΩ. Reported class counts are 210 phonological, 218 semantic and 43 shared/P2S-transfer contacts.

## Contents

### `01_process_sEEG_pipeline_each_sub`

Run the scripts in numerical order after adapting paths and participant-specific settings:

1. `step1_datacook_52word.m`
   - Loads four EDF recording blocks with EEGLAB/BIOSIG.
   - Concatenates the blocks, detects trigger edges, rejects closely spaced false triggers, filters, takes a Hilbert envelope, inserts the 52 condition labels from `logfile_newword`, and epochs from −0.2 to 1.2 s.
   - Inputs: four EDF recording blocks and the experimental log file.
   - Output used downstream: the participant-level `ALLEEG` structure.

2. `step2_identify_speech_responsive_contacts.m`
   - Baseline-z-scores each trial and identifies contacts using a sustained Cohen's-d criterion for at least 10 samples in at least five conditions.
   - Uses `find_consecutive_binary_sequences.m`.
   - Inputs: participant `ALLEEG` data and channel locations.
   - Output used downstream: `resp_contacts`.

3. `step3_decoding_to_construct_brain_rdms.m`
   - Computes time–frequency features with a continuous wavelet transform, using 60–150 Hz power by default.
   - Uses sliding 200-ms windows with a 50-ms step for sequence-resolved analysis.
   - Performs pairwise 52-condition LIBSVM decoding with repeated four-fold cross-validation and constructs time-resolved 52 × 52 RDMs.
   - Required inputs: participant `ALLEEG` and `resp_contacts` files.
   - Outputs per-contact feature and RDM `.mat` files to `save_path`.

### `02_group_analysis`

The supplied `.mat` files are anonymized aggregate/intermediate data for speech-responsive contacts and the three functional classes:

- phonology-only contacts;
- semantics-only contacts;
- shared/P2S-transfer contacts (phonological and semantic statistics are stored separately).

The numbered scripts:

1. classify responsive contacts using correlations between neural RDMs and phonological/semantic reference RDMs;
2. estimate the first significant time for each contact;
3. count contacts by class and anatomical grouping;
4. plot the cortical hierarchy distribution;
5–6. collect time-resolved statistics overall and for the three classes;
7. plot temporal heat maps/summary lines.

The manuscript classifies representations with one-sided two-sample t-tests (`P < 0.05`) contrasting different versus similar RDM entries. A unit is phonological-only or semantic-only when at least one window is significant for that dimension and none is significant for the other; a shared unit has at least one significant window in each dimension.

## MATLAB requirements

Recommended: MATLAB R2022b or newer with:

- EEGLAB and the BIOSIG plugin (`pop_biosig`, `pop_chanevent`, `pop_eegfiltnew`, `pop_epoch`);
- Signal Processing Toolbox (`hilbert`);
- Wavelet Toolbox (`cwt`);
- Statistics and Machine Learning Toolbox;
- LIBSVM MATLAB interface (`svmtrain`, `svmpredict`).
