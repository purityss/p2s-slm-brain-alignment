# Brain–model alignment

This directory relates model performance to hierarchical and sequential correspondence with the human sEEG results.

## Data

`model_matrix.mat` contains the summary matrix used by all scripts. The scripts define 12 rows/models:

1. XLSR-53-ch
2. Whisper-large-v3
3. LLaSM
4. SALMONN
5. Qwen-Audio
6. Qwen-Audio-Chat
7. Qwen2-Audio
8. Qwen2-Audio-Instruct
9. GLM-4-Voice
10. Freeze-Omni
11. MiniCPM-o 2.6
12. Qwen2.5-Omni

The matrix columns are used as follows:

| Column | Meaning |
|---:|---|
| 1 | AISHELL-1 performance |
| 2 | FLEURS Chinese performance |
| 3 | phonological hierarchical alignment |
| 4 | shared/P2S-transfer hierarchical alignment |
| 5 | semantic hierarchical alignment |
| 6 | phonological sequential alignment |
| 7 | shared/P2S-transfer sequential alignment |
| 8 | semantic sequential alignment |

The manuscript defines performance as mean per-utterance `1 − CER`, after clipping each utterance to `[0,1]`. Columns 1–2 should therefore contain recognition accuracy in percent if the scripts retain their `0–100` axes.

## Scripts

- `step1_plot_model_performance_bar_fig3bde.m`: performance and alignment summary plots.
- `step2_comput_cor_fig3f.m`: correlation between column 1 performance and the selected alignment index (currently column 7).
- `step2_comput_cor_fig3g.m`: correlation between column 2 performance and the selected alignment index (currently column 7).
- `step3_plot_hierarchy_alignment_ed5.m`: correlations of both performance measures with the three hierarchy indices.
- `step3_plot_sequential_alignment_ed5.m`: correlations of both performance measures with the three sequence indices.

Run MATLAB from this directory so that `load('model_matrix.mat')` resolves correctly:

```matlab
cd('/path/to/repo/03_brain_model_alignment');
run('step1_plot_model_performance_bar_fig3bde.m');
```

Recommended: MATLAB R2022b or newer with the Statistics and Machine Learning Toolbox (`corr`, `tinv`). Figures use the Arial font.

## Alignment definitions

For hierarchy, proportions of all three unit types are min–max normalized using one shared range. Each model's layer sequence is linearly interpolated to the number of ordered brain areas; Pearson `r` between corresponding profiles is the class-specific hierarchical alignment index.

For sequence, phonological and semantic representation indices across all unit types/positions are min–max normalized using one shared range. The model's two-segment trajectories are linearly interpolated to the 16 brain windows. For each class, phonological and semantic trajectories are concatenated and Pearson-correlated between brain and model.
