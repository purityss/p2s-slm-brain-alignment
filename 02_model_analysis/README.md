# Speech–language model analysis

This directory provides representative code for model activation/RDM analysis, speech-recognition evaluation, targeted lesions and activation steering. Detailed Qwen2-Audio and Qwen-Audio examples are provided; analyses for the other SLMs follow analogous procedures and can be adapted from these examples.

The manuscript evaluates 12 open-source models: XLSR-53-ch, Whisper-large-v3, LLaSM, SALMONN, Qwen-Audio, Qwen-Audio-Chat, Qwen2-Audio, Qwen2-Audio-Instruct, GLM-4-Voice, Freeze-Omni, MiniCPM-o 2.6 and Qwen2.5-Omni. They span approximately 318M–9B parameters and 31–66 indexed layers/stages. The code in this directory illustrates the common analysis workflow using Qwen2-Audio and Qwen-Audio.

## Contents and execution order

### `Qwen2_Audio/01_representation_analysis`

1. `step1_activations_qwen2_audio.py` and `step1_activations_qwen2_audio_English.py` register hooks and extract layer/unit activations for the Chinese and English 52-word stimuli.
2. `step2_hebing_qwen2_audio.m` combines activation files.
3. `step3_qwen2_audio_Cosine_distance_RDM_layer66_neuron.m` constructs unit-wise cosine-distance RDMs across 66 indexed stages/layers.
4. `Step4_find_selec_layer_neuron_token_label.m` identifies unit labels from phonological and semantic RDM relationships.
5. `Step5_find_selec_layer_neuron_token_t.m` derives time/token-resolved statistics.
6. `all_layers_selective_neuron_token_t_label/` contains the subsequent scripts and intermediate `.mat` files used to identify onset positions, classify phonological, semantic and shared units, plot sequence dynamics, count units by layer, and export shared-unit indices.

Scripts use one-based MATLAB indices and convert to zero-based Python hook indices where needed. Preserve that convention when adapting the code.

For convolutional modules, channels are treated as neurons; for transformer encoders/decoders, hidden dimensions are neurons. Prompt positions before the first generated response token are excluded. Each speech-evoked time/token sequence is bisected into two contiguous segments, and a 52 × 52 cosine-distance RDM is computed per neuron and segment without additional normalization beyond native model scaling.

### `Qwen2_Audio/02_performance_evaluation`

- `aishell1_test_qwen2_audio.py`: evaluates Mandarin ASR on AISHELL-1.
- `fleurs_zh_test_qwen2_audio.py`: evaluates Mandarin ASR on the FLEURS Chinese test split.

Both scripts use a fixed transcription prompt, normalize punctuation/spacing, and report mean WER and CER. The manuscript's performance measure is per-utterance recognition accuracy `1 − CER`, clipped to `[0,1]`, then averaged. Capping per-item CER at 1 is equivalent for this accuracy, but results should be converted consistently when populating the performance matrix.

### `Qwen2_Audio/03_targeted_lesion`

Six scripts lesion ranked phonological, semantic or shared units using forward hooks and evaluate either FLEURS Chinese or LibriSpeech `test-clean`. They write lesion curves to MATLAB files.

### `Qwen-Audio/04 activation_steering`

`clooseloop_activation_steering_qwen_audio.py` performs closed-loop activation steering of Qwen-Audio using selected shared units. The folder also includes the unit-index file and example transcription/summary outputs for steering strengths 0.0–0.8.

The steering analysis uses direction-consistent P2S units (phonology > semantics in segment 1 and semantics > phonology in segment 2), ranks them by the sum of those differences, selects the top 1,000, and intervenes in segment 2 along an edible-versus-inedible activation direction.

## Environment

Python is used for model inference, activation extraction, performance evaluation, lesion analysis and activation steering. Because the 12 models were released with different software stacks, no single Python version is prescribed for all analyses. For each model, use the Python, PyTorch, Transformers and CUDA versions recommended by its official model card or code repository. The corresponding analysis follows the public weight's recommended invocation environment.

