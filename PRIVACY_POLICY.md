# Privacy Policy

**Last updated: June 12, 2026**

## 1. Introduction

Fem-Psych Monitor ("we," "our," or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application Fem-Psych Monitor (the "App").

Please read this policy carefully. By using the App, you consent to the practices described in this policy. If you do not agree, please discontinue use immediately.

**Developer Information:**
- Developer Name: Syahrul Kustiawan Al Zayyan, S.Kom
- Address: Indonesia
- Email: syahrulkustiawanalzayyan.com

## 2. Information We Collect

### 2.1 Information You Provide Directly

| Category | Data Collected | Purpose |
|----------|---------------|---------|
| **Account Information** | Name, email address, profile photo | Account creation and authentication via Firebase Authentication |
| **Google Sign-In Data** | Name, email address, profile photo (from Google account) | Optional social login |
| **MBTI Assessment** | Personality type, dimension scores (E/I, S/N, T/F, J/P) | Personalized psychological insights |
| **Mental Health Questionnaire** | Responses to psychological assessment questions | Mental health score calculation and recommendations |
| **Trigger Tags** | Self-selected emotional triggers (work, romance, finance, health, family, social, other) | Emotion tracking and trend analysis |

### 2.2 Information Collected Automatically

| Category | Data Collected | Purpose |
|----------|---------------|---------|
| **Voice Recordings** | Temporary audio recorded via device microphone | On-device speech-to-text transcription via whisper_kit |
| **Transcripts & Emotion Analysis** | Text transcripts, emotion scores, confidence levels | Emotion detection history and trends (stored in Firestore) |
| **Device Information** | Device model, OS version, app version, language preference | App functionality and analytics |
| **Advertising ID** | Android Advertising ID | Serving contextual ads via Google AdMob |
| **Usage Data** | Screen views, feature interactions, crash logs | App improvement via Firebase Analytics & Crashlytics |
| **Purchase Data** | Subscription status, purchase history | Premium entitlement management via RevenueCat |

**Important:** Raw audio recordings are processed exclusively on your device using the on-device Whisper model (whisper_kit). No raw audio files are transmitted to our servers or any third party.

### 2.3 Sensitive Data

We process the following categories of sensitive data based on your explicit consent:
- Voice recordings (for emotion analysis)
- Mental health assessment responses
- Emotion detection results

## 3. Legal Basis for Processing (GDPR)

If you are located in the European Economic Area (EEA) or the United Kingdom, our legal basis for processing your personal data is as follows:

| Processing Activity | Legal Basis |
|-------------------|-------------|
| Account creation and authentication | Performance of a contract (Art. 6(1)(b) GDPR) |
| Emotion analysis and transcription | Your explicit consent (Art. 9(2)(a) GDPR) |
| Personalized recommendations | Your explicit consent (Art. 9(2)(a) GDPR) |
| Ad serving | Legitimate interest (Art. 6(1)(f) GDPR) or consent where required |
| Subscription management | Performance of a contract (Art. 6(1)(b) GDPR) |
| Analytics and crash reporting | Legitimate interest (Art. 6(1)(f) GDPR) |
| Push notifications | Your consent (Art. 6(1)(a) GDPR) |

You have the right to withdraw consent at any time without affecting the lawfulness of processing based on consent before its withdrawal.

## 4. How We Use Your Information

- To create and manage your account
- To transcribe voice recordings and analyze emotional content
- To display historical emotion trends and insights
- To provide personalized psychological recommendations
- To manage premium subscription entitlements
- To serve relevant advertisements (non-premium users)
- To send service-related communications
- To analyze app usage and improve functionality
- To detect, prevent, and address technical issues and fraud

## 5. Third-Party Services and Data Sharing

We share your data with the following third-party service providers who process data on our behalf (data processors):

| Service Provider | Purpose | Data Shared | Processing Location | Privacy Policy |
|-----------------|---------|-------------|-------------------|----------------|
| **Google Firebase (Auth, Firestore, Analytics, Crashlytics)** | Authentication, cloud database, analytics, crash reporting | Account info, emotion records, transcripts, app usage, crash logs | United States, Belgium, Netherlands | [Firebase Privacy](https://firebase.google.com/support/privacy) |
| **Google AdMob** | In-app advertising | Advertising ID, device info, IP address | Varies | [AdMob Privacy](https://support.google.com/admob/answer/6128543) |
| **RevenueCat** | Subscription management | Purchase history, entitlement status, app user ID | United States | [RevenueCat Privacy](https://www.revenuecat.com/privacy/) |
| **Google Gemini AI** | AI-powered psychological suggestions | Emotion data, MBTI type (anonymized) | United States | [Google Privacy](https://policies.google.com/privacy) |
| **Google Sign-In** | Optional authentication | Name, email, profile photo | United States | [Google Privacy](https://policies.google.com/privacy) |

We do not sell your personal information to third parties. We do not share your data with third parties for their own marketing purposes.

## 6. International Data Transfers

Your personal data may be transferred to and processed in countries outside your country of residence, including the United States and the European Union. When transferring data from the EEA or UK, we ensure appropriate safeguards are in place, including:

- **Standard Contractual Clauses (SCCs)** adopted by the European Commission
- **Data Processing Agreements (DPAs)** with all sub-processors
- Compliance with the **EU-U.S. Data Privacy Framework** where applicable

## 7. Data Retention and Deletion

| Data Type | Retention Period |
|-----------|-----------------|
| Account information | Until account deletion |
| Emotion records and transcripts | Until account deletion |
| MBTI and assessment data | Until account deletion |
| Voice recordings (temporary) | Deleted immediately after transcription (on-device only) |
| Analytics data | 25 months (Firebase default) |
| Crash logs | 90 days |
| Purchase history | Retained as required by tax law (typically 5-7 years) |

**Account Deletion:** You can delete your account and all associated data at any time via:
- App: Settings → Delete Account & Data

Upon deletion, all personal data will be permanently removed from our servers within **30 days**. Some anonymized, aggregated data may be retained for analytical purposes.

## 8. Your Rights

### 8.1 General Rights (All Users)
- **Right to Access**: Request a copy of your personal data
- **Right to Rectification**: Correct inaccurate or incomplete data
- **Right to Erasure** ("Right to be Forgotten"): Request deletion of your data
- **Right to Data Portability**: Receive your data in a structured, machine-readable format
- **Right to Object**: Object to processing based on legitimate interests

### 8.2 GDPR Rights (EEA & UK Users)
- **Right to Restrict Processing**: Request restriction of data processing
- **Right to Withdraw Consent**: Withdraw consent at any time
- **Right to Lodge a Complaint**: File a complaint with your local data protection authority (e.g., Autoriteit Persoonsgegevens in the Netherlands, ICO in the UK)

**How to exercise your rights:** Contact us at [your-email@example.com]. We will respond within **30 days** as required by GDPR.

### 8.3 CCPA Rights (California Residents)
If you are a California resident, you have the following rights under the California Consumer Privacy Act (CCPA):

- **Right to Know**: Request disclosure of categories and specific pieces of personal information collected, used, or disclosed
- **Right to Delete**: Request deletion of personal information collected
- **Right to Opt-Out**: Opt out of the sale of personal information (note: we do not sell personal information)
- **Right to Non-Discrimination**: No discrimination for exercising CCPA rights

To exercise your CCPA rights, contact us at [your-email@example.com]. We will verify your identity before processing your request.

**Categories of personal information disclosed for a business purpose in the past 12 months:**
- Identifiers (name, email)
- Commercial information (purchase history)
- Internet/electronic activity (app usage)
- Audio/electronic data (transcripts)
- Inferences drawn from data (emotion analysis)

## 9. Data Security

We implement appropriate technical and organizational measures to protect your personal data, including:

- **Encryption at rest**: Firebase Firestore data is encrypted using AES-256
- **Encryption in transit**: All network communication uses TLS 1.2+
- **Access controls**: Firebase Security Rules restrict data access to authenticated users only
- **On-device processing**: Voice recordings never leave your device
- **Regular security reviews**: We monitor for vulnerabilities and apply patches promptly

While we strive to protect your data, no method of electronic storage or transmission is 100% secure. We cannot guarantee absolute security.

## 10. Children's Privacy

The App is not intended for children under **13 years of age** (or **16 in the EEA**). We do not knowingly collect personal information from children. If we learn that we have collected personal information from a child without parental consent, we will delete it promptly. If you believe a child has provided us with personal data, please contact us.

## 11. Automatic Renewal Subscriptions

Premium subscriptions are managed through RevenueCat and the respective app store (Google Play). Details:

- **Renewal**: Subscriptions automatically renew unless auto-renewal is turned off at least 24 hours before the end of the current period
- **Cancellation**: Manage subscriptions via Google Play Store → Subscriptions
- **Refunds**: Managed by Google Play Store according to their refund policies
- **Data collected**: RevenueCat receives and stores your purchase transaction ID and subscription status for entitlement verification

## 12. Cookies and Tracking Technologies

The App itself does not use cookies. However, third-party SDKs integrated into the App (Firebase, AdMob) may use mobile device identifiers and similar tracking technologies for analytics and advertising purposes. You can reset your Advertising ID at any time via your device settings.

## 13. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Changes will be posted within the App and/or via email notification. The "Last updated" date at the top of this policy will reflect the most recent revision. Material changes will be notified at least **30 days** before taking effect.

We encourage you to review this policy periodically.

## 14. Contact Us

For questions, concerns, or requests regarding this Privacy Policy or your data:

| Purpose | Contact |
|---------|---------|
| **General inquiries** | syahrulkustiawanalzayyan@gmail,com |
| **Data protection inquiries** | syahrulkustiawanalzayyan@gmail,com |
| **GDPR Data Protection Officer** | syahrulkustiawanalzayyan@gmail,com |
| **Physical address** | syahrulkustiawanalzayyan@gmail,com |

**Response time:** We will respond to all legitimate requests within **30 days**. If your request is complex or you have made multiple requests, it may take up to **60 days** — we will notify you if this applies.

### Data Protection Authority Contacts

- **EEA**: Your local data protection authority — [List of EU DPAs](https://edpb.europa.eu/about-edpb/about-edpb/members_en)
- **UK**: Information Commissioner's Office (ICO) — [ico.org.uk](https://ico.org.uk/)
- **Indonesia**: Kementerian Komunikasi dan Informatika — [kominfo.go.id](https://www.kominfo.go.id/)
