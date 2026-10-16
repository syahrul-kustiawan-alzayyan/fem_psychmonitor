# System Flow Diagram — Fem-Psych Monitor

Copy this Mermaid code into [Mermaid Live Editor](https://mermaid.live) or a Markdown renderer that supports Mermaid (GitHub, VS Code with extension, etc.) to generate the system flow diagram.

## Mermaid Code

```mermaid
graph TB
    %% ============ ONBOARDING FLOW ============
    subgraph Onboarding["📱 ONBOARDING & AUTH"]
        direction TB
        A1[App Launch] --> A2{Splash Screen}
        A2 -->|First Launch| A3[Welcome Section]
        A2 -->|Returning User| A5{Logged In?}
        
        A3 --> A4[MBTI Assessment<br/>20 questions<br/>E/I, S/N, T/F, J/P]
        A4 --> A6[Psychological<br/>Questionnaire<br/>20 questions, 5 categories]
        A6 --> A7[Onboarding Results<br/>MBTI Type + Mental Score]
        
        A7 --> A8[Auth Screen]
        
        subgraph Auth["🔐 AUTHENTICATION"]
            direction TB
            A8 --> A9{Choose Method}
            A9 -->|Register| A10[Create Account<br/>Email + Password]
            A9 -->|Login| A11[Sign In<br/>Email Verification Required]
            A9 -->|Google| A12[Google Sign-In<br/>OAuth 2.0]
            A10 --> A13[Verify Email<br/>Link via Email]
            A13 --> A11
            A12 -->|New User| A14[Auto-create Firebase Account]
            A14 --> A3
        end
        
        A11 -->|Success| A15{Firestore<br/>has MBTI data?}
        A15 -->|No| A4
        A15 -->|Yes| A17
        A12 -->|Existing User| A15
    end
    
    %% ============ MAIN APP ============
    subgraph MainApp["🏠 MAIN APPLICATION"]
        direction TB
        
        %% --- HOME ---
        subgraph Home["📊 BERANDA (HOME)"]
            direction TB
            H1[Home Dashboard] --> H2[Display:<br/>• Greeting<br/>• Psychic Status Card<br/>• 3 Mini Stats<br/>• Recent History (3 logs)<br/>• Personalized Suggestions]
        end
        
        %% --- DETECTION ---
        subgraph Detection["🎤 EMOTION DETECTION"]
            direction TB
            D1[Tap Mulai Rekam] --> D2[Live Detection Screen<br/>Pulse Animation<br/>Real-time Emotion Preview]
            D2 --> D3[Tap Record Button]
            D3 --> D4[Record Audio<br/>WAV 16kHz mono]
            D4 --> D5[Stop Recording]
            
            D5 --> D6[Feature Extraction<br/>40 MFCC + Δ + Δ² + ZCR<br/>= 121 features per frame]
            D6 --> D7[TFLite Inference<br/>CNN-BiLSTM-Transformer<br/>685KB model]
            D7 --> D8[Audio Scores<br/>6 emotions × confidence]
            
            D5 --> D9[Whisper STT<br/>base model, language: id]
            D9 --> D10[Transcribed Text]
            D10 --> D11[Text Emotion Analysis<br/>Keyword Matching<br/>ID: 424 + EN: 381 keywords]
            D11 --> D12[Text Scores<br/>6 emotions × confidence]
            
            D8 --> D13[Gemini Score Fusion<br/>Audio × 0.6 + Text × 0.4]
            D12 --> D13
            D13 --> D14[Combined Scores<br/>+ Emotion Trend Score<br/>emotionValue × confidence]
        end
        
        %% --- RESULT ---
        subgraph Result["📋 RESULT & SAVE"]
            direction TB
            R1[Result Screen] --> R2[Display:<br/>• Dominant Emotion<br/>• Audio vs Text Chart<br/>• Trend Score<br/>• Trigger Tags (wajib pilih)<br/>• Personalized Suggestions]
            R2 --> R3{Select Trigger Tag}
            R3 -->|work / romance / finance<br/>health / family / social / other| R4[Tap Simpan]
            R4 --> R5[Save to Firestore<br/>users/{uid}/recordings/{id}]
            R5 --> R6[Navigate to Home / History]
        end
        
        %% --- HISTORY ---
        subgraph History["📈 HISTORY & ANALYTICS"]
            direction TB
            S1[History Screen] --> S2[Time Filter:<br/>All / Today / 7D / 30D / Custom]
            S2 --> S3[Line Chart<br/>Emotion Trend -10 to +11]
            S2 --> S4[Emotion Log List<br/>Infinite Scroll]
            S4 --> S5[Tap Log → Detail<br/>View transcript, scores,<br/>trigger tag, suggestions]
            S4 --> S6[Delete Recording]
        end
        
        A17 --> H1
        H1 --> D1
        R6 --> H1
        R6 --> S1
    end
    
    %% ============ MENTAL SCORE ============
    subgraph MentalScore["💚 MENTAL SCORE IMPACT"]
        direction TB
        M1[Recording Saved] --> M2[Update Mental Score<br/>Calculated from:<br/>• MBTI Type<br/>• Psych Questionnaire Score<br/>• Emotion Trend History]
        M2 --> M3[Home Dashboard Update<br/>Psychic Status Card<br/>Mini Stats Refresh]
        M2 --> M4[Trend Chart Update<br/>New data point<br/>on history graph]
        M2 --> M5[Personalized Suggestions<br/>MBTI × Emotion Matrix<br/>480 unique recommendations]
        
        M3 -.->|over time| M6[Pattern Recognition<br/>Identify weekly/monthly<br/>emotional patterns]
    end
    
    %% ============ FIRESTORE ============
    subgraph Firestore["☁️ CLOUD FIRESTORE"]
        direction TB
        F1[users/{uid}] --- F2[Profil:<br/>name, email,<br/>mbti_type, psych_score]
        F1 --- F3[recordings/{id}:<br/>date, dominant_emotion,<br/>confidence, scores<br/>transcript, trigger_tag]
        F3 --- F4[snapshots/{id}:<br/>emotion, confidence,<br/>source, timestamp]
    end
    
    %% ============ LINKS ============
    R5 --> F3
    D8 -.->|Continuous 3s<br/>frames during<br/>recording| F4
    S5 -.-> F3
    S6 -.-> F3
    A10 --> F1
    A12 --> F1
```

## Flow Description

The system operates in three main phases:

### Phase 1: Onboarding & Authentication
1. New user completes **MBTI assessment** (20 forced-choice questions) to determine personality type
2. User completes **Psychological questionnaire** (20 Likert-scale questions across 5 categories)
3. Results are temporarily stored; user must create an account or log in
4. On successful authentication, onboarding data is saved to Firestore

### Phase 2: Emotion Detection Pipeline
1. User records audio (WAV, 16kHz mono) via the voice detection screen
2. Two parallel processes run:
   - **Audio path**: Audio is preprocessed (pre-emphasis → framing → STFT → MFCC extraction), then passed to a TFLite CNN-BiLSTM-Transformer model for emotion classification
   - **Text path**: Audio is transcribed via Whisper STT (base model, language auto-detect), then analyzed using bilingual keyword matching (805 total keywords across 6 emotions)
3. Scores are fused: **Audio 60% + Text 40%** via Gemini AI

### Phase 3: Results & Mental Score Tracking
1. Combined scores are displayed with visual bar charts, trend scores, and trigger tag selection
2. Data is saved to Firestore with mandatory trigger tag (work/romance/finance/health/family/social/other)
3. Mental health dashboard updates with new statistics
4. History charts show longitudinal emotional trends

## Quick Links

- **Render Online**: [Mermaid Live Editor](https://mermaid.live)
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
- **GitHub**: Mermaid renders automatically in `.md` files
