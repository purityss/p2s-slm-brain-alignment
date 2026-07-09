import torch
from io import BytesIO
import librosa
from transformers import Qwen2AudioForConditionalGeneration, AutoProcessor
import os
import warnings
import re
import csv
import random
from jiwer import wer, cer
from scipy import io
from collections import defaultdict
import numpy as np

warnings.filterwarnings("ignore")

# === Set Device ===
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# === Load Model ===
model_path = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/qwen2_audio/qwen2-Audio-7B"
print("Step 1: Loading model...")
processor = AutoProcessor.from_pretrained(model_path)
model = Qwen2AudioForConditionalGeneration.from_pretrained(model_path, device_map="cuda:0").to(device)
print("Model loaded successfully.")

# Update save folder for English test results
save_folder = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/qwen2_audio_English/lesion_rank_results"
os.makedirs(save_folder, exist_ok=True)

# =========================
# 1) Lesion hook related
# =========================
hook_handles = []

def make_hook(n_idx, l_idx, mode):
    def hook(module, input, output):
        try:
            if mode == "cnn" and output.ndim == 3 and output.shape[1] > n_idx:
                output[:, n_idx, :] = 0
            elif mode == "transformer":
                if isinstance(output, (tuple, list)):
                    hidden = output[0]
                    return_as_tuple = isinstance(output, tuple)
                else:
                    hidden = output
                    return_as_tuple = False
                if isinstance(hidden, torch.Tensor):
                    if hidden.ndim == 3 and hidden.shape[-1] > n_idx:
                        hidden[:, :, n_idx] = 0
                    elif hidden.ndim == 2 and hidden.shape[-1] > n_idx:
                        hidden[:, n_idx] = 0
                return (hidden,) + tuple(output[1:]) if return_as_tuple else hidden
        except Exception as e:
            print(f"❌ Hook error at layer {l_idx}, neuron {n_idx}: {e}")
        return output
    return hook

def register_qwen_audio_lesion_hooks(model, lesion_targets):
    count = 0
    layer_map = defaultdict(list)
    for layer_idx, neuron_idx in lesion_targets:
        if layer_idx == 0:
            module = model.audio_tower.conv1
            mode = "cnn"
        elif layer_idx == 1:
            module = model.audio_tower.conv2
            mode = "cnn"
        elif 2 <= layer_idx <= 33:
            module = model.audio_tower.layers[layer_idx - 2]
            mode = "transformer"
        elif 34 <= layer_idx <= 65:
            module = model.language_model.model.layers[layer_idx - 34]
            mode = "transformer"
        else:
            print(f"⚠️ Invalid layer index: {layer_idx}, skipping")
            continue
            
        handle = module.register_forward_hook(make_hook(neuron_idx, layer_idx, mode))
        hook_handles.append(handle)
        count += 1
        layer_map[layer_idx].append(neuron_idx)
        
    print(f"\n✅ Successfully registered {count} lesion neuron hooks")
    return count

