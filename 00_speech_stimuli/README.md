# Speech stimuli

This directory contains the spoken-word stimuli used by the analysis:

- `Words_Chinese_52/`: 52 Mandarin Chinese WAV files, named using pinyin.
- `Words_English_52/wav_fixed/`: 52 English WAV files, prefixed with item numbers `01`–`52`.

All 104 files are mono, 16-bit PCM, sampled at 16 kHz. The Chinese clips are 0.5 s each. The English clips range from approximately 1.416 to 1.776 s.

The Mandarin stimuli are disyllabic words recorded by a female native speaker (reported mean fundamental frequency: 254 Hz). They comprise 26 edible and 26 inedible words arranged into 26 pairs sharing the first syllable. Mean word frequency was matched across categories. In the human experiment, stimuli were delivered binaurally at approximately 70 dB SPL; each word occurred 12 times over four randomized 156-trial blocks, with a random 2–4 s inter-stimulus interval.

## Item identity and ordering

The Chinese condition order used in `01_brain_analysis/01_process_sEEG_pipeline_each_sub/step1_datacook_52word.m` is:

`草莓, 带鱼, 蛋糕, 豆腐, 海带, 红薯, 鸡蛋, 煎饼, 荔枝, 龙虾, 萝卜, 绿豆, 芒果, 蜜桔, 面包, 蘑菇, 牛肉, 苹果, 软糖, 薯条, 西瓜, 香肠, 洋葱, 樱桃, 玉米, 猪蹄, 草坪, 代表, 弹弓, 逗号, 海滩, 红灯, 机会, 肩膀, 力量, 笼子, 螺旋, 律师, 盲人, 密码, 面具, 模特, 牛仔, 评委, 软件, 暑假, 膝盖, 乡村, 阳光, 英雄, 浴室, 珠宝`.

The English numeric prefixes provide an explicit order. Do not assume that Chinese filename sorting gives the experimental condition order.

## Use

Python example:

```python
import librosa

audio, sr = librosa.load(
    "00_speech_stimuli/Words_Chinese_52/caomei.wav",
    sr=16000,
    mono=True,
)
```

MATLAB example:

```matlab
[audio, fs] = audioread('00_speech_stimuli/Words_Chinese_52/caomei.wav');
assert(fs == 16000);
```
