# Phonology-to-Semantics (P2S) Alignment in Human Brain and Speech–Language Models

This repository accompanies the manuscript **“Human-like sequential sound-to-meaning transfer drives artificial speech comprehension”** by Zhang et al. The study compares how spoken-word representations progress from phonology to semantics in sEEG recordings from 17 participants and in 12 speech–language models (SLMs), then tests the proposed mechanism using model lesions and activation steering.

Figure-level processed data are included. Raw sEEG recordings contain sensitive clinical information and may be requested from the corresponding authors after publication, subject to ethical and institutional approval. Model weights and public benchmark corpora can be downloaded from their official sources.

## Repository structure

| Directory | Contents |
|---|---|
| [`00_speech_stimuli`](00_speech_stimuli/) | 52 Mandarin Chinese and 52 English spoken-word WAV files |
| [`01_brain_analysis`](01_brain_analysis/) | Subject-level sEEG preprocessing, responsive-contact identification and decoding/RDM construction; group-level unit classification, hierarchy and temporal-sequence analyses |
| [`02_model_analysis`](02_model_analysis/) | Representative model activation, RDM, evaluation, targeted-lesion and activation-steering analyses; the examples can be adapted to other SLMs |
| [`03_brain_model_alignment`](03_brain_model_alignment/) | Model-performance summaries and hierarchical/sequential brain–model alignment analyses |
| [`04_plotting`](04_plotting/) | Processed data and MATLAB scripts for the five main figures and ten extended-data figure sets |

## Analysis overview

1. Present 52 Mandarin disyllabic words to 17 participants and record sEEG.
2. Preprocess each participant, identify speech-responsive contacts, and construct time-resolved neural RDMs using pairwise decoding.
3. Use one-sided two-sample t-tests on phonologically/semantically similar versus different RDM entries and classify contacts or model units as phonological, semantic, or shared/P2S-transfer units.
4. quantify the distribution of these units across cortical/model hierarchies and their temporal/token sequence.
5. Evaluate SLM speech-recognition performance and perform targeted lesion and activation-steering analyses.
6. Compare model hierarchy and sequence indices with the corresponding human-brain indices.

See the README in each directory for inputs, outputs, and execution order.

## Software

The analysis uses the following software environment and dependencies:

- MATLAB R2022b or newer
- EEGLAB (with the BIOSIG plugin)
- MATLAB Signal Processing Toolbox
- MATLAB Wavelet Toolbox
- MATLAB Statistics and Machine Learning Toolbox
- LIBSVM MATLAB interface (`svmtrain` and `svmpredict`)
- SPM12, Brainstorm, FreeSurfer 6.0 and the USC Brain atlas for electrode localization
- Python version recommended by each model's official weight repository
- CUDA-capable PyTorch installation for the 7B-parameter models
- `torch`, `transformers`, `librosa`, `numpy`, `scipy`, `pandas`, `openpyxl`, and `jiwer`

See [`02_model_analysis/README.md`](02_model_analysis/) for Python setup guidance.

Repository-wide dependency lists are provided in [`requirements-python.txt`](requirements-python.txt) and [`requirements-matlab.txt`](requirements-matlab.txt). Model-specific Python, PyTorch, Transformers and CUDA versions should follow each official model-weight repository.

## Quick start

Clone the repository and start MATLAB from its root:

```matlab
repo = '/path/to/p2s-slm-brain-alignment';
cd(repo);
addpath(genpath(repo));
```

Figure scripts are the quickest reproducibility entry point because their processed `.mat`/`.xlsx` inputs are included:

```matlab
cd(fullfile(repo, '04_plotting', 'Main Figures', 'Fig2', 'c'));
run('plot_bar_model_units.m');
```

For subject-level sEEG or model analyses, edit the path variables near the beginning of each script to point to the corresponding local data, model weights, and output directories.

## External resources

- Qwen2-Audio weights: [Qwen2-Audio model collection](https://huggingface.co/collections/Qwen/qwen2-audio)
- AISHELL-1: [OpenSLR SLR33](https://www.openslr.org/33/)
- FLEURS: [Google FLEURS on Hugging Face](https://huggingface.co/datasets/google/fleurs)
- LibriSpeech: [OpenSLR SLR12](https://www.openslr.org/12/)

Users are responsible for complying with the licenses and terms of the models and datasets they download.

## Data availability and privacy

- The repository provides the speech stimuli and anonymized/aggregate intermediate results used by the analysis.
- Raw sEEG data are controlled-access data and are **not** included.

## License

Source code in this repository (`.m` and `.py` files) is licensed under the [MIT License](LICENSE).

The speech stimuli, processed data, and documentation created by the authors are licensed under the [Creative Commons Attribution 4.0 International License](LICENSE-DATA), unless otherwise stated.

Raw sEEG recordings are not covered by these licenses and remain subject to controlled-access requirements. Model weights and external datasets are governed by their respective original licenses.

## Citation

Zhang, S., Li, S., Yang, R., Chen, G., Tian, X., Wang, Q. & Fang, F. *Human-like sequential sound-to-meaning transfer drives artificial speech comprehension*. bioRxiv (2026). [https://doi.org/10.64898/2026.05.13.723203](https://www.biorxiv.org/content/10.64898/2026.05.13.723203v1)

Correspondence: Xing Tian (`xing.tian@nyu.edu`), Qian Wang (`wangqianpsy@pku.edu.cn`), or Fang Fang (`ffang@pku.edu.cn`).
