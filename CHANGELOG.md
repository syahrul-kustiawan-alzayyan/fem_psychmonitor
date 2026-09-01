# Changelog

## [2.2.1] - 2026-08-27

### 🐛 Perbaikan Bug
- **Premium Acknowledge** — Pembelian premium selalu di-acknowledge meskipun verifikasi server gagal (mencegah auto-refund Google dalam 3 hari).
- **Premium Expiry Auto-Revoke** — Status premium otomatis revoked jika sudah melewati masa berlaku.
- **Server Sync** — `refreshFromServer` me-revoke premium jika server mengembalikan status expired.
- **Expired UI** — Pengguna dengan premium expired tidak lagi melihat "Premium Aktif" di halaman Pengaturan.
- **Dialog Stuck** — Dialog "Data Belum Lengkap" bisa ditutup (bukan paksa isi onboarding).
- **Detection Limit** — Limit deteksi gratis per hari dijadikan konstanta `maxFreeDetections` (bukan hardcoded `5`).

### 📋 Kuesioner & Rekomendasi
- **Validasi Pakar** — 8 soal kuesioner Big Five disesuaikan berdasarkan validasi psikolog (Astrid Nur Alfaradais, M.Psi.).
- **Rekomendasi Diperbaiki** — 180+ rekomendasiBig Five ditinjau ulang: hapus redundansi, perjalan bahasa, sesuaikan konteks budaya Indonesia.

### 🌐 Lokalisasi
- Teks hardcoded di beberapa dialog & notifikasi diganti ke `AppLocalizations.tr()`.
- Channel notifikasi Android diubah ke Bahasa Inggris (ditampilkan di sistem Android).
- `TextEmotionService` hanya memuat file emosi sesuai locale aktif.

### 📝 Lainnya
- **Versi** — Update ke `2.2.1+10`.

## [2.2.0] - 2026-08-26

### 🎉 Open Testing Release

Pembukaan fase Open Testing untuk Fem-Psych Monitor.

### 🎨 Tampilan
- **Stat Card Redesign** — Kartu statistik (Rekaman, Positif, Perlu Perhatian, Sisa Deteksi) menggunakan grafis dekoratif organik (bunga, matahari tersenyum, hati dengan daun, timer berdaun) menggantikan ikon Phosphor.
- **Suggestion Card Redesign** — Kartu saran psikis dengan gradien halus, sudut membulat 20px, bayangan ganda lembut, dan grafis bunga di header untuk tampilan lebih empatik.
- **History Card Redesign** — Kartu riwayat dengan gradien aksen emosi pada border kiri, pola titik dekoratif, dan bayangan berwarna emosi.

### ⚙️ Perubahan Perilaku
- **Notifikasi Otomatis** — Notifikasi pengingat harian otomatis aktif saat pertama kali membuka aplikasi (tanpa toggle di Pengaturan).
- **Pengaturan Notifikasi Dihapus** — Menu notifikasi dihapus dari halaman Pengaturan karena notifikasi selalu aktif otomatis.

### 📝 Lainnya
- **Versi** — Update ke `2.2.0+9`.

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
