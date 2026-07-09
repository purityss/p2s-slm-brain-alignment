# -*- coding: utf-8 -*-
import os
import re
import csv
import math
import warnings
from collections import defaultdict

import numpy as np
import torch
from scipy import io, stats
from scipy.spatial.distance import cosine
from transformers import AutoModelForCausalLM, AutoTokenizer

warnings.filterwarnings("ignore")

# =========================================================
# 0) Basic Configuration
# =========================================================
torch.manual_seed(1234)
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# ---- Qwen-Audio Path ----
MODEL_PATH = "/home/user/model_activate/qwen_audio/Qwen-audio"
AUDIO_FOLDER = "/home/user/model_activate/WordVocoder(160916)"

# ---- P2S indices (Ensure this mat file is tailored for Qwen-Audio) ----
P2S_INDEX_MAT = "qwen_audio_both_neuron_pho_sem_index.mat" 
P2S_INDEX_KEY = "both_neuron_pho_sem_index"               

# ---- Output path ----
OUT_DIR = "/home/user/model_activate/qwen_audio/qwen_audio_repe_eval_p2s"
os.makedirs(OUT_DIR, exist_ok=True)

# ---- RepE intervention parameters ----
# ALPHAS = [0.0, 0.5, 1.0, 1.5, 2.0] 
ALPHAS = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8] 
# TOP_K = 500
TOP_K = 1000
SPLIT_RATIO = 0.5
FIXED_SEG_LEN = 8
SAVE_PER_WORD_TRANS = True

# =========================================================
# 1) Load Qwen-Audio Model
# =========================================================
print("Step 1: Loading Qwen-Audio model...")
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH, device_map="cuda:0", trust_remote_code=True, 
    bf16=False, fp16=False, fp32=True
).eval()
print("Model loaded successfully.")

# =========================================================
# 2) 52-word dataset and label construction
# =========================================================
audio_files = [
    "caomei.wav", "daiyu.wav", "dangao.wav", "doufu.wav", "haidai.wav", "hongshu.wav",
    "jidan.wav", "jianbing.wav", "lizhi.wav", "longxia.wav", "luobo.wav", "lvdou.wav",
    "mangguo.wav", "miji.wav", "mianbao.wav", "mogu.wav", "niurou.wav", "pingguo.wav",
    "ruantang.wav", "shutiao.wav", "xigua.wav", "xiangchang.wav", "yangcong.wav",
    "yingtao.wav", "yumi.wav", "zhuti.wav", "caoping.wav", "daibiao.wav", "dangong.wav",
    "douhao.wav", "haitan.wav", "hongdeng.wav", "jihui.wav", "jianbang.wav", "liliang.wav",
    "longzi.wav", "luoxuan.wav", "lvshi.wav", "mangren.wav", "mima.wav", "mianju.wav",
    "mote.wav", "niuzai.wav", "pingwei.wav", "ruanjian.wav", "shujia.wav", "xigai.wav",
    "xiangcun.wav", "yangguang.wav", "yingxiong.wav", "yushi.wav", "zhubao.wav"
]

PINYIN2ZH = {
    "caomei": "草莓", "daiyu": "带鱼", "dangao": "蛋糕", "doufu": "豆腐", "haidai": "海带", "hongshu": "红薯",
    "jidan": "鸡蛋", "jianbing": "煎饼", "lizhi": "荔枝", "longxia": "龙虾", "luobo": "萝卜", "lvdou": "绿豆",
    "mangguo": "芒果", "miji": "蜜桔", "mianbao": "面包", "mogu": "蘑菇", "niurou": "牛肉", "pingguo": "苹果",
    "ruantang": "软糖", "shutiao": "薯条", "xigua": "西瓜", "xiangchang": "香肠", "yangcong": "洋葱",
    "yingtao": "樱桃", "yumi": "玉米", "zhuti": "猪蹄",
    "caoping": "草坪", "daibiao": "代表", "dangong": "弹弓", "douhao": "逗号", "haitan": "海滩", "hongdeng": "红灯",
    "jihui": "机会", "jianbang": "肩膀", "liliang": "力量", "longzi": "聋子", "luoxuan": "螺旋", "lvshi": "律师",
    "mangren": "盲人", "mima": "密码", "mianju": "面具", "mote": "模特", "niuzai": "牛仔", "pingwei": "评委",
    "ruanjian": "软件", "shujia": "暑假", "xigai": "膝盖", "xiangcun": "乡村", "yangguang": "阳光",
    "yingxiong": "英雄", "yushi": "浴室", "zhubao": "珠宝",
}

