# Changelog

## [2.1.5] - 2026-08-06

### 🎨 Tampilan
- **Admin Dashboard Redesign** — Desain ulang dashboard admin dengan hero header gradien, kartu statistik, grafik distribusi emosi, status kesehatan mental, dan daftar pengguna.

### 🐛 Perbaikan Bug
- **Fix Relogin Admin** — Admin yang login kembali tidak lagi masuk ke halaman pengguna biasa; AppRouter memverifikasi `isAdmin` sebelum routing.
- **Fix Crash Stat Card** — Perbaikan `BoxConstraints forces an infinite height` pada kartu statistik dashboard admin.

### 📝 Lainnya
- **Versi** — Update ke `2.1.5+8`.

## [2.1.0] - 2026-07-23

### ✨ New Features
- **App Open Ad Cooldown** — Iklan open app dibatasi muncul setiap 3 jam sekali menggunakan SharedPreferences.
- **Privacy Policy & Terms of Service** — Halaman HTML baru `privacy-policy.html` (gabungan privacy + delete account) dan `terms-of-service.html` di root project.
- **Link Privacy & TOS di Login** — Halaman login menampilkan dua link terpisah: "Kebijakan Privasi" dan "Ketentuan Layanan" yang bisa diklik masing-masing.

### 🎨 Tampilan
- **Login Screen Modernisasi** — Desain ulang halaman login dengan:
  - Gradien pink dari atas ke bawah (light pink, Pink-50, lavender blush, off-white).
  - Komponen mengambang langsung di atas gradien tanpa card container.
  - Field input dengan gaya glass-morphism, shadow, dan border yang lebih halus.
  - Tombol "Masuk" dan Google reaktif terhadap status centang privasi.
  - Snackbar notifikasi jika tombol ditekan tanpa menyetujui privasi.
  - Tombol Google dengan outline biru (#4285F4) saat aktif, abu-abu saat nonaktif.

### 🐛 Perbaikan Bug
- **Fix Onboarding Bypass** — Pengguna yang login via Google dan menutup aplikasi saat onboarding tidak lagi langsung masuk ke MainNavigation. AppRouter sekarang memverifikasi data `bigFiveScores` di Firestore sebelum routing.
- **Defensive Check MainNavigation** — Menambahkan dialog peringatan jika data onboarding kosong, dengan redirect ke OnboardingScreen.
- **Fix Crash Model Transkrip** — Perbaikan crash pada model transkrip suara.

### 📝 Lainnya
- **Versi** — Update ke `2.1.0+7`.
- **Dependencies** — `flutter pub get` resolved tanpa error.
