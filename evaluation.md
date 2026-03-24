# Evaluation Notes — Fem-PhysicsMonitor

Catatan perubahan, perbaikan, dan pelajaran selama pengembangan UI Flutter.

---

## Sesi 1 — 14 Maret 2026

### ✅ Yang Berhasil
- Struktur proyek modular: `lib/theme/`, `lib/models/`, `lib/screens/`, `lib/widgets/`
- Material 3 dengan `ColorScheme.fromSeed()` + font Nunito via `google_fonts`
- 3 screen lengkap (Home, Voice Detection, History) + navigasi `BottomNavigationBar` 
  dengan `IndexedStack` agar state tiap screen terjaga
- Bar chart menggunakan `fl_chart ^0.70.2` berjalan baik

### ⚠️ Kesalahan & Perbaikan

| # | Kesalahan | Penyebab | Solusi |
|---|-----------|----------|--------|
| 1 | `CardTheme` tidak bisa di-assign ke `CardThemeData?` | Flutter versi baru mengganti `CardTheme` → `CardThemeData` di `ThemeData` | Ganti ke `CardThemeData(...)` |
| 2 | Unused import `emotion_badge.dart` di `home_screen.dart` | Import ditambahkan tapi widget tidak dipakai langsung di file itu | Hapus import yang tidak terpakai |
| 3 | Unused import `emotion_badge.dart` di `history_screen.dart` | Sama seperti di atas | Hapus import |
| 4 | `withOpacity()` deprecated (Flutter ≥ 3.18) | Flutter terbaru mengganti `.withOpacity(x)` → `.withValues(alpha: x)` | PowerShell mass-replace regex di seluruh `lib/` |
| 5 | `background` property deprecated di `ColorScheme` | Dihapus setelah v3.18, gunakan `surface` | Hapus parameter `background:` |
| 6 | `widget_test.dart` referensi `MyApp` yang sudah tidak ada | `main.dart` lama diganti total, class `MyApp` sudah hilang | Update test dengan `FemPhysicsMonitorApp` |
| 7 | Penghapusan import yang berlebihan (bug tool) | Saat menghapus unused import, `app_theme.dart` ikut terhapus | Restore import `app_theme` secara manual |
| 8 | String concatenation `+` di `emotion_badge.dart` | Lint `prefer_interpolation_to_compose_strings` | Ganti ke string interpolation `'${...} ${...}'` |

### 🔑 Pelajaran untuk Sesi Berikutnya
1. **Selalu gunakan `.withValues(alpha: x)`** bukan `.withOpacity(x)` di Flutter ≥ 3.18
2. **Gunakan `CardThemeData`** bukan `CardTheme` sebagai parameter `cardTheme` di `ThemeData`
3. **Hapus import satu per satu secara spesifik**, jangan hapus baris import dalam range yang bisa mengenai import lain
4. **Update `widget_test.dart`** setiap kali `main.dart` direfaktor (class root berubah)
5. **PowerShell regex replace** sangat efisien untuk mass-replace deprecated API

---

## Versi File (Sesi 1)

| File | Status |
|------|--------|
| `lib/main.dart` | ✅ Ditulis ulang |
| `lib/theme/app_theme.dart` | ✅ Baru |
| `lib/models/emotion_model.dart` | ✅ Baru |
| `lib/widgets/emotion_badge.dart` | ✅ Baru |
| `lib/screens/home_screen.dart` | ✅ Baru |
| `lib/screens/voice_detection_screen.dart` | ✅ Baru |
| `lib/screens/history_screen.dart` | ✅ Baru |
| `test/widget_test.dart` | ✅ Diupdate |
| `pubspec.yaml` | ✅ Ditambah `fl_chart`, `google_fonts` |

**Hasil akhir:** `flutter analyze` → **No issues found!**

---

## Sesi 2 — 14 Maret 2026

### ✅ Fitur Baru yang Diimplementasikan
- **Onboarding** — 13 halaman bertahap (welcome → nama → 10 soal psikis → hasil & saran awal), disimpan via `SharedPreferences`
- **Saran per-rekaman** — `SuggestionCard` collapsible muncul di Voice Detection setelah setiap hasil emosi
- **Saran psikis keseluruhan** — Kartu rekomendasi di Home berdasarkan `PsychLevel` dari skor assessment + emosi dominan 7 hari
- **Sapaan personal** — Nama user + inisial avatar + sapaan waktu (pagi/siang/sore/malam)

### ⚠️ Kesalahan & Perbaikan Sesi 2

| # | Kesalahan | Penyebab | Solusi |
|---|-----------|----------|--------|
| 1 | `unnecessary_underscores` di `PageRouteBuilder` | Dart melarang `_`, `__`, `___` sebagai parameter tidak terpakai | Ganti ke nama bermakna `context`, `a1`, `a2` |
| 2 | `dangling_library_doc_comments` di `user_model.dart` | Komentar `///` di baris paling atas file dianggap doc comment library yang menggantung | Ganti `///` ke `//` biasa |
| 3 | `unnecessary_brace_in_string_interps` | `'${_currentPage}'` bisa disingkat `'$_currentPage'` | Hapus kurung kurawal yang tidak perlu |
| 4 | `curly_braces_in_flow_control_structures` | `if ... level = x` tanpa kurung kurawal | Tambahkan `{}` di tiap cabang if-else |

### 🔑 Pelajaran Sesi 2
1. **PageRouteBuilder parameters**: Gunakan nama variabel yang valid (`a1`, `a2`) bukan underscores berulang
2. **Doc comments `///`** di baris pertama file = library doc comment → gunakan `//` biasa untuk komentar file
3. **String interpolation**: Variabel sederhana (tanpa titik/ekspresi) tidak memerlukan `${}`
4. **Selalu beri `{}` pada if-else chain** meski satu statement — Flutter analyzer strict di sini

