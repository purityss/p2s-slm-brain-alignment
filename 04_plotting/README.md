# Figure plotting

This directory contains processed MATLAB data and plotting scripts for the manuscript's five main figures and ten extended-data figure sets. It is the most self-contained entry point for reproducing visualizations without raw clinical recordings or model weights.

The manuscript reports 962 responsive contacts (210 phonological, 218 semantic and 43 shared/P2S-transfer), two 52 × 52 RDMs per model neuron, 16 neural time windows, and 12 evaluated models. These are useful numerical checks for tracing plotting inputs.

## Layout

- `Main Figures/Fig2`: numbers, temporal profiles and hierarchical distributions of phonological, semantic and shared/P2S-transfer units in human sEEG and example models.
- `Main Figures/Fig3`: model performance and brain–model hierarchical/sequential alignment.
- `Main Figures/Fig4`: targeted-lesion and activation-steering results.
- `Main Figures/Fig5`: human/model RDM visualization, phonology-versus-semantics distance and multidimensional scaling.
- `Extended/Fig1`: responsive-contact localization and example/average HGA responses.
- `Extended/Fig2`: unit counts by hemisphere/cortex.
- `Extended/Fig3`–`Fig4`: unit profiles across additional models.
- `Extended/Fig5`–`Fig6`: alignment, latency hierarchy and distance from posteromedial Heschl's gyrus.
- `Extended/Fig7`–`Fig9`: lesion analyses across models and English evaluation.
- `Extended/Fig10`: class-specific human/model RDM and MDS analyses.

Each panel folder is intentionally local: its script generally loads `.mat` or `.xlsx` files by filename from the current working directory. Change into the panel directory before running a script:

```matlab
cd('/path/to/repo/04_plotting/Main Figures/Fig5/b');
run('plot_rdm_model.m');
```

Some folders contain multiple scripts representing successive calculations, such as distance calculation, MDS and plotting. Run them in the order indicated by their names.

For MDS panels, Methods specify averaging RDMs within unit class and sequence position, two-dimensional `mdscale`, normalization to unit radius, and sequential Procrustes alignment without scaling. The clustering metric is mean distance for different pairs minus mean distance for similar pairs.

## Requirements

Recommended: MATLAB R2022b or newer with:

- Statistics and Machine Learning Toolbox (`mdscale`, correlations and statistical functions);
- spreadsheet support for `.xlsx` inputs;
- Arial font for matching the manuscript typography.

Most plots use only core MATLAB graphics. No Python environment is required for this directory.
