# Fem-Psych Monitor — Technical Documentation for AI/ML Journal

**App Version:** 1.0.1  
**Package Name:** `com.fempsychmonitor`  
**Platform:** Android (Flutter)  
**Last Updated:** 16 Juni 2026

---

## Table of Contents

1. [Application Overview](#1-application-overview)
2. [System Architecture](#2-system-architecture)
3. [Audio Emotion Recognition Model](#3-audio-emotion-recognition-model)
4. [Text-Based Emotion Analysis](#4-text-based-emotion-analysis)
5. [Speech-to-Text Integration (Whisper)](#5-speech-to-text-integration-whisper)
6. [Emotion Score Fusion](#6-emotion-score-fusion)
7. [MBTI Personality Assessment](#7-mbti-personality-assessment)
8. [Psychological Screening](#8-psychological-screening)
9. [Personalized Suggestion System](#9-personalized-suggestion-system)
10. [Dataset Sources](#10-dataset-sources)
11. [On-Device Inference Pipeline](#11-on-device-inference-pipeline)
12. [Future Work & Improvements](#12-future-work--improvements)
13. [Project Structure](#13-project-structure)
14. [References](#14-references)

---

## 1. Application Overview

Fem-Psych Monitor is a women's psychological monitoring application designed for the Indonesian market. It combines **audio emotion recognition** (deep learning), **text-based keyword analysis**, **speech-to-text transcription**, and **psychological assessments** (MBTI + mental health screening) to provide users with daily emotion tracking and personalized mental health insights.

### Key AI/ML Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Audio Emotion Recognition | TensorFlow Lite (CNN-BiLSTM-Transformer) | Classify 6 emotions from voice recordings |
| Text Emotion Analysis | Keyword matching (JSON dictionaries) | Analyze transcribed text for emotional content |
| Speech-to-Text | Whisper (whisper_kit) | Transcribe Indonesian/English speech |
| Score Fusion | Gemini AI API (Google) | Combine audio (60%) and text (40%) scores |
| MBTI Assessment | Rule-based scoring (20 questions) | Classify personality into 16 types |
| Mental Health Screening | Likert-scale questionnaire (20 questions) | Score psychological well-being |

### Emotion Classes

Six universal emotions are detected:
- Happy (positive valence, high arousal)
- Sad (negative valence, low arousal)
- Angry (negative valence, high arousal)
- Fear (negative valence, high arousal)
- Disgust (negative valence, medium arousal)
- Neutral (medium valence, low arousal)

---

## 2. System Architecture

### 2.1 High-Level Pipeline

```
User Voice Input
       │
       ▼
┌──────────────────┐     ┌──────────────────┐
│  Audio Recording │────►│  Feature Extract  │
│  (16kHz, mono)   │     │  (MFCC + Δ + Δ²  │
│  3-second frames  │     │   + ZCR = 121 feats)│
└──────────────────┘     └────────┬─────────┘
                                  ▼
                        ┌──────────────────┐
                        │  TFLite Inference │
                        │  CNN-BiLSTM-ATTN  │
                        └────────┬─────────┘
                                 │ Audio Scores (60%)
                                 │
User Voice Input                 │
       │                         │
       ▼                         │
┌──────────────────┐             │
│  Whisper STT     │             │
│  (base model)    │             │
└────────┬─────────┘             │
         │                       │
         ▼                       │
┌──────────────────┐             │
│  Text Emotion    │             │
│  Keyword Match   │─────────────┤ Text Scores (40%)
│  (ID + EN)       │             │
└──────────────────┘             │
                                 │
                                 ▼
                        ┌──────────────────────┐
                        │  Gemini Score Fusion  │
                        │  audio × 0.6          │
                        │  + text × 0.4         │
                        │  = combined_scores     │
                        └──────────────────────┘
                                 │
                                 ▼
                        ┌──────────────────────┐
                        │  Suggestion Service   │
                        │  (MBTI × Emotion)     │
                        └──────────────────────┘
                                 │
                                 ▼
                        ┌──────────────────────┐
                        │  Save to Firestore    │
                        │  (RecordingData)      │
                        └──────────────────────┘
```

### 2.2 Mobile Architecture (Flutter)

```
┌────────────────────────────────────────────────┐
│              Presentation Layer                 │
│  Screens: Home, Recording, Result, History,    │
│           Profile, Settings, Premium            │
├────────────────────────────────────────────────┤
│              State Management (Provider)        │
│  AuthProvider, ThemeProvider, LocaleProvider,   │
│  PremiumProvider, AudioRecorderWithDetection    │
├────────────────────────────────────────────────┤
│              Service Layer                       │
│  ┌──────────┐ ┌──────────┐ ┌────────────────┐  │
│  │ Database │ │ Whisper  │ │ TextEmotion    │  │
│  │ Service  │ │ Init     │ │ Service        │  │
│  │(Firestore)│ │ Service  │ │(keyword match) │  │
│  └──────────┘ └──────────┘ └────────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌────────────────┐  │
│  │ Gemini   │ │ Suggestion│ │ Subscription  │  │
│  │ Service  │ │ Service  │ │ Service        │  │
│  │(score    │ │(MBTI-based│ │(RevenueCat)    │  │
│  │ fusion)  │ │ saran)   │ │                │  │
│  └──────────┘ └──────────┘ └────────────────┘  │
├────────────────────────────────────────────────┤
│              ML / Data Layer                    │
│  ┌──────────┐ ┌──────────┐ ┌────────────────┐  │
│  │ TFLite   │ │ Whisper  │ │ Emotion/       │  │
│  │ Model    │ │ Model    │ │ MBTI/Psych     │  │
│  │(685KB)   │ │(~142MB)  │ │ JSON Assets    │  │
│  └──────────┘ └──────────┘ └────────────────┘  │
└────────────────────────────────────────────────┘
```

---

## 3. Audio Emotion Recognition Model

### 3.1 Model Architecture: Hybrid CNN-BiLSTM-Transformer

The core emotion recognition model uses a hybrid architecture combining Convolutional Neural Networks (CNN), Bidirectional Long Short-Term Memory (BiLSTM), and Multi-Head Attention (Transformer).

```
Input: (None, 128, 121)
  │
  ├── Conv1D(64 filters, kernel=3, ReLU)
  │     └── BatchNormalization
  │           └── MaxPool1D(pool_size=2)
  │                 └── Dropout(0.3)
  │
  ├── Conv1D(128 filters, kernel=3, ReLU)
  │     └── BatchNormalization
  │           └── MaxPool1D(pool_size=2)
  │                 └── Dropout(0.3)
  │
  ├── Bidirectional(LSTM(128, return_sequences=True))
  │     └── Dropout(0.4)
  │
  ├── MultiHeadAttention(num_heads=4, key_dim=64)
  │     └── Residual Add + Layer Normalization
  │           └── Dropout(0.3)
  │
  ├── GlobalAveragePooling1D
  │
  ├── Dense(128, ReLU)
  │     └── Dropout(0.5)
  │
  └── Dense(6, Softmax)
        └── Output: [happy, sad, angry, fearful, disgust, neutral]
```

**Key design decisions:**
- CNN layers capture local acoustic patterns (intonation, emphasis)
- BiLSTM models temporal dependencies across speech frames
- Multi-Head Attention provides global context (captures relationships between distant frames)
- Residual connection in attention prevents gradient degradation
- Gender-specific models (separate male/female training)

### 3.2 Input Features

**Feature vector (121 dimensions per time frame):**

| Feature | Dimensions | Description |
|---------|-----------|-------------|
| MFCC | 40 | Mel-Frequency Cepstral Coefficients |
| Delta MFCC (Δ) | 40 | First-order derivative of MFCC |
| Delta-Delta MFCC (Δ²) | 40 | Second-order derivative of MFCC |
| Zero-Crossing Rate | 1 | Rate of sign changes in the signal |

**Preprocessing pipeline:**
- Sample rate: 16 kHz
- Frame duration: 3 seconds (128 time frames)
- Frame shift: ~23 ms (hop length)
- FFT window: Hamming, 512 samples
- Mel filter bank: 40 filters
- Pre-emphasis coefficient: 0.97
- Noise augmentation: Gaussian noise (std=0.02) applied to every 3rd sample during training
- Normalization: Per-feature standardization (z-score)

### 3.3 Training Configuration

| Parameter | Value |
|-----------|-------|
| Optimizer | Adam (learning rate = 0.001) |
| Loss function | Categorical Crossentropy |
| Batch size | 32 |
| Max epochs | 50 |
| Early stopping | ReduceLROnPlateau (factor=0.5, patience=5) |
| Class balancing | SMOTE oversampling + random undersampling |
| Train/validation/test split | ~72.25% / 12.75% / 15% (stratified) |
| GPU | NVIDIA Tesla T4 (Kaggle) |
| Framework | TensorFlow 2.x / Keras |

### 3.4 TFLite Conversion

The trained Keras model is converted to TensorFlow Lite with specific settings for LSTM support:

```python
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS
]
converter._experimental_lower_tensor_list_ops = False
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()
```

**Critical details:**
- `SELECT_TF_OPS` is required because standard TFLite does not support LSTM operations natively
- `_experimental_lower_tensor_list_ops = False` prevents conversion errors with LSTM state management
- Model size after conversion: **685.52 KB**
- On-device inference uses `FlexDelegate` (flutter_litert) to execute SELECT_TF_OPS

### 3.5 Gender-Specific Training

**Two separate models were trained:**
- `final_female_model.tflite` — deployed in the app
- `final_male_model.tflite` — available but not deployed

The rationale for gender-specific models is that male and female voices have fundamentally different acoustic characteristics (pitch range, formant frequencies, timbre), which can cause a single model to learn gender-biased features rather than emotion-relevant features.

**Currently only the female model is deployed** in the production app. The app's Dart code in `audio_recorder_detection.dart` loads `assets/final_female_model.tflite`.

---

## 4. Text-Based Emotion Analysis

### 4.1 Keyword Matching Approach

Separate from the deep learning audio model, the app uses a **dictionary-based keyword matching** approach for analyzing transcribed text.

Two JSON files contain emotion-labeled keywords:

| File | Language | Total Keywords |
|------|----------|---------------|
| `assets/emotion.json` | Indonesian (mixed with slang) | 424 keywords |
| `assets/emotion_en.json` | English | 381 keywords |

**Keyword distribution:**

| Emotion | ID Keywords | EN Keywords | Example (ID) | Example (EN) |
|---------|------------|-------------|-------------|--------------|
| happy | 82 | 83 | bahagia, seneng, syukur | happy, joyful, great |
| sad | 79 | 70 | sedih, kecewa, nelangsa | sad, depressed, lonely |
| angry | 73 | 61 | marah, kesel, bete | angry, furious, annoyed |
| disgust | 64 | 62 | jijik, muak, ngeri | disgust, gross, nasty |
| fear | 69 | 65 | takut, cemas, parno | fear, scared, anxious |
| neutral | 57 | 40 | biasa, santai, fine | neutral, okay, fine |

### 4.2 Scoring Algorithm (`TextEmotionService`)

```
Input: transcript_text (String)
                │
                ▼
    ┌──────────────────────────┐
    │ Load both keyword sets    │
    │ (ID + EN) simultaneously  │
    └────────────┬─────────────┘
                 │
                 ▼
    ┌──────────────────────────┐
    │ For each emotion class:   │
    │   score = 0               │
    │   For each keyword:       │
    │     if keyword in text:   │
    │       score += 1          │
    └────────────┬─────────────┘
                 │
                 ▼
    ┌──────────────────────────┐
    │ Normalize:               │
    │   total = Σ scores       │
    │   if total > 0:          │
    │     scores /= total      │
    └────────────┬─────────────┘
                 │
                 ▼
    Output: Map<EmotionType, double>
```

**Example for transcript "Saya sedih dan kecewa hari ini":**
- Match: `sedih` → sad +1, `kecewa` → sad +1
- Total matches: 2
- Normalized sad score: 2/2 = 1.0
- All other emotions: 0.0

**Limitations:**
- Does not account for negation ("tidak sedih" would still match `sedih`)
- No semantic understanding — purely lexical
- Context-independent

---

## 5. Speech-to-Text Integration (Whisper)

### 5.1 Model Selection

| Feature | Value |
|---------|-------|
| Engine | whisper_kit (Flutter package) |
| Model size | base (~142 MB) |
| Language | Indonesian (`id`) + auto-detect |
| Threads | 4 (mobile-optimized) |
| Sample rate | 16 kHz |
| Format | WAV (mono, 16-bit PCM) |

### 5.2 Integration Architecture

```
┌──────────────────────────────────────┐
│         EmotionDetectionScreen       │
│                                      │
│  1. AudioRecorder records WAV file   │
│     (16kHz, mono, temp directory)    │
│                                      │
│  2. On stop:                         │
│     Whisper.transcribe(WAV_file)     │
│       └── language: 'id'             │
│       └── threads: 4                 │
│                                      │
│  3. transcript → TextEmotionService  │
│     (keyword matching)               │
│                                      │
│  4. TFLite → audio_emotion_scores    │
│                                      │
│  5. GeminiService.combineResults()   │
│     (audio 60% + text 40%)           │
│                                      │
│  6. Navigate to ResultScreen         │
└──────────────────────────────────────┘
```

### 5.3 Model Download Strategy

To avoid loading the model twice (causing crashes), the initialization service (`WhisperInitService.warmUp()`) only **pre-downloads** the model file via `downloadModel()` without creating a Whisper inference instance or loading the model into memory. The actual model load happens only once during the first `transcribe()` call in `EmotionDetectionScreen`.

---

## 6. Emotion Score Fusion

### 6.1 Weighting Scheme

Audio and text scores are combined using fixed weights:

```
combined_scores[emotion] = audio_scores[emotion] × 0.6
                         + text_scores[emotion]  × 0.4
```

**Rationale:**
- Audio (60%) weighted higher because vocal tone is more difficult to consciously control
- Text (40%) supplements with explicit semantic content
- Weights determined heuristically; no formal optimization performed

### 6.2 Dominant Emotion Selection

```
dominantEmotion = argmax(combined_scores)
confidence = combined_scores[dominantEmotion]
```

### 6.3 Emotion Trend Score

```
emotionTrendScore = emotionValue × confidence

emotionValues:
  happy:   +10
  neutral:   0
  sad:      -6
  fear:     -6
  angry:    -8
  disgust:  -4
```

The trend score ranges from -8 to +10, displayed on both the result screen and history charts.

---

## 7. MBTI Personality Assessment

### 7.1 Assessment Design

**20 forced-choice questions** (5 per dimension):

| Dimension | Scale | Questions |
|-----------|-------|-----------|
| E/I | Extraversion vs Introversion | 5 |
| S/N | Sensing vs Intuition | 5 |
| T/F | Thinking vs Feeling | 5 |
| J/P | Judging vs Perceiving | 5 |

Each question has exactly 2 options, each mapping to one end of the dimension.

### 7.2 Scoring Algorithm

```python
scores = {E:0, I:0, S:0, N:0, T:0, F:0, J:0, P:0}
for each answer:
    scores[answer.type] += 1

dimensions = {
    "E_I": "E" if scores["E"] > scores["I"] else "I",
    "S_N": "S" if scores["S"] > scores["N"] else "N",
    "T_F": "T" if scores["T"] > scores["F"] else "F",
    "J_P": "J" if scores["J"] > scores["P"] else "P"
}

mbti_type = dimensions["E_I"] + dimensions["S_N"] 
          + dimensions["T_F"] + dimensions["J_P"]
```

### 7.3 Output Format

Each MBTI type includes:
- **Type code** (e.g., INFJ)
- **Alias** (e.g., "The Advocate")
- **Group** (Analis / Diplomat / Pengawal / Penjelajah)
- **Description** (Indonesian & English)
- **Strengths** (key characteristics)

All 16 types are fully documented in the app's assets.

---

## 8. Psychological Screening

### 8.1 Assessment Design

**20 questions** across 5 categories (4 questions each):

| Category | Focus | Score Range |
|----------|-------|-------------|
| Beban Peran & Stres | Work-life balance, societal pressure | 0–12 |
| Regulasi Emosi & Hormonal | Emotional control, hormonal influence | 0–12 |
| Kecemasan & Stres Sosial | Social anxiety, future worries | 0–12 |
| Citra Tubuh & Harga Diri | Body image, self-esteem | 0–12 |
| Kelelahan Emosional & Dukungan Sosial | Burnout, support system | 0–12 |

**Scoring:** Each question has 4 Likert options (score 0–3), where higher scores indicate more severe distress.

### 8.2 Category Classification

| Total Score | Category | Recommendation |
|------------|----------|---------------|
| 0–15 | Sehat Optimal (Optimal Health) | Maintain healthy lifestyle |
| 16–30 | Cukup Sehat (Moderate Health) | Monitor, continue self-care |
| 31–45 | Rentan (Vulnerable) | Seek social support, counseling |
| 46+ | Butuh Perhatian Klinis (Clinical Attention) | Professional help recommended |

---

## 9. Personalized Suggestion System

### 9.1 Recommendation Matrix

The `saran.json` file contains a 16 (MBTI types) × 6 (emotions) grid, producing **480 unique suggestion strings**.

For each combination of MBTI type and detected emotion, the system returns 5 action-oriented suggestions tailored to the personality type.

**Example — INTJ experiencing Sadness:**
1. "Analisis penyebab kesedihan secara logis" (Logically analyze the cause of sadness)
2. "Evaluasi apakah situasi ini dapat dikendalikan" (Evaluate if this situation is controllable)
3. "Buat rencana konkret untuk perbaikan" (Make a concrete plan for improvement)
4. "Gunakan waktu sendiri untuk refleksi" (Use alone time for reflection)
5. "Pertimbangkan dampak jangka panjang" (Consider long-term impact)

**Example — ENFP experiencing Sadness:**
1. "Curhat dengan teman dekat" (Confide in close friends)
2. "Cari aktivitas kreatif yang menyenangkan" (Find fun creative activities)
3. "Ingat pengalaman positif masa lalu" (Remember positive past experiences)
4. "Eksplorasi ide-ide baru yang inspiring" (Explore new inspiring ideas)
5. "Bagikan perasaan dalam jurnal" (Share feelings in a journal)

### 9.2 Suggestion Loading

Suggestions are loaded from `assets/saran.json` (Indonesian) or `assets/saran_en.json` (English) based on the current locale. The `SuggestionService` singleton caches the loaded suggestions and re-loads on locale change.

---

## 10. Dataset Sources

### 10.1 Combined Dataset Composition

| Dataset | Language | Gender | Emotions | Samples | Role |
|---------|----------|--------|----------|---------|------|
| **RAVDESS** | English | Mixed (24 actors) | Happy, Sad, Angry, Fearful, Disgust, Neutral + Calm, Surprised | ~1,440 | Core emotion dataset |
| **CREMA-D** | English | Mixed (48 actors) | Happy, Sad, Angry, Fearful, Disgust, Neutral | 7,443 | Large-scale supplement |
| **TESS** | English | Female only | Happy, Sad, Angry, Fearful, Disgust, Neutral + Surprised | ~2,800 | Female voice enrichment |
| **SAVEE** | English | Male only | Happy, Sad, Angry, Fearful, Disgust, Neutral + Surprised | ~480 | Male voice enrichment |
| **E-SERAVD** | Indonesian | Mixed | Happy, Sad, Angry, Neutral | ~1,200 | Indonesian language data |
| **IndoWaveSentiment** | Indonesian | Mixed | Happy, Sad, Angry, Neutral, Fear | ~1,500 | Indonesian language data |

### 10.2 Emotion Label Mapping

Some datasets contain emotions beyond the 6 target classes:

| Target Class | RAVDESS | TESS | SAVEE | CREMA-D | E-SERAVD | IndoWaveSentiment |
|-------------|---------|------|-------|---------|----------|-------------------|
| happy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| sad | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| angry | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| fearful | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| disgust | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| neutral | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |
| *calm/surprised* | → neutral | → neutral | → neutral | — | — | — |

**Important note:** Fearful and disgust labels for Indonesian speech are not available — these emotions are learned exclusively from English datasets. Neutral for Indonesian speech is available from E-SERAVD but not from IndoWaveSentiment.

### 10.3 Data Preprocessing

```
Raw Audio (variable length, 16kHz)
        │
        ▼
Truncate/pad to 3.0 seconds
        │
        ▼
Pre-emphasis (coefficient = 0.97)
        │
        ▼
Frame blocking (frame size ≈ 23ms, hop ≈ 12ms)
        │
        ▼
Feature extraction:
  ├── 40 MFCC
  ├── 40 Delta MFCC (Δ)
  ├── 40 Delta-Delta MFCC (Δ²)
  └── 1 Zero-Crossing Rate
        │
        ▼
Output: (128 time frames, 121 features)
        │
        ▼
SMOTE oversampling (per dataset/gender)
        │
        ▼
Gaussian noise augmentation (std=0.02) on every 3rd sample
        │
        ▼
Random undersampling (all classes = minority class count)
        │
        ▼
Save: combined_balanced_{gender}.npz
```

### 10.4 Class Distribution (After Balancing)

All classes are balanced after SMOTE oversampling + random undersampling, ensuring each of the 6 emotions has an equal number of training samples per gender.

---

## 11. On-Device Inference Pipeline

### 11.1 Feature Extraction (Dart)

The mobile app reimplements the entire librosa-compatible feature extraction pipeline in Dart to ensure inference-time features match training-time features exactly:

```dart
// Pre-emphasis
for (int i = 1; i < samples.length; i++) {
    samples[i] = samples[i] - 0.97 * samples[i - 1];
}

// Framing + Windowing (Hamming)
// STFT → Mel filterbank → log → DCT → MFCC
// Delta computation (central difference)
// Zero-crossing rate (sign changes / frame_length)
```

### 11.2 Model Loading

```dart
final flexDelegate = await FlexDelegate.create();
final interpreterOptions = InterpreterOptions()
  ..addDelegate(flexDelegate)
  ..threads = 2;
_interpreter = await Interpreter.fromAsset(
  'assets/final_female_model.tflite',
  options: interpreterOptions,
);
```

### 11.3 Real-Time Audio Stream Detection

The `AudioRecorderWithDetection` service provides continuous emotion detection during live monitoring:

1. Audio chunks streamed every ~3 seconds
2. Each chunk processed through the feature extraction → TFLite pipeline
3. Results emitted via broadcast `StreamController<DetectionResult>`
4. UI updates emotion chips and pulse animation in real time

### 11.4 Full Recording Detection

For saved recordings, the `EmotionDetectionScreen`:

1. Records full WAV file (16kHz, mono)
2. On stop, runs Whisper transcription (blocking, 1–5s)
3. Runs TFLite inference on the full audio
4. Runs text keyword matching on transcript
5. Fuses scores via GeminiService
6. Navigates to ResultScreen

---

## 12. Future Work & Improvements

### 12.1 Model Improvements

| Area | Current | Proposed |
|------|---------|----------|
| **Feature set** | 121 features (MFCC+Δ+Δ²+ZCR) | Add prosodic features (pitch, energy, voice quality) |
| **Indonesian emotions** | Fearful & disgust from EN only | Collect Indonesian speech for all 6 emotions |
| **Real-time processing** | 3-second window | Variable-length input with attention masking |
| **Gender** | Female-only deployed | Add male model or gender-agnostic model |
| **Domain adaptation** | None | Fine-tune on Indonesian speech data |
| **Architecture** | CNN-BiLSTM-Attention | Wav2Vec 2.0 / HuBERT transformer |
| **Model size** | 685 KB TFLite | Quantization-aware training for further compression |

### 12.2 Text Analysis Improvements

| Area | Current | Proposed |
|------|---------|----------|
| **Approach** | Keyword matching (dictionary-based) | Fine-tuned BERT/IndoBERT for emotion classification |
| **Negation handling** | None | Scope detection ("tidak sedih" → not sad) |
| **Intensity** | Binary (matched/not matched) | Weighted by word intensity |
| **Context** | Single sentence | Multi-utterance context |

### 12.3 Data Collection

- **In-app labeling**: Allow users to self-report emotion after recording, creating a labeled dataset for fine-tuning
- **Privacy-preserving**: On-device learning (Federated Learning) or opt-in data contribution
- **Cross-cultural validation**: Validate emotion expressions specific to Indonesian culture

### 12.4 Application Features

- **Male model deployment**: Add the already-trained male model for male users
- **Real-time feedback**: Expand live detection with more granular visualizations
- **Export & sharing**: Allow users to share reports with mental health professionals

---

## 13. Project Structure

```
fem_physicsmonitor/
├── lib/                              # Flutter application code
│   ├── main.dart                     # Entry point + routing
│   ├── l10n/app_localizations.dart   # Bilingual strings (600+ keys)
│   ├── models/
│   │   ├── emotion_model.dart        # EmotionType, TriggerTag, EmotionRecord
│   │   └── user_model.dart           # AppUser, MBTIQuestion, PsyQuestion, calculateMBTI
│   ├── providers/                    # State management (Provider pattern)
│   │   ├── auth_provider.dart
│   │   ├── theme_provider.dart
│   │   ├── locale_provider.dart
│   │   └── premium_provider.dart
│   ├── screens/                      # 15 screen files
│   │   ├── auth_screen.dart
│   │   ├── onboarding_screen.dart + onboarding/ (4 sub-screens)
│   │   ├── home_screen.dart
│   │   ├── live_detection_screen.dart
│   │   ├── emotion_detection_screen.dart
│   │   ├── result_screen.dart
│   │   ├── record_detail_screen.dart
│   │   ├── history_screen.dart
│   │   ├── premium_screen.dart
│   │   ├── profile_screen.dart
│   │   └── settings_screen.dart
│   ├── services/                     # 10 service files
│   │   ├── database_service.dart     # Firestore CRUD
│   │   ├── audio_recorder_detection.dart  # TFLite inference
│   │   ├── whisper_init_service.dart
│   │   ├── text_emotion_service.dart
│   │   ├── gemini_service.dart
│   │   ├── suggestion_service.dart
│   │   ├── subscription_service.dart # RevenueCat
│   │   ├── ad_service.dart           # AdMob
│   │   ├── storage_service.dart
│   │   └── config_service.dart
│   ├── theme/app_theme.dart
│   ├── utils/animations.dart
│   └── widgets/
│       ├── gradient_background.dart
│       └── suggestion_card.dart
├── assets/
│   ├── model/                        # Jupyter notebooks for training
│   │   ├── modeltrainingser.ipynb    # Main training notebook
│   │   ├── feature_extraction.ipynb  # Dataset preprocessing
│   │   └── convert.ipynb             # TFLite conversion
│   ├── final_female_model.tflite     # Deployed TFLite model (685 KB)
│   ├── emotion.json                  # Indonesian keywords (424)
│   ├── emotion_en.json               # English keywords (381)
│   ├── MBTI.json                     # 20 MBTI questions
│   ├── MBTI_en.json                  # English MBTI questions
│   ├── psych.json                    # 20 psych questions
│   ├── psych_en.json                 # English psych questions
│   ├── saran.json                    # 480 suggestions (ID)
│   ├── saran_en.json                 # 480 suggestions (EN)
│   └── bgimage/                      # Background images for UI
├── android/
│   ├── app/google-services.json      # Firebase configuration
│   └── gradle.properties              # Build configuration
├── firestore.rules                    # Security rules
├── firestore.indexes.json
├── firebase.json                     # Firebase Hosting config
├── pubspec.yaml
└── .env                              # Environment variables (gitignored)
```

---

## 14. References

### Datasets
- **RAVDESS**: Livingstone & Russo (2018). The Ryerson Audio-Visual Database of Emotional Speech and Song.
- **CREMA-D**: Cao et al. (2014). CREMA-D: Crowd-sourced Emotional Multimodal Actors Dataset.
- **TESS**: Pichora-Fuller & Dupuis (2020). Toronto Emotional Speech Set.
- **SAVEE**: Haq & Jackson (2010). Surrey Audio-Visual Expressed Emotion.
- **E-SERAVD**: Indonesian film-based emotional speech dataset.
- **IndoWaveSentiment**: Indonesian acted emotion speech dataset.

### Libraries & Frameworks
- **TensorFlow / Keras**: Model training and TFLite conversion
- **librosa**: Audio feature extraction (Python reference implementation)
- **scikit-learn**: SMOTE oversampling, class balancing
- **whisper_kit**: On-device Whisper STT (Flutter)
- **flutter_litert**: TFLite inference on mobile
- **RevenueCat**: In-app subscription management
- **Google AdMob**: Advertising
- **Firebase Auth / Firestore**: Authentication and data storage
- **Google Gemini API**: Score fusion (audio + text)

### Notebooks (in `assets/model/`)
| Notebook | Purpose |
|----------|---------|
| `feature_extraction.ipynb` | Loads raw audio, extracts 121-dim features, balances classes, saves `.npz` |
| `modeltrainingser.ipynb` | Builds and trains CNN-BiLSTM-Transformer, saves `.keras` model |
| `convert.ipynb` | Converts Keras model to TFLite with SELECT_TF_OPS support |

---

*Document prepared for academic reference and AI-assisted journal writing. For questions about the codebase or models, contact syahrulkustiawanalzayyan@gmail.com.*