### 🗂️ File Baru Sesi 2

| File | Deskripsi |
|------|-----------|
| `lib/models/user_model.dart` | `AppUser`, `PsychLevel` (4 level + saran), 10 `PsychQuestion` |
| `lib/services/storage_service.dart` | SharedPreferences wrapper |
| `lib/screens/onboarding_screen.dart` | 13-step onboarding flow |
| `lib/widgets/suggestion_card.dart` | Collapsible & static suggestion card |

**Hasil akhir Sesi 2:** `flutter analyze` → **No issues found!**

---

## Sesi 3 — 14 Maret 2026

### ✅ Yang Diimplementasikan: Premium UI Redesign Total

Refaktor visual menyeluruh pada 7 file — tidak ada perubahan logika atau API, murni UI/UX.

#### Perubahan per File

| File | Perubahan Utama |
|------|-----------------|
| `lib/theme/app_theme.dart` | Font Nunito → **Poppins**, Primary Teal → **Sage Green `#6BAE8A`**, Background → `#F8FAFC`, tambah design tokens (spacing, radius, shadow, gradient) |
| `lib/main.dart` | Bottom nav diganti **floating pill-shaped** dengan `extendBody: true`, animated top-line indicator, `AnimatedSwitcher` per ikon/label |
| `lib/screens/home_screen.dart` | Header dengan tanggal + emoji waktu, gradient psych card + decorative circles, CTA button triple-ring animated pulse, quick stats row, left-border accent pada history items |
| `lib/screens/voice_detection_screen.dart` | Waveform mirrored top/bottom (bars simetris), 3 concentric pulse rings pada mic button, REC badge, `FadeTransition` pada hasil, `CircularProgressIndicator` sebagai confidence ring |
| `lib/screens/history_screen.dart` | `LineChart` fl_chart (area fill, smooth curves, dot berwarna per emosi), emotion breakdown pill bars, animated filter chips, log list dengan left-border accent |
| `lib/widgets/emotion_badge.dart` | `EmotionResultCard` dengan gradient background, decorative blobs, circular confidence ring, accuracy badge |
| `lib/widgets/suggestion_card.dart` | Gradient header strip, arsitektur bersih (`_StaticCard`, `_CollapsibleCard`, `_CardHeader`, `_SuggestionItem`), `AnimatedCrossFade` + `AnimatedRotation` |

#### Penyesuaian Tambahan (Sesi 3b)

- **Chart diubah dari "Per Hari" → "Per Rekaman"**: X-axis = `#1, #2, ... #N` (urutan sesi dari terlama ke terbaru), Y-axis = confidence 0–100%, setiap titik/dot diwarnai sesuai emosi yang terdeteksi pada rekaman tersebut, tooltip menampilkan emoji + nama emosi + confidence%.
- Label section header diperbarui: "Tren Emosi Mingguan" → **"Tren Confidence per Rekaman"**, subtitle → "Tiap titik = satu sesi rekaman (terlama → terbaru)".

### ⚠️ Catatan Teknis Sesi 3

| # | Hal | Detail |
|---|-----|--------|
| 1 | `extendBody: true` di `Scaffold` | Diperlukan agar konten scrollable di belakang floating bottom nav; perlu tambah `SizedBox(height: 100)` di akhir setiap screen |
| 2 | `List<EmotionRecord>.from(...)..sort(...)` | Pattern spread-sort untuk tidak mutate list asli di `DummyData` |
| 3 | `FlDotCirclePainter` berwarna per-index | `getDotPainter` menerima `idx` yang bisa dipakai untuk index ke list warna emosi |
| 4 | `getTooltipColor` pada `LineTouchTooltipData` | Menerima `LineBarSpot` bukan `FlSpot`, harus menggunakan `spot.x.toInt()` untuk index ke data |
| 5 | Unused import `dart:math` | Dihapus setelah kode yang membutuhkannya dihapus; `flutter analyze` mendeteksi ini |

### 🔑 Pelajaran Sesi 3

1. **Chart data harus mencerminkan flow nyata aplikasi** — "per rekaman" lebih akurat dari "per hari" untuk deteksi emosi berbasis suara
2. **Design tokens di `AppTheme`** (spacing, radius, shadow) sangat mengurangi hardcoded values dan membuat refaktor lebih mudah
3. **`extendBody: true`** + `SafeArea(bottom: false)` adalah pola standar untuk floating nav bar — jangan lupa bottom padding di setiap screen
4. **`AnimatedSwitcher` untuk ganti ikon** lebih premium dibanding langsung swap icon
5. **Tooltip fl_chart**: `getTooltipColor` menerima `LineBarSpot` (bukan `FlSpot`) yang memiliki property `.x` untuk referensi ke data asli

### 🗂️ File yang Dimodifikasi Sesi 3

| File | Status |
|------|--------|
| `lib/theme/app_theme.dart` | ✅ Ditulis ulang total |
| `lib/main.dart` | ✅ Ditulis ulang total |
| `lib/screens/home_screen.dart` | ✅ Ditulis ulang total |
| `lib/screens/voice_detection_screen.dart` | ✅ Ditulis ulang total |
| `lib/screens/history_screen.dart` | ✅ Ditulis ulang + chart per-rekaman |
| `lib/widgets/emotion_badge.dart` | ✅ Ditulis ulang total |
| `lib/widgets/suggestion_card.dart` | ✅ Ditulis ulang total |

**Hasil akhir Sesi 3:** `flutter analyze` → **No issues found!**
