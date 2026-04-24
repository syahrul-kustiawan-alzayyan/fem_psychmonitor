# Onboarding Screen Redesign & Content Enhancement

## Goal

To revamp the Onboarding UI to feel more **modern and professional**. Additionally, we will update the "Info Page" so it focuses on providing deeper, separate insights about **MBTI** and **Mental Health**, instead of merely comparing the two ("MBTI vs Mental Health").

## Proposed Changes

### `lib/screens/onboarding_screen.dart`

We will overhaul the UI layouts for the welcome sequence and the info screens.

#### [MODIFY] `onboarding_screen.dart`
- **`_buildWelcomePage()`**:
  - Restructure the layout to use a hero-style header with a large, beautifully rendered app logo and subtle background decorative elements.
  - Apply clean and modern typography (using the existing `GoogleFonts.poppins` but with better hierarchy).
  - Use glassmorphism or sleek, rounded-corner containers with lighter shadows.
  - Add motivational, professionally phrased welcome copies.

- **`_buildInfoPage()`**:
  - Change the header from "MBTI vs Kesehatan Mental" to a unified, professional title like **"Mengenal Potensi & Mental Anda"**.
  - Expand the **MBTI** information to briefly explain its foundation (e.g., Carl Jung's psychological types) and how it maps out 16 distinct personality facets, providing value to the user beyond just "it's not a medical tool".
  - Expand the **Kesehatan Mental (Mental Health)** information to emphasize emotional tracking, self-awareness, and well-being strategies.
  - Implement a cleaner card UI layout with clear icons, better line heights, and bullet points.
  - Re-style the crucial disclaimer (not a medical diagnostic tool) visually so it looks like an important note but not an alarming error.

### `lib/l10n/app_localizations.dart` (if necessary)

#### [MODIFY] `app_localizations.dart`
- Update existing or add new default localization strings for the new UI texts such as title headers if they don't yet exist. (Although for the Indonesian specific copies, we can add inline texts inside the component or add fallback English mappings).

## Open Questions

- Should we apply an animation library (such as AnimeJS equivalent for Flutter, or standard Flutter animation) into the Welcome Screen, or keep the initial load focused strictly on clean typography and layout? Flutter's built-in `AnimatedContainer` or `FadeIn` could be applied.
- Are there specific color schemes or branding (other than current primary/secondary colors) you want applied to the new info sections?

## Verification Plan

### Manual Verification
- Hot restart the app to clear out the navigation stack.
- View the new Welcome Page directly inside the Onboarding flow.
- Ensure the Info Page clearly describes MBTI and Mental Health as requested.
- Check layout responsiveness on the Android emulator.