N_WORDS = len(audio_files)
semantic_label = np.array([0] * 26 + [1] * 26, dtype=np.int64) # 0 edible, 1 inedible
pho_pair_id = np.array(list(range(26)) + list(range(26)), dtype=np.int64)

def build_pair_masks():
    pho_same, pho_diff, sem_same, sem_diff = [], [], [], []
    for i in range(N_WORDS):
        for j in range(i + 1, N_WORDS):
            if pho_pair_id[i] == pho_pair_id[j]: pho_same.append((i, j))
            else: pho_diff.append((i, j))
            if semantic_label[i] == semantic_label[j]: sem_same.append((i, j))
            else: sem_diff.append((i, j))
    return pho_same, pho_diff, sem_same, sem_diff

PHO_SAME_PAIRS, PHO_DIFF_PAIRS, SEM_SAME_PAIRS, SEM_DIFF_PAIRS = build_pair_masks()

# =========================================================
# 3) Module Mapping System
# =========================================================
def get_layer_mapping(model):
    """
    Uniformly maps Qwen-Audio layer indices:
    0: conv1, 1: conv2
    2 ~ N: audio blocks
    N+1 ~ M: LLM blocks
    """
    mapping = {}
    idx = 0
    if hasattr(model.transformer, "audio"):
        enc = model.transformer.audio
        if hasattr(enc, "conv1"):
            mapping[idx] = (enc.conv1, "cnn"); idx += 1 
        if hasattr(enc, "conv2"):
            mapping[idx] = (enc.conv2, "cnn"); idx += 1 
        if hasattr(enc, "blocks"):
            for block in enc.blocks:
                mapping[idx] = (block, "audio"); idx += 1
    
    if hasattr(model.transformer, "h"):
        for block in model.transformer.h:
            mapping[idx] = (block, "llm"); idx += 1
    
    return mapping

LAYER_MAP = get_layer_mapping(model)

# =========================================================
# 4) Load P2S Neurons (Target Units)
# =========================================================
def load_direction_consistent_units(mat_path, key, top_k=500):
    try:
        mat = io.loadmat(mat_path)
    except FileNotFoundError:
        print(f"⚠️ File {mat_path} not found, using random test neurons for validation...")
        rows = [{"layer": 30, "neuron": i, "D": 1.0} for i in range(top_k)]
        by_layer = defaultdict(list)
        for r in rows: by_layer[r["layer"]].append(r)
        return rows, by_layer

    data = mat[key]
    rows = []
    for row in data:
        layer, neuron = int(row[0]) - 1, int(row[1]) - 1
        pho1, pho2 = float(row[2]), float(row[3])
        sem1, sem2 = float(row[4]), float(row[5])
        b1, b2 = pho1 - sem1, sem2 - pho2
        
        # Only take units with consistent direction of transformation
        if layer >= 0 and neuron >= 0 and b1 > 0 and b2 > 0:
            rows.append({"layer": layer, "neuron": neuron, "D": b1 + b2})

    print(f"[INFO] Number of direction-consistent units (b1>0, b2>0): {len(rows)}")
    rows = sorted(rows, key=lambda x: x["D"], reverse=True)[:top_k]
    print(f"[INFO] Extracted direction-consistent neurons: {len(rows)}")
    
    by_layer = defaultdict(list)
    for r in rows: by_layer[r["layer"]].append(r)
    return rows, by_layer

selected_units, selected_by_layer = load_direction_consistent_units(P2S_INDEX_MAT, P2S_INDEX_KEY, top_k=TOP_K)

# =========================================================
# 5) RepE Core System (Injection & Steering)
# =========================================================
injection_handles = []
injection_pack_gpu = {}