The shared dependencies used by the example scripts are listed in [`requirements-python.txt`](../requirements-python.txt). After creating the model-specific environment, install or reconcile these packages from the repository root:

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements-python.txt
```

A CUDA-capable GPU is recommended for full 7B-model analyses. Select the PyTorch/CUDA build appropriate for the machine.

MATLAB is used for activation aggregation, RDM construction, unit classification, hierarchy/sequence analysis and plotting. The repository-wide MATLAB components are listed in [`requirements-matlab.txt`](../requirements-matlab.txt). The model-analysis MATLAB scripts use:

- MATLAB R2022b or newer
- Statistics and Machine Learning Toolbox

## Model weights

Download model weights from the official project or model-card pages below. Follow the installation and inference instructions on the linked page for the corresponding model analysis.

| Model | Official weights/project |
|---|---|
| XLSR-53-ch | [wav2vec2-large-xlsr-53-chinese-zh-cn](https://huggingface.co/jonatasgrosman/wav2vec2-large-xlsr-53-chinese-zh-cn) |
| Whisper-large-v3 | [openai/whisper-large-v3](https://huggingface.co/openai/whisper-large-v3) |
| LLaSM | [LinkSoul/LLaSM-Cllama2](https://huggingface.co/LinkSoul/LLaSM-Cllama2) · [official code](https://github.com/LinkSoul-AI/LLaSM) |
| SALMONN | [tsinghua-ee/SALMONN](https://huggingface.co/tsinghua-ee/SALMONN) · [official code](https://github.com/bytedance/SALMONN) |
| Qwen-Audio | [Qwen/Qwen-Audio](https://huggingface.co/Qwen/Qwen-Audio) |
| Qwen-Audio-Chat | [Qwen/Qwen-Audio-Chat](https://huggingface.co/Qwen/Qwen-Audio-Chat) |
| Qwen2-Audio | [Qwen/Qwen2-Audio-7B](https://huggingface.co/Qwen/Qwen2-Audio-7B) |
| Qwen2-Audio-Instruct | [Qwen/Qwen2-Audio-7B-Instruct](https://huggingface.co/Qwen/Qwen2-Audio-7B-Instruct) |
| GLM-4-Voice | [zai-org/glm-4-voice-9b](https://huggingface.co/zai-org/glm-4-voice-9b) · [official code](https://github.com/zai-org/GLM-4-Voice) |
| Freeze-Omni | [VITA-MLLM/Freeze-Omni](https://huggingface.co/VITA-MLLM/Freeze-Omni) · [official code](https://github.com/VITA-MLLM/Freeze-Omni) |
| MiniCPM-o 2.6 | [openbmb/MiniCPM-o-2_6](https://huggingface.co/openbmb/MiniCPM-o-2_6) |
| Qwen2.5-Omni | [Qwen/Qwen2.5-Omni-7B](https://huggingface.co/Qwen/Qwen2.5-Omni-7B) · [official code](https://github.com/QwenLM/Qwen2.5-Omni) |

Model weights retain their original licenses and are not redistributed by this repository.

## Public evaluation datasets

- [AISHELL-1 / OpenSLR SLR33](https://www.openslr.org/33/)
- [Google FLEURS](https://huggingface.co/datasets/google/fleurs), configuration `cmn_hans_cn`, test split
- [LibriSpeech / OpenSLR SLR12](https://www.openslr.org/12/), `test-clean`

Download these resources separately and comply with their respective licenses. The code currently points to local copies rather than downloading datasets automatically.

## Configuration before running

Edit `model_path`, stimulus/dataset paths, transcript paths, output paths, device selection, and selected-unit `.mat` paths near the top of each script for the local environment.

The main configurable settings are:

- whether the checkpoint is the base or instruct/chat variant;
- the expected 66-stage mapping (two convolutional stages, 32 audio-tower layers and 32 language-model layers in the example lesion code);
- the activation tensor/token selected at each hook;
- the prompt template and sampling/generation parameters;
- dataset manifest schema and filename matching;
- the total-unit counts used by the lesion scripts;
- random seeds, deterministic settings, batch size and GPU memory.
