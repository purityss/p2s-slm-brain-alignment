import torch
from io import BytesIO
import librosa
from transformers import Qwen2AudioForConditionalGeneration, AutoProcessor
import os
import warnings
from scipy import io
import re
from jiwer import wer, cer
import csv
import pandas as pd

warnings.filterwarnings("ignore")

model_path = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/qwen2_audio/qwen2-Audio-7B"

# Initialize model and processor
print("Step 1: Loading model...")
processor = AutoProcessor.from_pretrained(model_path)
model = Qwen2AudioForConditionalGeneration.from_pretrained(model_path, device_map="cuda:0")
print("Model loaded successfully.")
#print(model)

# Read the audio file and pass it as a byte stream
def read_audio_file(audio_path):
    with open(audio_path, 'rb') as f:
        return BytesIO(f.read())

# Set an explicit transcription prompt
prompt = "<|audio_bos|><|AUDIO|><|audio_eos|>Transcribe the speech in the audio:"

# **New path: Aishell test set**
audio_root_dir = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/Aishell/speech_asr_aishell1_testsets/wav/test"
transcription_file = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/Aishell/speech_asr_aishell1_testsets/test_trans.xlsx"
# Root directory prefix (used to concatenate relative paths in Excel)
audio_root_prefix = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/Aishell"

# **Read the Excel file and establish a mapping from full path to text**
transcriptions = {}
df = pd.read_excel(transcription_file, skiprows=2, header=None)

# Concatenate prefix and normalize path format
transcriptions = {
    os.path.normpath(os.path.join(audio_root_prefix, row[0].strip())): row[1].strip()
    for _, row in df.iterrows()
    if isinstance(row[0], str) and isinstance(row[1], str)
}

print(f"Loaded {len(transcriptions)} transcriptions")

# **Process ground truth transcription text**
def clean_text(text):
    """Remove all spaces, punctuation, and special characters from the text, and strip leading/trailing whitespace"""
    text = re.sub(r"\s+", "", text)  # Remove all spaces
    text = re.sub(r"[^\w\u4e00-\u9fff]", "", text)  # Keep only Chinese characters, English letters, and numbers
    return text.strip()

# Extract transcription content from the predicted text
def extract_transcription(predicted_text):
    # First extract text within quotes (if any)
    match = re.search(r"['\"](.*)['\"]", predicted_text)
    if match:
        predicted_text = match.group(1)  # Extract text from quotes

    # Remove all punctuation and special characters (keep Chinese, English, numbers)
    predicted_text = re.sub(r"[^\w\u4e00-\u9fff]", "", predicted_text)

    return predicted_text

# **Store WER and CER calculation results**
total_wer = 0
total_cer = 0
num_samples = 0

# **Output file**
output_file = "/appsnew/home/ffang_pkuhpc/gpfs1/zss/qwen2_audio/test_output/qwen2_audio_aishell1_test_transcriptions.txt"
# **Recursively traverse all audio files**
with open(output_file, "w", encoding="utf-8") as f:
    for root, dirs, files in os.walk(audio_root_dir):
        for file in files:
            if not file.endswith(".wav"):
                continue

            audio_path = os.path.normpath(os.path.join(root, file))

            if audio_path not in transcriptions:
                print(f"Ground truth transcription not found for: {audio_path}")
                continue

            # **Get audio file path**
            print(f"\nProcessing: {audio_path}")

            # Read audio data
            audio, sr = librosa.load(audio_path, sr=processor.feature_extractor.sampling_rate)

            # Process inputs
            inputs = processor(text=prompt, audios=audio, return_tensors="pt", padding=True)
            inputs = {k: v.to("cuda:0") for k, v in inputs.items()}  # Move to GPU

            # Generate text
            generated_ids = model.generate(**inputs, max_new_tokens=256)

            # Remove the prompt part of the input to get the model output
            generated_ids = generated_ids[:, inputs["input_ids"].size(1):]
            predicted_text = \
            processor.batch_decode(generated_ids, skip_special_tokens=True, clean_up_tokenization_spaces=False)[0]

            # **Get ground truth transcription text**
            actual_text = transcriptions[audio_path]

            # **Clean ground truth and predicted texts**
            actual_text = clean_text(actual_text)  # Clean ground truth

            # Extract the transcription part from the predicted text
            extracted_predicted_text = extract_transcription(predicted_text)

            # **Calculate WER/CER**
            # error_rate = wer(actual_text, extracted_predicted_text)
            error_rate = min(wer(actual_text, extracted_predicted_text), 1.0)
            total_wer += error_rate
            # character_error = cer(actual_text, extracted_predicted_text)
            character_error = min(cer(actual_text, extracted_predicted_text), 1.0)
            total_cer += character_error
            num_samples += 1

            # **Save transcription text**
            f.write(f"{audio_path} {predicted_text}\n")
            print(f"Saved transcription: {audio_path}")

            # **Output ground truth text and model transcription**
            print(f"Ground truth: {actual_text}")
            print(f"Model transcription: {extracted_predicted_text}")
            print(f"Current WER: {error_rate:.6f}")
            print(f"Current CER: {character_error:.6f}\n")


# **Calculate final average WER and CER**
if num_samples > 0:
    average_wer = total_wer / num_samples
    print(f"Average WER of qwen2-audio model: {average_wer:.6f}")
    average_cer = total_cer / num_samples
    print(f"Average CER of qwen2-audio model: {average_cer:.6f}")
else:
    print("No valid samples, cannot calculate WER.")