def compute_steering_vectors(per_word_acts, selected_by_layer, split_ratio=0.5):
    """Extract semantic axis, using P2S neurons as a mask"""
    print("\n[INFO] Computing Semantic Steering Vectors from Baseline...")
    steering_pack = {}
    
    for layer_idx, rows in selected_by_layer.items():
        neuron_indices = [r["neuron"] for r in rows]
        edible_vecs, inedible_vecs = [], []
        
        for word_idx in range(N_WORDS):
            act = per_word_acts[word_idx].get(layer_idx)
            if act is None: continue
            
            T, D = act.shape
            if T < 2: continue
            
            t_split = max(1, min(T - 1, int(T * split_ratio)))
            seg2_mean = act[t_split:, :].mean(dim=0)
            
            if semantic_label[word_idx] == 0: edible_vecs.append(seg2_mean)
            else: inedible_vecs.append(seg2_mean)
                
        if not edible_vecs or not inedible_vecs: continue
            
        mean_edible = torch.stack(edible_vecs).mean(dim=0)
        mean_inedible = torch.stack(inedible_vecs).mean(dim=0)
        
        C = (mean_edible + mean_inedible) / 2.0
        v_dir = mean_edible - mean_inedible
        
        mask = torch.zeros_like(v_dir)
        mask[neuron_indices] = 1.0
        
        C_masked = C * mask
        v_masked = v_dir * mask
        
        norm = v_masked.norm(p=2)
        v_norm = v_masked / norm if norm > 1e-8 else torch.zeros_like(v_masked)
        steering_pack[layer_idx] = {"C": C_masked, "v_norm": v_norm}
        
    print(f"[INFO] Steering vectors calculated for {len(steering_pack)} layers.")
    return steering_pack

def make_injection_hook(layer_idx, alpha, mode, steering_pack, prompt_len_ref):
    def hook(module, inp, out):
        if alpha == 0.0 or steering_pack is None or layer_idx not in steering_pack:
            return out

        main, rest, return_tuple = (out[0], list(out[1:]), True) if isinstance(out, (tuple, list)) else (out, [], False)
        if not isinstance(main, torch.Tensor): return out

        x = main 
        dev, dtype = x.device, x.dtype

        cache_key = (layer_idx, str(dev), str(dtype))
        if cache_key not in injection_pack_gpu:
            C = steering_pack[layer_idx]["C"].to(device=dev, dtype=dtype).view(1, 1, -1)
            v_norm = steering_pack[layer_idx]["v_norm"].to(device=dev, dtype=dtype).view(1, 1, -1)
            injection_pack_gpu[cache_key] = {"C": C, "v_norm": v_norm}

        pack = injection_pack_gpu[cache_key]
        C, v_norm = pack["C"], pack["v_norm"]

        # ---------------- Intervention Logic ----------------
        if x.ndim == 3:
            if mode == "cnn":
                # CNN output is [B, D, T], transpose to [B, T, D] for computation
                x_trans = x.transpose(1, 2)
                B, T, D = x_trans.shape
                if T >= 2:
                    t_split = max(1, min(T - 1, int(T * SPLIT_RATIO)))
                    x_seg2 = x_trans[:, t_split:, :]
                    proj = ((x_seg2 - C) * v_norm).sum(dim=-1, keepdim=True)
                    x_trans[:, t_split:, :] = x_seg2 + alpha * proj * v_norm
                x = x_trans.transpose(1, 2)
                
            else:
                B, T, D = x.shape
                if mode == "audio":
                    if T >= 2:
                        t_split = max(1, min(T - 1, int(T * SPLIT_RATIO)))
                        x_seg2 = x[:, t_split:, :]
                        proj = ((x_seg2 - C) * v_norm).sum(dim=-1, keepdim=True)
                        x[:, t_split:, :] = x_seg2 + alpha * proj * v_norm
                elif mode == "llm":
                    prompt_len = prompt_len_ref[0]
                    if T > prompt_len:
                        T_gen = T - prompt_len
                        if T_gen >= 2:
                            t_split_gen = max(1, min(T_gen - 1, int(T_gen * SPLIT_RATIO)))
                            abs_split_idx = prompt_len + t_split_gen
                            x_seg2 = x[:, abs_split_idx:, :]
                            proj = ((x_seg2 - C) * v_norm).sum(dim=-1, keepdim=True)
                            x[:, abs_split_idx:, :] = x_seg2 + alpha * proj * v_norm

        return (x, *rest) if return_tuple else x
    return hook

# =========================================================
# 6) Word Inference Loop
# =========================================================
def clean_text(text):
    text = re.sub(r"\s+", "", text)
    return re.sub(r"[^\w\u4e00-\u9fff]", "", text).strip()

def extract_transcription(text):
    match = re.search(r"['\"](.*)['\"]", text)
    if match:
        text = match.group(1)
    return re.sub(r"[^\w\u4e00-\u9fff]", "", text)