# =========================
# 2) English text cleaning
# =========================
def normalize_en(text: str) -> str:
    """
    Common English ASR normalization:
    - lowercase
    - Keep only a-z, spaces, and apostrophes
    - Compress multiple spaces into a single space
    """
    text = text.lower()
    text = re.sub(r"[^a-z'\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text

# =========================
# 3) Read LibriSpeech test-clean
# =========================
def build_librispeech_manifest(root_dir: str):
    items = []
    trans_files = []

    for dirpath, _, filenames in os.walk(root_dir):
        for fn in filenames:
            if fn.endswith(".trans.txt"):
                trans_files.append(os.path.join(dirpath, fn))

    if len(trans_files) == 0:
        raise FileNotFoundError(f"No .trans.txt files found in directory: {root_dir}")

    for trans_path in trans_files:
        with open(trans_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                parts = line.split(" ", 1)
                if len(parts) != 2:
                    continue
                utt_id, ref = parts[0].strip(), parts[1].strip()

                audio_path = os.path.join(os.path.dirname(trans_path), f"{utt_id}.flac")
                if not os.path.exists(audio_path):
                    continue

                items.append((utt_id, audio_path, normalize_en(ref)))

    if len(items) == 0:
        raise RuntimeError("Parsed .trans.txt files, but found no matching .flac + transcription pairs. Check directory structure.")

    return items

librispeech_root = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/qwen_audio_English/LibriSpeech/test-clean"
manifest = build_librispeech_manifest(librispeech_root)
manifest = sorted(manifest, key=lambda x: x[0])
print(f"✅ LibriSpeech manifest loaded: {len(manifest)} utterances")

# =========================
# 4) Load lesion sorted neurons (pho_only)
# === Read neuron data from .mat file and sort by significance value ===
mat = io.loadmat("qwen2_audio_start_pho_only_neurons.mat")
neuron_data = mat["start_pho_only_neurons"]

# Sort by significance value in row[3]
valid_neurons = [(int(row[0]) - 1, int(row[1]) - 1, float(row[3]))
                 for row in neuron_data
                 if 0 <= int(row[0]) - 1 <= 65 and int(row[1]) - 1 >= 0]

sorted_neurons = sorted(valid_neurons, key=lambda x: -x[2])
total_neurons = 4071

# =========================
# 5) Main Loop
# =========================
results = []
step = 500
prompt = "<|audio_bos|><|AUDIO|><|audio_eos|>Transcribe the speech in the audio:"

for top_n in list(range(0, 5000, step)):
    top_n = min(top_n, total_neurons)  # Avoid out of bounds
    selected = [(layer, neuron) for layer, neuron, _ in sorted_neurons[:top_n]]

    # Clear old hooks
    for h in hook_handles:
        h.remove()
    hook_handles.clear()

    lesion_count = register_qwen_audio_lesion_hooks(model, selected)

    total_wer = 0.0
    total_cer = 0.0
    num_samples = 0

    for utt_id, audio_path, ref_text in manifest:
        audio, sr = librosa.load(audio_path, sr=processor.feature_extractor.sampling_rate)

        inputs = processor(text=prompt, audios=audio, sampling_rate=16000, return_tensors="pt", padding=True)
        inputs = {k: v.to(device) for k, v in inputs.items()}

        generated_ids = model.generate(**inputs, max_new_tokens=256)
        generated_ids = generated_ids[:, inputs["input_ids"].size(1):]
        
        predicted_text = processor.batch_decode(generated_ids, skip_special_tokens=True, clean_up_tokenization_spaces=False)[0]
        hyp_text = normalize_en(predicted_text)

        # WER / CER calculation
        sample_wer = min(wer(ref_text, hyp_text), 1.0)
        
        ref_c = ref_text.replace(" ", "")
        hyp_c = hyp_text.replace(" ", "")
        sample_cer = min(cer(ref_c, hyp_c), 1.0) if len(ref_c) > 0 else 0.0

        total_wer += sample_wer
        total_cer += sample_cer
        num_samples += 1

        if num_samples <= 3:
            print(f"[{utt_id}] REF: {ref_text}")
            print(f"[{utt_id}] HYP: {hyp_text}")
            print(f"WER={sample_wer:.4f}, CER={sample_cer:.4f}\n")

    avg_wer = total_wer / num_samples if num_samples > 0 else -1
    avg_cer = total_cer / num_samples if num_samples > 0 else -1

    results.append([top_n, lesion_count, avg_wer, avg_cer])
    print(f"Top {top_n} neurons → Lesioned {lesion_count}, WER: {avg_wer:.6f}, CER: {avg_cer:.6f}")

results_array = np.array(results)

# Save as phoneme-specific English test result filename
save_path = os.path.join(save_folder, "qwen2_audio_lesion_rank_results_librispeech_testclean_pho.mat")
io.savemat(save_path, {"lesion_results": results_array})
print(f"\n✅ All results have been saved to {save_path}")