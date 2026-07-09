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

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# model_path = "/home/user/model_activate/qwen_audio/qwen2-Audio-7B"
model_path = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/qwen2_audio/qwen2-Audio-7B"
print("Step 1: Loading model...")
processor = AutoProcessor.from_pretrained(model_path)
model = Qwen2AudioForConditionalGeneration.from_pretrained(model_path, device_map="cuda:0").to(device)
print("Model loaded successfully.")

save_folder = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/qwen2_audio/lesion_rank_results"
os.makedirs(save_folder, exist_ok=True)

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
    print("📊 Lesion neuron distribution across layers:")
    for l in sorted(layer_map):
        print(f"  - Layer {l}: {len(layer_map[l])} → {layer_map[l]}")
    return count

def clean_text(text):
    text = re.sub(r"\s+", "", text)
    text = re.sub(r"[^\w\u4e00-\u9fff]", "", text)
    return text.strip()

def extract_transcription(text):
    match = re.search(r"['\"](.*)['\"]", text)
    if match:
        text = match.group(1)
    return re.sub(r"[^\w\u4e00-\u9fff]", "", text)

prompt = "<|audio_bos|><|AUDIO|><|audio_eos|>Transcribe the speech in the audio:"
# audio_dir = "/home/user/model_activate/model_performance/Fleurs-zh/test"
# tsv_file = "/home/user/model_activate/model_performance/Fleurs-zh/data2Ftest.tsv"
audio_dir = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/fleurs/cmn_hans_cn/wav/test"
tsv_file = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/fleurs/cmn_hans_cn/data2Ftest.tsv"

transcriptions = {}
with open(tsv_file, "r", encoding="utf-8") as f:
    reader = csv.reader(f, delimiter="\t")
    for row in reader:
        if len(row) >= 3:
            transcriptions[row[1]] = row[2].strip()
print(f"Loaded {len(transcriptions)} transcriptions")

# === Read neuron data from .mat file and sort by significance value ===
mat = io.loadmat("qwen2_audio_start_pho_only_neurons.mat")
neuron_data = mat["start_pho_only_neurons"]

valid_neurons = [(int(row[0]) - 1, int(row[1]) - 1, float(row[3]))
                 for row in neuron_data
                 if 0 <= int(row[0]) - 1 <= 65 and int(row[1]) - 1 >= 0]

sorted_neurons = sorted(valid_neurons, key=lambda x: -x[2])

# Convert to NumPy array format and save
# sorted_array = np.array(sorted_neurons)
# save_path = os.path.join(save_folder, "sorted_start_pho_neurons.mat")
# io.savemat(save_path,  {"sorted_neurons": sorted_array})
# print("✅ Sorted neuron information has been saved as sorted_start_pho_neurons.mat")

results = []
# total_neurons = len(sorted_neurons)
total_neurons = 1767

# Modify here: from top 0, 100, 200... up to a maximum of 1767
step = 100
for top_n in list(range(0, 1900, step)):
    top_n = min(top_n, total_neurons)  # Avoid out of bounds
    selected = [(layer, neuron) for layer, neuron, _ in sorted_neurons[:top_n]]

    for h in hook_handles:
        h.remove()
    hook_handles.clear()

    lesion_count = register_qwen_audio_lesion_hooks(model, selected)

    total_wer = 0
    total_cer = 0
    num_samples = 0

    for audio_file in os.listdir(audio_dir):
        if not audio_file.endswith(".wav") or audio_file not in transcriptions:
            continue

        audio_path = os.path.join(audio_dir, audio_file)
        audio, sr = librosa.load(audio_path, sr=processor.feature_extractor.sampling_rate)

        inputs = processor(text=prompt, audios=audio, sampling_rate=16000, return_tensors="pt", padding=True)
        inputs = {k: v.to("cuda") for k, v in inputs.items()}

        generated_ids = model.generate(**inputs, max_new_tokens=256)
        generated_ids = generated_ids[:, inputs["input_ids"].size(1):]
        predicted_text = processor.batch_decode(generated_ids, skip_special_tokens=True, clean_up_tokenization_spaces=False)[0]

        actual_text = clean_text(transcriptions[audio_file])
        extracted_predicted_text = extract_transcription(predicted_text)

        #if len(extracted_predicted_text) > len(actual_text):
        #    extracted_predicted_text = extracted_predicted_text[:len(actual_text)]

        sample_wer = min(wer(actual_text, extracted_predicted_text), 1.0)
        sample_cer = min(cer(actual_text, extracted_predicted_text), 1.0)

        total_wer += sample_wer
        total_cer += sample_cer
        num_samples += 1

        print(f"Lesion Top: {top_n} neurons")
        print(f"Saved transcription: {audio_file}")
        print(f"Ground truth: {actual_text}")
        print(f"Predicted: {extracted_predicted_text}")
        print(f"Full: {predicted_text}")
        print(f"Current WER: {sample_wer:.6f}")
        print(f"Current CER: {sample_cer:.6f}\n")

    avg_wer = total_wer / num_samples if num_samples > 0 else -1
    avg_cer = total_cer / num_samples if num_samples > 0 else -1

    results.append([top_n, lesion_count, avg_wer, avg_cer])
    print(f"Top {top_n} neurons → Lesioned {lesion_count}, WER: {avg_wer:.6f}, CER: {avg_cer:.6f}")

results_array = np.array(results)

save_path = os.path.join(save_folder, "qwen2_audio_lesion_rank_results_pho_num.mat")
io.savemat(save_path, {"lesion_results": results_array})
print(f"\n✅ All results have been saved to {save_path}")