@torch.no_grad()
def process_single_audio(audio_file, alpha, steering_pack):
    """
    Returns:
    1. cleaned_response (prediction)
    2. final_acts (activation tensor dictionary)
    """
    audio_path = os.path.join(AUDIO_FOLDER, audio_file)
    sp_prompt = "<|startoftranscript|><|zh|><|transcribe|><|zh|><|notimestamps|>"
    query = f"<audio>{audio_path}</audio>{sp_prompt}"
    
    audio_info = tokenizer.process_audio(query)
    inputs = tokenizer(query, return_tensors='pt', audio_info=audio_info).to(model.device)
    prompt_len = inputs["input_ids"].shape[1]
    prompt_len_ref = [prompt_len]

    # --- Register Hooks ---
    activations = {}
    local_handles = []
    injection_pack_gpu.clear()

    # Collection Hook   
    def collect_hook(layer_idx, mode):
        def hook(module, inp, out):
            main = out[0] if isinstance(out, (tuple, list)) else out
            if isinstance(main, torch.Tensor):
                x = main.detach().cpu().to(torch.float32)
                # Process CNN layer [B, D, T] -> [B, T, D]
                if mode == "cnn":
                    x = x.transpose(1, 2)
                
                x = x.squeeze(0) # Becomes [T, D]
                
                if mode == "llm" and x.shape[0] > prompt_len:
                    activations[layer_idx] = x[prompt_len:, :]
                elif mode in ["audio", "cnn"]:
                    activations[layer_idx] = x
        return hook

    for layer_idx in selected_by_layer.keys():
        if layer_idx not in LAYER_MAP: continue
        module, mode = LAYER_MAP[layer_idx]
        
        # Register intervention hook first
        h_inj = module.register_forward_hook(
            make_injection_hook(layer_idx, alpha, mode, steering_pack, prompt_len_ref)
        )
        local_handles.append(h_inj)
        
        # Register collection hook
        h_col = module.register_forward_hook(collect_hook(layer_idx, mode))
        local_handles.append(h_col)

    # --- Generation ---
    pred = model.generate(**inputs, use_cache=False, audio_info=audio_info)

    # --- Decoding and Cleaning ---
    response = tokenizer.decode(pred.cpu()[0], skip_special_tokens=True, audio_info=audio_info)
    response_cleaned = re.sub(rf"^{re.escape(audio_path)}", "", response).strip()
    response_cleaned = clean_text(response_cleaned)

    # Unregister hooks
    for h in local_handles: h.remove()
    
    return response_cleaned, activations

# =========================================================
# 7) Feature Transformation and Statistics
# =========================================================

def extract_segment_feature(act_tensor, neuron_idx, seg_id):
    """
    Keep original time dimensions without interpolation.
    For odd lengths, Segment 1 takes one extra frame (rounded up).
    """
    if act_tensor is None or act_tensor.ndim != 2: 
        return np.array([], dtype=np.float32)
    
    T, D = act_tensor.shape
    if neuron_idx >= D or T < 1: 
        return np.array([], dtype=np.float32)

    ts = act_tensor[:, neuron_idx].numpy()
    
    # Rounded up split
    t_split = math.ceil(T / 2.0) 
    
    if seg_id == 1:
        seg = ts[:t_split]
    else:
        seg = ts[t_split:]
        
    return seg.astype(np.float32)

def truncated_cosine_distance(a, b):
    """
    Calculate cosine distance between unequal length vectors
    by truncating to the shortest length.
    """
    if len(a) == 0 and len(b) == 0: return 0.0
    if len(a) == 0 or len(b) == 0: return 1.0
    
    min_len = min(len(a), len(b))
    a_trunc = a[:min_len]
    b_trunc = b[:min_len]
    
    if np.allclose(a_trunc, 0) and np.allclose(b_trunc, 0): return 0.0
    if np.allclose(a_trunc, 0) or np.allclose(b_trunc, 0): return 1.0
    
    return float(cosine(a_trunc, b_trunc))

def t_value_from_pairs(dist_mat, same_pairs, diff_pairs):
    same_vals = np.array([dist_mat[i, j] for (i, j) in same_pairs], dtype=np.float32)
    diff_vals = np.array([dist_mat[i, j] for (i, j) in diff_pairs], dtype=np.float32)
    if len(same_vals) < 2 or len(diff_vals) < 2: return np.nan
    
    # Default ttest_ind assumes equal variance
    res = stats.ttest_ind(diff_vals, same_vals, equal_var=True)
    
    return float(res.statistic)

