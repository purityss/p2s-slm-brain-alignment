import torch
from transformers import Qwen2AudioForConditionalGeneration, AutoProcessor
import os
import warnings
from scipy import io
import numpy as np
from io import BytesIO
import librosa
import re

warnings.filterwarnings("ignore")

# ========== Path Settings ==========
model_path = "/home/user/model_activate/qwen_audio/qwen2-Audio-7B"
audio_folder = "/home/user/model_activate/WordVocoder(160916)"
save_path = "/home/user/model_activate/qwen_audio/qwen2_audio_activation"
output_txt_path = os.path.join(save_path, "transcriptions_qwen2_audio.txt")
os.makedirs(save_path, exist_ok=True)

# ========== Model and Processor Loading ==========
print("Loading model...")
processor = AutoProcessor.from_pretrained(model_path)
model = Qwen2AudioForConditionalGeneration.from_pretrained(model_path, device_map="auto").eval()
print("Model loaded successfully.")

# ========== Register Hooks ==========
activations = {}

def get_activation(name):
    def hook(module, input, output):
        if isinstance(output, (tuple, list)):
            output = output[0]
        if isinstance(output, torch.Tensor):
            activations.setdefault(name, []).append(output.detach().cpu())
    return hook

# Register CNN layers
if hasattr(model.audio_tower, "conv1"):
    model.audio_tower.conv1.register_forward_hook(get_activation("audio_conv1"))
if hasattr(model.audio_tower, "conv2"):
    model.audio_tower.conv2.register_forward_hook(get_activation("audio_conv2"))

# Register Transformer layers
if hasattr(model.audio_tower, "layers"):
    for i, layer in enumerate(model.audio_tower.layers):
        layer.register_forward_hook(get_activation(f"audio_block_{i}"))

# Register language model Transformer layers
if hasattr(model.language_model.model, "layers"):
    for i, layer in enumerate(model.language_model.model.layers):
        layer.register_forward_hook(get_activation(f"lm_block_{i}"))

# ========== Audio File List ==========
#audio_files = ["caomei.wav", "daiyu.wav"]
#'''
audio_files = [
    "caomei.wav", "daiyu.wav", "dangao.wav", "doufu.wav", "haidai.wav", "hongshu.wav", "jidan.wav", "jianbing.wav", "lizhi.wav",
    "longxia.wav", "luobo.wav", "lvdou.wav", "mangguo.wav", "miji.wav", "mianbao.wav", "mogu.wav", "niurou.wav", "pingguo.wav",
    "ruantang.wav", "shutiao.wav", "xigua.wav", "xiangchang.wav", "yangcong.wav", "yingtao.wav", "yumi.wav", "zhuti.wav", "caoping.wav",
    "daibiao.wav", "dangong.wav", "douhao.wav", "haitan.wav", "hongdeng.wav", "jihui.wav", "jianbang.wav", "liliang.wav", "longzi.wav",
    "luoxuan.wav", "lvshi.wav", "mangren.wav", "mima.wav", "mianju.wav", "mote.wav", "niuzai.wav", "pingwei.wav", "ruanjian.wav",
    "shujia.wav", "xigai.wav", "xiangcun.wav", "yangguang.wav", "yingxiong.wav", "yushi.wav", "zhubao.wav"
]
#'''

# ========== Main Processing Loop ==========
prompt = "<|audio_bos|><|AUDIO|><|audio_eos|>Transcribe the speech in the audio:"

for idx, audio_file in enumerate(audio_files, start=1):
    audio_path = os.path.join(audio_folder, audio_file)
    print(f"\n[{idx}] Processing: {audio_file}")

    # Load audio
    audio, sr = librosa.load(audio_path, sr=processor.feature_extractor.sampling_rate)

    # Preprocess inputs
    inputs = processor(text=prompt, audios=audio, return_tensors="pt", padding=True)
    inputs = inputs.to(model.device)

    prompt_len = inputs["input_ids"].shape[1]  # ✅ Record prompt length

    # Clear activations
    activations.clear()

    # Generate text
    with torch.no_grad():
        generated_ids = model.generate(**inputs, max_length=256, use_cache=False)
        generated_ids = generated_ids[:, inputs["input_ids"].size(1):]
        response = processor.batch_decode(generated_ids, skip_special_tokens=True, clean_up_tokenization_spaces=False)[0]

    print("Transcript:", response)
    with open(output_txt_path, "a", encoding="utf-8") as f:
        f.write(f"{audio_file}: {response}\n")

    # ========== Save CNN and Transformer Activations ==========
    layer_num = 0
    print("\n=== Saving activations from CNN/Transformer layers ===")

    for name, layer_outputs in activations.items():
        layer_num += 1

        for step_idx, activation in enumerate(layer_outputs):
            if not isinstance(activation, torch.Tensor):
                continue

            activation = activation.squeeze(0)  # Remove batch dimension

            # Save CNN and audio block parts directly
            if "audio_conv" in name or "audio_block" in name:
                mat_filename = f"{save_path}/input_{idx}_layer_{layer_num}_activation_qwen2_audio.mat"
                io.savemat(mat_filename, {"activation": activation.numpy()})
                print(f"✅ Saved {name} step {step_idx} → {activation.shape} → {mat_filename}")

            # For LM parts, crop out prompt + audio tokens
            elif "lm_block" in name:
                if activation.shape[0] <= prompt_len:
                    print(f"⛔ {name} step {step_idx} only contains prompt, skipping")
                    continue

                activation = activation[prompt_len:, :]  # ✅ Remove prompt

                if activation.shape[0] == 0:
                    print(f"⛔ {name} step {step_idx} remaining generated tokens=0, skipping")
                    continue

                mat_filename = f"{save_path}/input_{idx}_layer_{layer_num}_activation_qwen2_audio.mat"
                io.savemat(mat_filename, {"activation": activation.numpy()})
                print(f"✅ Saved {name} step {step_idx} (after cropping) → {activation.shape} → {mat_filename}")

            else:
                continue  # Skip other cases

print("\n🎯 All done!")