def evaluate_metrics(per_word_acts):
    PI1_all, SI1_all, PI2_all, SI2_all, M_all = [], [], [], [], []
    for u in selected_units:
        layer, neuron = u["layer"], u["neuron"]
        seg1_feats, seg2_feats = [], []
        
        # 1. Get raw features for all words
        for w_idx in range(N_WORDS):
            act = per_word_acts[w_idx].get(layer)
            seg1_feats.append(extract_segment_feature(act, neuron, 1))
            seg2_feats.append(extract_segment_feature(act, neuron, 2))

        # 2. Distance matrix calculation
        d1, d2 = np.zeros((N_WORDS, N_WORDS)), np.zeros((N_WORDS, N_WORDS))
        for i in range(N_WORDS):
            for j in range(i + 1, N_WORDS):
                dist1 = truncated_cosine_distance(seg1_feats[i], seg1_feats[j])
                dist2 = truncated_cosine_distance(seg2_feats[i], seg2_feats[j])
                
                d1[i, j] = d1[j, i] = dist1
                d2[i, j] = d2[j, i] = dist2

        # 3. T-test for PI and SI
        PI1 = t_value_from_pairs(d1, PHO_SAME_PAIRS, PHO_DIFF_PAIRS)
        SI1 = t_value_from_pairs(d1, SEM_SAME_PAIRS, SEM_DIFF_PAIRS)
        PI2 = t_value_from_pairs(d2, PHO_SAME_PAIRS, PHO_DIFF_PAIRS)
        SI2 = t_value_from_pairs(d2, SEM_SAME_PAIRS, SEM_DIFF_PAIRS)
        
        PI1_all.append(PI1)
        SI1_all.append(SI1)
        PI2_all.append(PI2)
        SI2_all.append(SI2)
        M_all.append((PI1 - SI1) + (SI2 - PI2))

    return {
        "PI1": float(np.nanmean(PI1_all)), "SI1": float(np.nanmean(SI1_all)),
        "PI2": float(np.nanmean(PI2_all)), "SI2": float(np.nanmean(SI2_all)),
        "M": float(np.nanmean(M_all))
    }

# =========================================================
# 8) Main Control Logic
# =========================================================
def run_evaluation(alpha, steering_pack=None):
    print(f"\n{'='*60}\n[RUN] Alpha = {alpha}\n{'='*60}")
    
    correct = 0
    per_word_acts = []
    
    trans_path = os.path.join(OUT_DIR, f"trans_alpha_{alpha:.1f}.txt")
    fout = open(trans_path, "w", encoding="utf-8") if SAVE_PER_WORD_TRANS else None

    for idx, audio_file in enumerate(audio_files):
        key = audio_file.replace(".wav", "")
        gt = PINYIN2ZH[key]
        
        pred, acts = process_single_audio(audio_file, alpha, steering_pack)
        per_word_acts.append(acts)
        
        ok = int(pred == gt)
        correct += ok
        
        print(f"[{idx+1:02d}/52] GT={gt} | PRED={pred} | Correct={ok}")
        if fout: fout.write(f"{audio_file}\tGT:{gt}\tPRED:{pred}\tOK:{ok}\n")
        
    if fout: fout.close()
    
    acc = correct / N_WORDS
    print(f"\n-> Accuracy: {acc:.4f} ({correct}/52)")
    
    metrics = evaluate_metrics(per_word_acts)
    metrics.update({"alpha": alpha, "acc": acc, "correct": correct, "acts": per_word_acts})
    return metrics

if __name__ == "__main__":
    results = []
    
    # Phase 1: Establish steering vectors from baseline
    print("\n>>> Phase 1: Running Baseline to establish Steering Vectors")
    baseline = run_evaluation(alpha=0.0, steering_pack=None)
    M_base = baseline["M"]
    baseline["delta_M"] = 0.0
    results.append(baseline)
    
    # Compute Steering Pack
    steering_pack = compute_steering_vectors(baseline["acts"], selected_by_layer, split_ratio=SPLIT_RATIO)
    del baseline["acts"] # Free memory
    
    # Phase 2: Perform RepE intervention
    print("\n>>> Phase 2: Intervening Representations")
    for alpha in ALPHAS:
        if alpha == 0.0: continue
        res = run_evaluation(alpha=alpha, steering_pack=steering_pack)
        res["delta_M"] = res["M"] - M_base
        del res["acts"]
        results.append(res)
        
    # Save results
    summary_csv = os.path.join(OUT_DIR, "summary_qwenaudio_repe.csv")
    with open(summary_csv, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["alpha", "correct", "acc", "PI1", "SI1", "PI2", "SI2", "M_mean", "delta_M_vs_baseline"])
        for r in results:
            writer.writerow([r["alpha"], r["correct"], r["acc"], r["PI1"], r["SI1"], r["PI2"], r["SI2"], r["M"], r["delta_M"]])
            
    print(f"\n✅ All tasks completed! Results saved to: {summary_csv}")