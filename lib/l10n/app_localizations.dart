// Sistem lokalisasi sederhana — map string manual untuk Bahasa Indonesia & Inggris.
// Tidak menggunakan package intl/flutter_localizations agar ringan.

class AppLocalizations {
  static String _currentLocale = 'id';

  static String get currentLocale => _currentLocale;

  /// Getter shorthand untuk locale (digunakan oleh services dan screens)
  static String get locale => _currentLocale;

  static void setLocale(String locale) {
    _currentLocale = locale;
  }

  /// Ambil terjemahan berdasarkan key
  static String tr(String key) {
    return _strings[_currentLocale]?[key] ?? _strings['id']?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _strings = {
    // ════════════════════════════════════════════
    // Bahasa Indonesia
    // ════════════════════════════════════════════
    'id': {
      // ── Umum ──
      'app_name': 'Fem-Psych Monitor',
      'app_subtitle': 'Monitoring Psikologis Cerdas',
      'splash_subtitle': 'Pantau Kesehatan Mentalmu',
      'cancel': 'Batal',
      'save': 'Simpan',
      'ok': 'OK',
      'yes': 'Ya',
      'no': 'Tidak',
      'close': 'Tutup',
      'done': 'Selesai',
      'back': 'Kembali',
      'edit': 'Edit',
      'delete': 'Hapus',
      'loading': 'Memuat...',

      // ── Bottom Nav ──
      'nav_home': 'Beranda',
      'nav_record': 'Rekam',
      'nav_history': 'Riwayat',

      // ── Home Screen ──
      'greeting_morning': 'Selamat Pagi',
      'greeting_afternoon': 'Selamat Siang',
      'greeting_evening': 'Selamat Sore',
      'greeting_night': 'Selamat Malam',
      'how_are_you': 'Bagaimana perasaanmu hari ini?',
      'psych_status_today': 'Kondisi Psikis Hari Ini',
      'detection_confidence': 'Kepercayaan Deteksi',
      'last_detection': 'Deteksi terakhir',
      'recordings': 'Rekaman',
      'positive': 'Positif',
      'attention': 'Perhatian',
      'start_recording': 'Mulai Rekam',
      'detect_emotion_ai': 'Deteksi emosimu sekarang dengan AI',
      'realtime': '⚡ Real-time',
      'private': '🔒 Privat',
      'six_emotions': '🧠 6 Emosi',
      'psych_recommendation': 'Rekomendasi Psikis',
      'dominant_emotion': 'Emosi Dominan',
      'dominant_emotion_7d': 'Emosi dominan 7 hari ini',
      'suggestion_for': 'Saran untuk Kondisi',
      'start_recording_desc': 'Deteksi emosimu sekarang dengan AI',
      'recent_detection': 'Deteksi Terbaru',
      'recent_detections': 'Deteksi Terbaru',
      'view_all': 'Lihat Semua →',
      'see_all': 'Lihat Semua →',

      // ── Voice Detection ──
      'voice_detection': 'Deteksi Suara',
      'recording': 'Sedang Merekam...',
      'detection_done': 'Deteksi Selesai! ✓',
      'press_to_record': 'Tekan untuk Mulai Merekam',
      'detection_result': 'Hasil Deteksi',
      'all_emotion_dist': 'Distribusi Semua Emosi',
      'psych_message': 'Pesan Psikologis',
      'suggestion_for_emotion': 'Saran untuk',
      'how_to_use': 'Cara Penggunaan',
      'step_1': 'Tekan tombol mikrofon di atas',
      'step_2': 'Ucapkan beberapa kalimat dengan natural',
      'step_3': 'Tekan lagi untuk berhenti dan lihat hasil',
      'guide_step_1': 'Tekan tombol mikrofon di atas',
      'guide_step_2': 'Ucapkan beberapa kalimat dengan natural',
      'guide_step_3': 'Tekan lagi untuk berhenti dan lihat hasil',

      // ── History ──
      'history_title': 'Riwayat',
      'confidence_trend': 'Tren Confidence per Rekaman',
      'confidence_trend_sub':
          'Tiap titik = satu sesi rekaman (terlama → terbaru)',
      'emotion_breakdown': 'Sebaran Emosi',
      'detection_log': 'Log Deteksi',
      'confidence': 'Confidence',
      'all_filter': 'Semua',
      'filter_date': 'Filter Tanggal',
      'emotion_value_trend': 'Tren Nilai Emosi',
      'emotion_score_over_time': 'Perkembangan skor emosi dari waktu ke waktu',
      'mental_score_trend': 'Tren Skor Mental',
      'mental_score_over_time': 'Perubahan skor mental dari waktu ke waktu',
      'entries_count': '{count} entri',
      'see_more_count': 'Lihat {count} lainnya',
      'total': 'Total',
      'no_emotion_data': 'Belum ada data emosi',
      'average_score_label': 'Rata-rata: {score}',
      'sessions_count': '{count} sesi',
      'chart_tooltip_format': '{emoji} {name}\nSkor: {score} • {confidence}',
      'search_emotion_hint': 'Cari emosi...',
      'sort_newest': 'Terbaru',
      'sort_oldest': 'Terlama',
      'results_count': '{count} hasil',
      'no_data_found': 'Tidak ada data ditemukan',

      // ── Profile Menu ──
      'profile': 'Profil',
      'profile_menu': 'Profil',
      'settings': 'Pengaturan',
      'settings_menu': 'Pengaturan',
      'login_signup': 'Login / Sign Up',

      // ── Recording Prompts ──
      'recording_prompt_title': 'Mulai dengan bercerita...',
      'recording_prompt_1': 'Ceritakan tentang harimu hari ini...',
      'recording_prompt_2': 'Apa yang membuatmu bahagia belakangan ini?',
      'recording_prompt_3': 'Apakah ada sesuatu yang mengganggu pikiranmu?',
      'recording_prompt_4': 'Bagaimana perasaanmu saat ini?',
      'recording_prompt_5': 'Ceritakan hal yang kamu syukuri hari ini.',
      'recording_prompt_6': 'Apa yang ingin kamu capai minggu ini?',
      'recording_prompt_7': 'Siapa yang membuatmu tersenyum hari ini?',
      'recording_prompt_8': 'Bagaimana kualitas tidurmu semalam?',

      // ── Time Filter ──
      'filter_all_time': 'Semua',
      'filter_today': 'Hari Ini',
      'filter_7_days': '7 Hari',
      'filter_30_days': '30 Hari',
      'filter_custom': 'Custom',
      'filter_select_range': 'Pilih Rentang Tanggal',

      // ── Profile Screen ──
      'profile_title': 'Profil Saya',
      'profile_photo': 'Foto Profil',
      'tap_to_change_photo': 'Ketuk untuk mengubah foto',
      'username': 'Nama Pengguna',
      'email': 'Email',
      'save_profile': 'Simpan Perubahan',
      'profile_saved': 'Profil berhasil disimpan!',
      'member_since': 'Anggota sejak',

      // ── Settings Screen ──
      'settings_title': 'Pengaturan',
      'language': 'Bahasa',
      'language_id': 'Bahasa Indonesia',
      'language_en': 'English',
      'theme_mode': 'Tema Tampilan',
      'theme_light': 'Terang',
      'theme_dark': 'Gelap',
      'app_guide': 'Panduan Aplikasi',
      'app_guide_desc': 'Pelajari cara menggunakan aplikasi ini',
      'terms_services': 'Syarat & Ketentuan',
      'terms_desc': 'Baca syarat penggunaan aplikasi',
      'license': 'Lisensi',
      'license_desc': 'Lisensi open-source yang digunakan',
      'logout': 'Keluar',
      'logout_confirm': 'Apakah kamu yakin ingin keluar?',
      'logout_confirm_desc':
          'Kamu perlu login kembali untuk menggunakan fitur rekaman.',
      'general': 'Umum',
      'about': 'Tentang',
      'account': 'Akun',
      'notifications': 'Notifikasi',
      'routine_reminder': 'Pengingat Rutin',
      'routine_reminder_desc': 'Ingatkan deteksi emosi setiap 3 jam sekali',
      'reminder_time': 'Waktu Mulai',
      'reminder_disabled': 'Nonaktif',
      'reminder_notification_title': 'Pengingat Fem-Psych Monitor',
      'reminder_notification_body':
          'Halo, saatnya mengecek perasaanmu hari ini. Rekam beberapa kalimat untuk melihat kondisi psikismu.',
      'notification_permission_denied':
          'Izin notifikasi ditolak. Aktifkan dari pengaturan perangkat.',
      'reminder_scheduled': 'Pengingat rutin diaktifkan (setiap 3 jam)',
      'reminder_cancelled': 'Pengingat rutin dinonaktifkan',

      // ── Auth Screen ──
      'login': 'Masuk',
      'register': 'Daftar',
      'login_title': 'Selamat Datang Kembali',
      'login_subtitle': 'Masuk untuk memantau kesehatan psikismu',
      'register_title': 'Buat Akun Baru',
      'register_subtitle': 'Daftar untuk memulai perjalanan kesehatan psikismu',
      'email_hint': 'nama@contoh.com',
      'password_hint': 'Kata sandi',
      'confirm_password': 'Konfirmasi Kata Sandi',
      'username_hint': 'Nama lengkap',
      'forgot_password': 'Lupa kata sandi?',
      'or_continue_with': 'atau lanjutkan dengan',
      'google_signin': 'Masuk dengan Google',
      'no_account': 'Belum punya akun?',
      'has_account': 'Sudah punya akun?',
      'login_required': 'Login Diperlukan',
      'login_required_desc':
          'Silakan login terlebih dahulu untuk menggunakan fitur rekaman suara.',
      'login_now': 'Masuk Sekarang',
      'privacy_agree': 'Saya telah membaca dan menyetujui',
      'privacy_agree_prefix': 'Saya menyetujui ',
      'privacy_agree_connector': ' dan ',
      'privacy_link': 'Kebijakan Privasi',
      'auth_pass_required': 'Password wajib diisi',
      'auth_email_required': 'Email wajib diisi',
      'auth_email_invalid_format': 'Format email tidak valid',
      'auth_pass_min_length': 'Minimal 6 karakter',
      'auth_confirm_required': 'Konfirmasi password wajib diisi',
      'auth_pass_mismatch': 'Password tidak cocok',
      'auth_invalid_email_first': 'Masukkan email yang valid terlebih dahulu',
      'auth_already_verified': 'Sudah Verifikasi? Masuk',
      'auth_email_exists_title': 'Email Sudah Terdaftar',
      'auth_email_exists_desc':
          'Email {email} sudah memiliki akun. Password yang Anda masukkan tidak cocok.',
      'auth_reset_sent': 'Email reset password terkirim!',
      'auth_reset_failed': 'Gagal mengirim email reset password',
      'auth_reset_button': 'Kirim Reset Password',
      'try_again': 'Coba Lagi',
      'auth_google_account_title': 'Akun Terdaftar dengan Google',
      'auth_google_account_desc':
          'Email ini sudah terdaftar menggunakan Google. Silakan masuk dengan tombol Google di bawah.',
      'auth_err_email_in_use':
          'Email ini sudah memiliki akun. Silakan masuk dengan password yang benar.',
      'auth_err_wrong_password_title': 'Password Salah',
      'auth_err_wrong_password':
          'Password yang Anda masukkan salah. Silakan coba lagi.',
      'auth_err_invalid_email_title': 'Email Tidak Valid',
      'auth_err_invalid_email': 'Format email yang Anda masukkan tidak valid.',
      'auth_err_too_many_title': 'Terlalu Banyak Percobaan',
      'auth_err_too_many':
          'Terlalu banyak percobaan login. Silakan tunggu beberapa saat.',
      'auth_err_network_title': 'Koneksi Gagal',
      'auth_err_network':
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      'auth_err_invalid_credential_title': 'Email/Password Salah',
      'auth_err_invalid_credential':
          'Email atau password yang Anda masukkan salah. Silakan coba lagi.',
      'auth_err_generic_title': 'Masuk Gagal',
      'auth_err_generic': 'Terjadi kesalahan. Silakan coba lagi nanti.',
      'auth_has_password_desc':
          'Email ini sudah terdaftar menggunakan password. Silakan login menggunakan email dan password, bukan Google.',
      'auth_login_with_password': 'Login dengan Password',
      'auth_email_label': 'Email',
      'password_label': 'Kata sandi',
      'auth_privacy_required': 'Centang kebijakan privasi terlebih dahulu',
      'auth_email_verif_note':
          'Verifikasi email akan diperlukan sebelum akun bisa digunakan.',
      'verif_gmail_hint': 'Cek inbox atau folder Promosi / Sosial',
      'verif_yahoo_hint': 'Cek inbox atau folder Bulk / Spam',
      'verif_outlook_hint': 'Cek inbox atau folder Junk Email',
      'verif_other_hint': 'Cek inbox dan folder spam',
      'verification_step': 'Verifikasi',
      'verif_account_created': 'Akun Baru Berhasil Dibuat!',
      'verif_email_sent_to': 'Email verifikasi telah dikirim ke:',
      'verif_click_link':
          'Klik link di email untuk verifikasi, lalu kembali ke aplikasi.',
      'verif_resend_sent': 'Email verifikasi terkirim',
      'verif_resend_countdown': 'Kirim Ulang ({count})',
      'verif_resend_button': 'Kirim Email Verifikasi',
      'verif_success_title': 'Verifikasi Berhasil!',
      'verif_success_desc': 'Email Anda telah terverifikasi. Mengalihkan...',
      'verif_processing': 'Memproses masuk...',
      'setpass_title': 'Buat Password',
      'auth_onboarding_title': 'Lengkapi Data Diri',
      'auth_onboarding_desc':
          'Sebelum menggunakan aplikasi, Anda perlu mengisi kuesioner psikis terlebih dahulu. Data ini akan membantu kami memberikan rekomendasi yang sesuai dengan kondisi Anda.',
      'auth_onboarding_start': 'Mulai Sekarang',
      'setpass_desc':
          'Buat password untuk akun Google Anda agar bisa login juga menggunakan email dan password.',
      'setpass_failed': 'Gagal menyimpan password. Coba lagi.',
      'setpass_button': 'Simpan Password',
      'bigfive_dominant': 'Dimensi Dominan',

      // ── App Guide ──
      'guide_title': 'Panduan Aplikasi',
      'guide_step1_title': 'Rekam Suaramu',
      'guide_step1_desc':
          'Tekan tombol mikrofon dan ucapkan beberapa kalimat. AI akan menganalisis emosi dari nada suaramu.',
      'guide_step2_title': 'Lihat Hasil Deteksi',
      'guide_step2_desc':
          'Setelah rekaman selesai, kamu akan melihat emosi dominan beserta tingkat kepercayaannya.',
      'guide_step3_title': 'Pantau Riwayatmu',
      'guide_step3_desc':
          'Kunjungi halaman Riwayat untuk melihat tren emosi dan perkembangan psikismu dari waktu ke waktu.',
      'guide_step4_title': 'Baca Saran Psikologis',
      'guide_step4_desc':
          'Setiap deteksi disertai saran psikologis yang relevan untuk membantumu mengelola emosi.',

      // ── Terms ──
      'terms_title': 'Syarat & Ketentuan',
      'terms_content':
          'Fem-PhysicsMonitor adalah aplikasi pemantau kesehatan psikis '
          'berbasis analisis suara. Aplikasi ini bersifat edukatif dan tidak '
          'menggantikan konsultasi dengan profesional kesehatan jiwa.\n\n'
          '1. Data suara hanya digunakan untuk analisis emosi lokal dan tidak '
          'dikirim ke server pihak ketiga.\n\n'
          '2. Hasil deteksi emosi bersifat estimasi dan tidak boleh dijadikan '
          'dasar diagnosis medis.\n\n'
          '3. Pengguna bertanggung jawab atas penggunaan aplikasi sesuai ketentuan.\n\n'
          '4. Pengembang tidak bertanggung jawab atas keputusan yang diambil '
          'berdasarkan hasil analisis aplikasi.',

      // ── Privacy Policy ──
      'privacy_policy': 'Kebijakan Privasi',
      'privacy_policy_desc': 'Baca kebijakan privasi aplikasi',
      'privacy_title': 'Kebijakan Privasi',
      'privacy_content':
          'Kebijakan privasi Fem-Psych Monitor menjelaskan bagaimana kami '
          'mengumpulkan, menggunakan, dan melindungi data Anda.\n\n'
          '1. Data yang Dikumpulkan\n'
          'Rekaman suara, transkrip, hasil analisis emosi, skor Big Five, '
          'dan skor kesehatan psikis yang Anda input melalui aplikasi.\n\n'
          '2. Penggunaan Data\n'
          'Data digunakan untuk memberikan analisis emosi, rekomendasi, '
          'dan pemantauan kesehatan psikis Anda secara personal.\n\n'
          '3. Penyimpanan & Keamanan\n'
          'Rekaman dan hasil analisis disimpan secara aman dan tidak dibagikan '
          'kepada pihak ketiga tanpa persetujuan Anda.\n\n'
          '4. Hak Anda\n'
          'Anda dapat menghapus data Anda kapan saja melalui menu pengaturan '
          'aplikasi.\n\n'
          '5. Kontak\n'
          'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini, '
          'hubungi kami melalui email resmi aplikasi.',

      // ── Days & Months ──
      'mon': 'Senin', 'tue': 'Selasa', 'wed': 'Rabu', 'thu': 'Kamis',
      'fri': 'Jumat', 'sat': 'Sabtu', 'sun': 'Minggu',
      'jan': 'Januari', 'feb': 'Februari', 'mar': 'Maret', 'apr': 'April',
      'may': 'Mei', 'jun': 'Juni', 'jul': 'Juli', 'aug': 'Agustus',
      'sep': 'September',
      'oct': 'Oktober',
      'nov': 'November',
      'dec': 'Desember',

      // ── Live Detection Screen ──
      'live_detection_title': 'Deteksi Emosi Live',
      'loading_model': 'Memuat model TFLite...',
      'model_not_ready': 'Model belum siap. Tunggu sebentar...',
      'mic_permission_required':
          'Permission microphone diperlukan untuk fitur ini',
      'failed_start_recording': 'Gagal memulai rekaman',
      'tap_to_stop': 'Sentuh untuk menghentikan',
      'loading_model_short': 'Memuat model...',
      'tap_to_start': 'Sentuh untuk memulai',
      'detecting_emotion': 'Mendeteksi emosi...',
      'emotion_detected': 'Emosi terdeteksi: ',
      'live_detection_label': 'Deteksi Live',
      'emotion_distribution': 'Distribusi Emosi:',
      'recording_result': 'Hasil Rekaman',
      'processing_result': 'Memproses hasil...',
      'story_prompts_title': 'Ceritakan Keluh Kesahmu',
      'story_prompts_subtitle':
          'Pilih salah satu pertanyaan di bawah ini dan ceritakan perasaanmu:',
      'story_prompt_tip': '💡 Tekan tombol mikrofon dan mulailah bercerita',
      'how_to_use_title': 'Cara Menggunakan',
      'guide_step_1_record': 'Sentuh tombol mikrofon untuk memulai',
      'press_mic_tip': 'Tekan tombol mikrofon dan mulailah bercerita',
      'guide_step_2_speak': 'Bicara dengan jelas selama 5-10 detik',
      'guide_step_3_stop': 'Sentuh lagi untuk menghentikan',
      'guide_step_4_view': 'Lihat hasil deteksi emosi Anda',

      // ── Story Prompts ──
      'story_prompt_1': 'Apa yang paling membuatmu khawatir hari ini?',
      'story_prompt_2': 'Ceritakan hal yang membuatmu bangga akhir-akhir ini',
      'story_prompt_3':
          'Bagaimana cara kamu menghadapi tantangan baru-baru ini?',
      'story_prompt_4':
          'Siapa yang selalu mendukungmu? Ceritakan tentang mereka',
      'story_prompt_5': 'Apa yang paling membuatmu sedih minggu ini?',
      'story_prompt_6': 'Apa target yang ingin kamu capai bulan ini?',
      'story_prompt_7': 'Apa hal terbaik yang terjadi padamu baru-baru ini?',
      'story_prompt_8': 'Bagaimana perasaanmu tentang keseimbangan hidupmu?',

      // ── Psych Levels ──
      'psych_excellent': 'Baik',
      'psych_good': 'Cukup',
      'psych_fair': 'Rentan',
      'psych_needs_attention': 'Butuh Perhatian',

      // ── Emotion Translations ──
      'emotion_happy': 'Bahagia',
      'emotion_sad': 'Sedih',
      'emotion_angry': 'Marah',
      'emotion_disgust': 'Jijik',
      'emotion_neutral': 'Netral',
      'emotion_fear': 'Takut',

      'msg_happy':
          'Luar biasa! Suasana hatimu sangat positif hari ini. Pertahankan energi baikmu! 🌟',
      'msg_sad':
          'Tidak apa-apa merasa sedih. Ambil napas dalam, kamu tidak sendirian. Kami ada untukmu. 💙',
      'msg_angry':
          'Terdeteksi emosi kuat. Coba tarik napas perlahan selama 5 detik untuk menenangkan diri. 🌿',
      'msg_disgust':
          'Kamu mungkin sedang tidak nyaman. Istirahat sebentar dan coba fokus pada hal positif. 🌈',
      'msg_neutral':
          'Kondisimu stabil dan tenang hari ini. Tetap jaga keseimbanganmu! ⚖️',
      'msg_fear':
          'Terdeteksi rasa cemas. Ingat, kamu lebih kuat dari ketakutanmu. Satu langkah kecil. 🤝',

      'sugg_happy_1':
          'Bagus sekali! Abadikan momen positif ini — tulis 3 hal yang membuatmu bahagia hari ini.',
      'sugg_happy_2':
          'Gunakan energi positifmu untuk menyelesaikan tugas yang sudah kamu tunda.',
      'sugg_happy_3':
          'Bagikan kebahagiaanmu kepada orang terdekat, kebaikan emosi itu menular! 🌟',

      'sugg_sad_1':
          'Tidak apa-apa untuk bersedih. Beri dirimu izin untuk merasakan emosi ini.',
      'sugg_sad_2':
          'Coba teknik 5-4-3-2-1: sebutkan 5 benda yang kamu lihat untuk kembali ke masa kini.',
      'sugg_sad_3':
          'Hubungi seseorang yang kamu percaya — berbagi cerita bisa sangat membantu.',
      'sugg_sad_4':
          'Lakukan aktivitas ringan yang kamu sukai: mendengarkan musik, membuat teh hangat.',

      'sugg_angry_1':
          'Hentikan sejenak. Tarik napas dalam 4 detik, tahan 4 detik, hembuskan 4 detik.',
      'sugg_angry_2':
          'Identifikasi sumber kemarahanmu — tuliskan apa yang terjadi tanpa menghakimi.',
      'sugg_angry_3':
          'Gerakkan tubuhmu: jalan santai 10 menit bisa meredakan ketegangan secara signifikan.',
      'sugg_angry_4':
          'Hindari pengambilan keputusan penting saat emosi sedang memuncak.',

      'sugg_disgust_1':
          'Rasa tidak nyaman ini valid. Coba identifikasi apa yang memicunya.',
      'sugg_disgust_2':
          'Alihkan fokus dengan melihat atau menghirup sesuatu yang kamu sukai.',
      'sugg_disgust_3':
          'Bersihkan area sekitarmu — lingkungan yang rapi bisa memperbaiki suasana hati.',
      'sugg_disgust_4':
          'Tetapkan batasan yang sehat terhadap hal-hal yang membuatmu tidak nyaman.',

      'sugg_neutral_1':
          'Kondisimu stabil. Ini saat yang baik untuk merencanakan aktivitas produktif.',
      'sugg_neutral_2':
          'Gunakan ketenangan ini untuk bermeditasi 5 menit — fokus pada pernapasanmu.',
      'sugg_neutral_3':
          'Cek kembali tujuan harianmu dan apa yang sudah kamu capai.',

      'sugg_fear_1':
          'Ketakutan adalah sinyal, bukan musuh. Tanya dirimu: "Apa yang benar-benar aku takuti?"',
      'sugg_fear_2':
          'Coba teknik grounding: injak tanah dengan kaki, rasakan lantai di bawahmu.',
      'sugg_fear_3':
          'Pecah hal yang menakutimu menjadi langkah-langkah kecil yang bisa dilakukan.',
      'sugg_fear_4':
          'Ingat: kamu sudah melewati hari-hari sulit sebelumnya. Kamu lebih kuat dari yang kamu kira. 💪',

      'overall_exc_1':
          'Pertahankan rutinitas positifmu! Kondisi psikismu sangat baik.',
      'overall_exc_2':
          'Bagikan energi positifmu kepada orang-orang di sekitarmu.',
      'overall_exc_3':
          'Lanjutkan aktivitas fisik & sosial yang sudah berjalan baik.',
      'overall_exc_4':
          'Tetap jadwalkan waktu istirahat yang cukup setiap hari.',

      'overall_good_1':
          'Kondisimu baik! Pertahankan keseimbangan hidup sehari-hari.',
      'overall_good_2':
          'Luangkan 10 menit setiap hari untuk refleksi diri atau jurnal.',
      'overall_good_3':
          'Jaga kualitas tidur — tidur 7-8 jam membantu stabilitas emosi.',
      'overall_good_4': 'Coba teknik pernapasan dalam saat mulai merasa stres.',

      'overall_fair_1':
          'Kondisimu cukup stabil. Sedikit upaya ekstra bisa membuat perbedaan besar.',
      'overall_fair_2':
          'Mulai terapkan rutinitas harian yang konsisten: makan, tidur, olahraga.',
      'overall_fair_3': 'Ceritakan perasaanmu kepada orang yang kamu percaya.',
      'overall_fair_4':
          'Pertimbangkan untuk mencoba meditasi atau journaling selama 5 menit/hari.',
      'overall_fair_5': 'Batasi paparan konten negatif di media sosial.',

      'overall_attn_1':
          'Kondisimu memerlukan perhatian lebih. Kamu tidak sendirian! 💙',
      'overall_attn_2':
          'Sangat disarankan untuk berbicara dengan konselor atau psikolog.',
      'overall_attn_3':
          'Fokus pada kebutuhan dasar: makan teratur, tidur cukup, gerak ringan.',
      'overall_attn_4':
          'Coba teknik grounding: sebutkan 5 hal yang kamu lihat, 4 yang bisa disentuh.',
      'overall_attn_5':
          'Jangan ragu menghubungi layanan kesehatan jiwa jika merasa kewalahan.',

      // ── Auth Validation ──
      'email_not_registered': 'Email tidak terdaftar atau password salah',
      'email_already_registered': 'Email sudah terdaftar. Silakan login.',
      'email_required': 'Email wajib diisi',
      'email_invalid': 'Format email tidak valid',
      'password_required': 'Password wajib diisi',
      'password_min_length': 'Minimal 6 karakter',
      'name_required': 'Nama wajib diisi',
      'password_mismatch': 'Password tidak cocok',
      'email_verification_sent': 'Email Verifikasi Terkirim',
      'email_verification_desc':
          'Silakan cek inbox email Anda dan klik link verifikasi sebelum login. Periksa juga folder Spam.',
      'email_not_verified': 'Email Belum Diverifikasi',
      'email_not_verified_desc':
          'Silakan verifikasi email Anda terlebih dahulu dengan mengklik link yang telah dikirim ke inbox Anda.',
      'resend_verification': 'Kirim Ulang Email Verifikasi',
      'verification_resent': 'Email verifikasi telah dikirim ulang!',
      'resend_failed': 'Gagal mengirim ulang email verifikasi',
      'google_signin_failed': 'Gagal masuk dengan Google',
      'check_email': 'Mengerti, Cek Email',
      'register_failed': 'Pendaftaran gagal. Silakan coba lagi.',

      // ── Settings ──
      'show_onboarding_again': 'Tampilkan Onboarding Lagi',
      'delete_account_data': 'Hapus Akun & Data',
      'delete_account_desc': 'Menghapus data rekaman & profil secara permanen',
      'yes_show': 'Ya, Tampilkan',
      'yes_delete': 'Ya, Hapus',
      'show_onboarding_title': 'Tampilkan Onboarding Lagi?',
      'delete_account_title': 'Hapus Akun & Data?',
      'delete_account_message':
          'Semua data rekaman dan profil Anda akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
      'backup_data': 'Backup Data',
      'backup_data_desc': 'Cadangkan data rekaman ke penyimpanan lokal',
      'restore_data': 'Restore Data',
      'restore_data_desc': 'Pulihkan data dari file backup',
      'backup_success': 'Backup Berhasil',
      'restore_no_backup': 'Tidak ada file backup ditemukan',
      'restore_confirm': 'Pulihkan Data?',
      'restore_confirm_desc':
          'Data saat ini akan ditimpa dengan data dari file backup. Lanjutkan?',
      'restore': 'Pulihkan',
      'save_backup': 'Simpan Backup',
      'select_backup_file': 'Pilih File Backup',

      // ── Profile ──
      'select_profile_photo': 'Pilih Foto Profil',
      'camera': 'Kamera',
      'gallery': 'Galeri',
      'delete_photo': 'Hapus Foto',
      'profile_photo_updated': 'Foto profil berhasil diperbarui',
      'failed_select_photo': 'Gagal memilih foto',
      'username_required': 'Username wajib diisi',

      // ── Onboarding ──
      'user': 'Pengguna',
      'start_now': 'Mulai Sekarang',
      'welcome_desc':
          'Aplikasi kesehatan mental khusus perempuan yang menggabungkan analisis emosi berbasis AI dengan pemahaman kepribadian Big Five (OCEAN) untuk mendukung perkembangan diri Anda.',
      'feature_voice_title': 'Analisis Suara & Emosi',
      'feature_voice_desc':
          'Deteksi emosi secara real-time menggunakan AI canggih. Rekam suara Anda dan dapatkan analisis mendalam tentang state emosi saat ini.',
      'feature_self_title': 'Pemahaman Diri',
      'feature_self_desc':
          'Kenali tipe kepribadian Big Five (OCEAN) dan pantau kesehatan mental dengan asesmen terstruktur berbasis sains.',
      'feature_growth_title': 'Pengembangan Diri',
      'feature_growth_desc':
          'Dapatkan rekomendasi dan saran tindakan yang dipersonalisasi untuk setiap fase kehidupan dan kondisi mental Anda.',
      'psy_intro_title': 'Kesehatan Mental\nPerempuan',
      'psy_intro_desc':
          'Pahami kesehatan mental Anda dengan pendekatan saintifik yang disesuaikan untuk kebutuhan perempuan.',
      'psy_about_title': 'Tentang Asesmen Kesehatan Mental',
      'psy_about_desc':
          'Kuesioner ini dirancang khusus untuk mengukur kesejahteraan mental perempuan, menggunakan standar klinis yang telah divalidasi. Asesmen ini mencakup 4 aspek utama yang seringkali unik bagi pengalaman perempuan:',
      'psy_point_1':
          '💼 Beban Peran & Stres: Menilai tekanan dari peran sosial, pekerjaan, dan keluarga',
      'psy_point_2':
          '💭 Regulasi Emosi & Hormonal: Memahami dampak fluktuasi hormon terhadap stabilitas emosi',
      'psy_point_3':
          '🪞 Citra Tubuh (Body Image): Mengukur persepsi diri dan kepuasan terhadap fisik',
      'psy_point_4':
          '🌙 Kualitas Tidur & Energi: Evaluasi pola tidur dan tingkat vitalitas harian',
      'psy_note_title': 'Catatan Penting',
      'psy_note_desc':
          'Jawablah dengan jujur sesuai kondisi Anda selama ini. Hasil asesmen ini bersifat rahasia dan hanya akan digunakan untuk memberikan rekomendasi yang dipersonalisasi.',
      'start_assessment': 'Mulai Asesmen',
      'result_title': 'Hasil Asesmen Anda',
      'result_subtitle':
          ', berikut adalah hasil analisis kepribadian dan kesehatan mental Anda.',
      'result_mental_health': 'Kesehatan Mental',
      'result_recommendations': 'Rekomendasi:',
      'completed': 'Selesai 🚀',
      'result_rec_1': 'Pertahankan rutinitas positif yang sudah berjalan',
      'result_rec_2': 'Lakukan aktivitas yang mendukung kesejahteraan mental',
      'result_rec_3': 'Bagikan energi positif Anda kepada orang lain',
      'result_rec_4': 'Tingkatkan manajemen stres harian',
      'result_rec_5': 'Luangkan waktu lebih untuk diri sendiri',
      'result_rec_6': 'Eksplorasi teknik relaksasi baru',
      'result_rec_7': 'Pertimbangkan untuk berkonsultasi dengan profesional',
      'result_rec_8': 'Tingkatkan pola tidur dan istirahat yang cukup',
      'result_rec_9': 'Cari dukungan dari orang terdekat',
      'result_rec_10':
          'Segera konsultasikan dengan profesional kesehatan mental',
      'result_rec_11': 'Jangan ragu untuk mencari dukungan sosial',
      'result_rec_12': 'Prioritaskan aktivitas yang memulihkan energi',
      'mental_health_questionnaire': 'Kuesioner Kesehatan Mental',
      'important_note': 'Catatan Penting',
      'continue_to_question': 'Lanjut ke Pertanyaan',
      'next': 'Next',
      'mental_health': 'Kesehatan Mental',

      // ── Big Five ──
      'bigfive_what_is': 'Psikologi Big Five',
      'bigfive_what_is_desc':
          'Model Big Five Personality (OCEAN) adalah teori kepribadian yang mengelompokkan sifat manusia ke dalam 5 dimensi utama yang luas. Setiap orang memiliki kombinasi unik dari kelima dimensi ini yang membentuk kepribadian mereka.',
      'bigfive_5dimensions': '5 Dimensi Utama:',
      'bigfive_dim_o': 'Keterbukaan',
      'bigfive_dim_o_desc':
          'Imajinatif, ingin tahu, dan terbuka terhadap hal-hal baru vs. konservatif dan suka rutinitas',
      'bigfive_dim_c': 'Kehati-hatian',
      'bigfive_dim_c_desc':
          'Terorganisir, disiplin, dan bertanggung jawab vs. spontan dan kurang terstruktur',
      'bigfive_dim_e': 'Ekstraversi',
      'bigfive_dim_e_desc':
          'Bersemangat, suka bergaul, dan energik vs. pendiam dan lebih suka menyendiri',
      'bigfive_dim_a': 'Keramahan',
      'bigfive_dim_a_desc':
          'Percaya, kooperatif, dan penuh empati vs. kompetitif dan skeptis',
      'bigfive_dim_n': 'Neurotisisme',
      'bigfive_dim_n_desc':
          'Cemas, sensitif, dan mudah khawatir vs. stabil emosi dan tenang',
      'bigfive_ready': 'Siap mulai mengenali kepribadian Anda?',
      'result_bigfive': 'Skor Big Five Anda',
      'bigfive_high': 'Tinggi',
      'bigfive_moderate': 'Sedang',
      'bigfive_low': 'Rendah',

      // ── Home ──
      'not_assessed': 'Belum Dinilai',
      'fill_questionnaire_to_see_score':
          'Isi kuesioner kesehatan mental untuk melihat skor Anda',
      'mental_health_score': 'Skor Kesehatan Mental',
      'emotion_impact_on_score': 'Dampak Emosi terhadap Skor',
      'positive_emotions_increase':
          'Emosi positif (Happy, Neutral) meningkatkan skor',
      'negative_emotions_decrease':
          'Emosi negatif (Sad, Fear, Angry, Disgust) menurunkannya',
      'info': 'Info',

      // ── Record Detail ──
      'detail_title': 'Detail Deteksi',
      'detail_detection_time': 'Waktu Deteksi',
      'detail_emotion_value': 'Nilai Emosi',
      'detail_confidence': 'Tingkat Kepercayaan',
      'detail_weighted_score': 'Skor Berbobot',
      'detail_scale_5': '(skala -5 s/d +5)',
      'detail_emotion_distribution': 'Distribusi Emosi',
      'detail_radar_desc':
          'Grafik radar distribusi intensitas 6 jenis emosi dari rekaman suara',
      'detail_emotion_scale': '📊 Skala Nilai Emosi',
      'detail_suggestion_emotion': '💡 Saran Berdasarkan Emosi',

      // ── Live Detection ──
      'analyzing_voice': 'Menganalisis Suara Live...',
      'ready_to_listen': 'Siap Mendengarkan',
      'story_prompt_proud':
          'Ceritakan hal yang membuatmu bangga akhir-akhir ini',
      'story_prompt_supporter':
          'Siapa yang selalu mendukungmu? Ceritakan tentang mereka',

      // ── Emotion Detection Screen ──
      'emotion_detection': 'Deteksi Emosi',
      'transcript_placeholder': 'Transkrip akan muncul di sini...',
      'transcript_label': 'Transkrip',
      'listening_label': 'Mendengarkan',
      'processing_transcription': 'Memproses transkripsi...',
      'processing_transcription_first':
          'Memproses transkripsi...\n(Pertama kali muat model bisa lebih lama)',
      'analyzing_text_emotion': 'Menganalisis emosi dari teks...',
      'failed_start_recording_detail': 'Gagal memulai rekaman: {error}',
      'emotion_data_unavailable':
          'Data emosi tidak tersedia. Silakan coba rekam ulang.',
      'emotion_score': 'Skor Emosi',
      'top_emotions': 'Top Emosi',
      'available': 'Tersedia',
      'none': 'Tidak ada',
      'dominant_badge': 'DOMINAN',
      'combined_source_desc':
          'Gabungan deteksi suara (60%) + analisis teks (40%)',
      'suggestion_for_emotion_name': 'Saran untuk Emosi {emotion}',
      'detected': 'Terdeteksi',
      'transcript_unavailable': 'Transkrip tidak tersedia',
      'transcript_unavailable_desc':
          'Pastikan Anda berbicara dengan jelas dan\nGemini API key sudah benar di file .env',
      'transcript_not_recorded': 'Transkrip tidak terekam untuk sesi ini.',
      'text_emotions_label': 'Emosi dari teks:',
      'detection_source': 'Sumber Deteksi',
      'voice_source': 'Suara',
      'text_source': 'Teks',
      'not_available': 'Tidak tersedia',
      'combined_source_info':
          'Hasil akhir adalah gabungan deteksi suara (60%) dan analisis teks (40%)',
      'score_trend_title': 'Skor Tren Emosi',
      'score_trend_desc':
          'Skor ini digunakan untuk grafik tren emosi di halaman Riwayat',
      'base_value': 'Nilai Dasar',
      'final_confidence': 'Keyakinan Akhir',
      'emotion_score_result': 'Hasil Skor Emosi',
      'trigger_title': 'Apa pemicunya?',
      'trigger_not_selected': 'Tidak dipilih',
      'trigger_work': 'Pekerjaan',
      'trigger_romance': 'Asmara',
      'trigger_finance': 'Keuangan',
      'trigger_health': 'Kesehatan',
      'trigger_family': 'Keluarga',
      'trigger_social': 'Pertemanan',
      'trigger_other': 'Lainnya',
      'trigger_saved': 'Pemicu disimpan',
      'trigger_chart_title': 'Pemicu Emosi',

      // ── Premium Purchase ──
      'purchase_success_title': 'Pembelian Berhasil',
      'purchase_success_desc':
          'Selamat! Anda sekarang menikmati semua fitur premium.',
      'purchase_failed_title': 'Pembelian Gagal',
      'purchase_failed_desc': 'Terjadi kesalahan. Silakan coba lagi.',
      'restore_success_title': 'Pemulihan Berhasil',
      'restore_success_desc': 'Pembelian Anda berhasil dipulihkan.',
      'restore_failed_title': 'Pemulihan Gagal',
      'restore_failed_desc': 'Tidak ada pembelian yang dapat dipulihkan.',

      // ── Premium Screen ──
      'premium_badge': 'PREMIUM',
      'premium_active_badge': 'PREMIUM AKTIF',
      'premium_hero_title': 'Buka Akses Premium',
      'premium_hero_active_title': 'Premium Aktif',
      'premium_hero_subtitle': 'Deteksi emosi tanpa batas & bebas iklan',
      'premium_hero_active_subtitle': 'Anda menikmati semua fitur premium',
      'premium_chip_unlimited': 'Deteksi tanpa batas',
      'premium_chip_adfree': 'Bebas iklan',
      'premium_chip_secure': 'Aman & pribadi',
      'premium_plan_weekly': 'Mingguan',
      'premium_plan_monthly': 'Bulanan',
      'premium_plan_yearly': 'Tahunan',
      'premium_tag_weekly': 'Coba dulu',
      'premium_tag_monthly': 'Paling fleksibel',
      'premium_tag_yearly': 'Nilai terbaik',
      'premium_period_week': '/mgg',
      'premium_period_month': '/bln',
      'premium_period_year': '/thn',
      'premium_effective': '± {price}/bln',
      'premium_savings': 'Hemat {percent}%',
      'premium_popular': 'POPULER',
      'premium_choose_plan': 'Pilih paket',
      'premium_cancel_anytime': 'Batalkan kapan saja',
      'premium_secure_checkout': 'Pembayaran aman. Batalkan kapan saja.',
      'premium_subscribe_terms':
          'Dengan berlangganan, Anda menyetujui Syarat & Ketentuan dan Kebijakan Privasi kami. Langganan diperpanjang otomatis kecuali dibatalkan.',
      'premium_subscribe_now': 'Langganan Sekarang',
      'premium_restore_tooltip': 'Pulihkan pembelian',
      'premium_active_pill': 'Aktif',
      'premium_expires_in': 'Premium Berakhir Dalam',
      'premium_expiry_label': 'Berakhir',
      'premium_benefits_title': 'Manfaat Premium Anda',
      'premium_benefit_unlimited': 'Deteksi tanpa batas',
      'premium_benefit_unlimited_desc':
          'Rekam dan analisis emosi sebanyak yang Anda butuhkan',
      'premium_benefit_adfree': 'Bebas iklan',
      'premium_benefit_adfree_desc': 'Nikmati aplikasi tanpa gangguan iklan',
      'premium_countdown_days': 'Hari',
      'premium_countdown_hours': 'Jam',
      'premium_countdown_minutes': 'Menit',
      'premium_countdown_seconds': 'Detik',
      'premium_purchase_canceled': 'Pembelian dibatalkan.',
      'premium_purchase_error': 'Gagal memulai pembelian. Silakan coba lagi.',
      'premium_plan_unavailable': 'Produk tidak tersedia saat ini.',

      // ── Daily Detection Limit ──
      'daily_limit_title': 'Batas Harian Tercapai',
      'daily_limit_message':
          'Kamu telah menggunakan 5 deteksi gratis hari ini. Tonton iklan untuk mendapatkan 1 deteksi tambahan?',
      'watch_ad': 'Tonton Iklan',
      'remaining_detections': 'Sisa Deteksi Hari Ini',
      'remaining_unlimited': 'Tak Terbatas',
      'remaining_prefix': 'Sisa',
      'big_five_retake_title': 'Tes Big Five',
      'big_five_retake_desc':
          'Jawab 20 pertanyaan singkat untuk mengetahui profil kepribadian Big Five-mu.',
      'big_five_saved': 'Skor Big Five berhasil disimpan!',
      'reset_onboarding': 'Tampilkan Onboarding',
      'reset_onboarding_desc': 'Ulangi asesmen awal aplikasi',
      'reset_onboarding_message':
          'Anda akan kembali ke asesmen awal. Semua data yang sudah tersimpan tetap aman. Lanjutkan?',
      'reset': 'Reset',
      'reward_earned_title': 'Reward Didapatkan!',
      'reward_earned_message':
          'Terima kasih telah menonton iklan. Kamu bisa melakukan 1 deteksi emosi tambahan sekarang.',
      'login_successful': 'Login Berhasil',
      'incomplete_data_title': 'Data Belum Lengkap',
      'incomplete_data_desc': 'Anda harus mengisi data onboarding terlebih dahulu sebelum menggunakan aplikasi.',
      'fill_now': 'Isi Sekarang',
      'later': 'Nanti',
      'model_downloading': 'Mengunduh model suara...',
      'model_download_success': 'Model berhasil diunduh.',
      'model_download_failed': 'Gagal mengunduh model. Periksa koneksi internet Anda.',
      'download_now': 'Unduh Sekarang',
      'voice_model': 'Model Suara',
      'voice_model_desc': 'Model ini diperlukan untuk deteksi emosi dari suara.',
      'psych_status_happy': 'Sangat Baik',
      'psych_status_sad': 'Perlu Perhatian',
      'psych_status_angry': 'Butuh Jeda',
      'psych_status_disgust': 'Kurang Nyaman',
      'psych_status_neutral': 'Stabil',
      'psych_status_fear': 'Perlu Dukungan',
      'weight': 'bobot',
    },

    // ════════════════════════════════════════════
    // English
    // ════════════════════════════════════════════
    'en': {
      // ── General ──
      'app_name': 'Fem-Psych Monitor',
      'app_subtitle': 'Smart Psychological Monitoring',
      'splash_subtitle': 'Monitor Your Mental Health',
      'cancel': 'Cancel',
      'save': 'Save',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
      'done': 'Done',
      'back': 'Back',
      'edit': 'Edit',
      'delete': 'Delete',
      'loading': 'Loading...',

      // ── Bottom Nav ──
      'nav_home': 'Home',
      'nav_record': 'Record',
      'nav_history': 'History',

      // ── Home Screen ──
      'greeting_morning': 'Good Morning',
      'greeting_afternoon': 'Good Afternoon',
      'greeting_evening': 'Good Evening',
      'greeting_night': 'Good Night',
      'how_are_you': 'How are you feeling today?',
      'psych_status_today': 'Psychological Status Today',
      'detection_confidence': 'Detection Confidence',
      'last_detection': 'Last detection',
      'recordings': 'Recordings',
      'positive': 'Positive',
      'attention': 'Attention',
      'start_recording': 'Start Recording',
      'detect_emotion_ai': 'Detect your emotions now with AI',
      'realtime': '⚡ Real-time',
      'private': '🔒 Private',
      'six_emotions': '🧠 6 Emotions',
      'psych_recommendation': 'Psych Recommendation',
      'dominant_emotion': 'Dominant Emotion',
      'dominant_emotion_7d': 'Dominant emotion past 7 days',
      'suggestion_for': 'Suggestions for',
      'start_recording_desc': 'Detect your emotions now with AI',
      'recent_detection': 'Recent Detections',
      'recent_detections': 'Recent Detections',
      'view_all': 'View All →',
      'see_all': 'View All →',

      // ── Voice Detection ──
      'voice_detection': 'Voice Detection',
      'recording': 'Recording...',
      'detection_done': 'Detection Complete! ✓',
      'press_to_record': 'Press to Start Recording',
      'detection_result': 'Detection Result',
      'all_emotion_dist': 'All Emotion Distribution',
      'psych_message': 'Psychological Message',
      'suggestion_for_emotion': 'Suggestions for',
      'how_to_use': 'How to Use',
      'step_1': 'Press the microphone button above',
      'step_2': 'Say a few sentences naturally',
      'step_3': 'Press again to stop and see results',
      'guide_step_1': 'Press the microphone button above',
      'guide_step_2': 'Say a few sentences naturally',
      'guide_step_3': 'Press again to stop and see results',

      // ── History ──
      'history_title': 'History',
      'confidence_trend': 'Confidence Trend per Recording',
      'confidence_trend_sub':
          'Each point = one recording session (oldest → newest)',
      'emotion_breakdown': 'Emotion Breakdown',
      'detection_log': 'Detection Log',
      'confidence': 'Confidence',
      'all_filter': 'All',
      'filter_date': 'Filter Date',
      'emotion_value_trend': 'Emotion Value Trend',
      'emotion_score_over_time': 'Emotion score development over time',
      'mental_score_trend': 'Mental Score Trend',
      'mental_score_over_time': 'Mental score changes over time',
      'entries_count': '{count} entries',
      'see_more_count': 'See {count} more',
      'total': 'Total',
      'no_emotion_data': 'No emotion data yet',
      'average_score_label': 'Average: {score}',
      'sessions_count': '{count} sessions',
      'chart_tooltip_format': '{emoji} {name}\nScore: {score} • {confidence}',
      'search_emotion_hint': 'Search emotions...',
      'sort_newest': 'Newest',
      'sort_oldest': 'Oldest',
      'results_count': '{count} results',
      'no_data_found': 'No data found',

      // ── Profile Menu ──
      'profile': 'Profile',
      'profile_menu': 'Profile',
      'settings': 'Settings',
      'settings_menu': 'Settings',
      'login_signup': 'Login / Sign Up',

      // ── Recording Prompts ──
      'recording_prompt_title': 'Start by sharing...',
      'recording_prompt_1': 'Tell me about your day today...',
      'recording_prompt_2': 'What has made you happy recently?',
      'recording_prompt_3': 'Is there something on your mind?',
      'recording_prompt_4': 'How are you feeling right now?',
      'recording_prompt_5': 'Share something you are grateful for today.',
      'recording_prompt_6': 'What do you want to achieve this week?',
      'recording_prompt_7': 'Who made you smile today?',
      'recording_prompt_8': 'How was your sleep last night?',

      // ── Time Filter ──
      'filter_all_time': 'All',
      'filter_today': 'Today',
      'filter_7_days': '7 Days',
      'filter_30_days': '30 Days',
      'filter_custom': 'Custom',
      'filter_select_range': 'Select Date Range',

      // ── Profile Screen ──
      'profile_title': 'My Profile',
      'profile_photo': 'Profile Photo',
      'tap_to_change_photo': 'Tap to change photo',
      'username': 'Username',
      'email': 'Email',
      'save_profile': 'Save Changes',
      'profile_saved': 'Profile saved successfully!',
      'member_since': 'Member since',

      // ── Settings Screen ──
      'settings_title': 'Settings',
      'language': 'Language',
      'language_id': 'Bahasa Indonesia',
      'language_en': 'English',
      'theme_mode': 'Theme',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'app_guide': 'App Guide',
      'app_guide_desc': 'Learn how to use this app',
      'terms_services': 'Terms & Conditions',
      'terms_desc': 'Read the terms of use',
      'license': 'License',
      'license_desc': 'Open-source licenses used',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'logout_confirm_desc':
          'You will need to login again to use the recording feature.',
      'general': 'General',
      'about': 'About',
      'account': 'Account',
      'notifications': 'Notifications',
      'routine_reminder': 'Regular Reminder',
      'routine_reminder_desc':
          'Remind to check in with your emotions every 3 hours',
      'reminder_time': 'Start Time',
      'reminder_disabled': 'Disabled',
      'reminder_notification_title': 'Fem-Psych Monitor Reminder',
      'reminder_notification_body':
          'Hi, it\'s time to check in with your feelings today. Record a few sentences to see how you\'re doing.',
      'notification_permission_denied':
          'Notification permission denied. Enable it in your device settings.',
      'reminder_scheduled': 'Regular reminder enabled (every 3 hours)',
      'reminder_cancelled': 'Regular reminder disabled',

      // ── Auth Screen ──
      'login': 'Login',
      'register': 'Register',
      'login_title': 'Welcome Back',
      'login_subtitle': 'Login to monitor your mental health',
      'register_title': 'Create Account',
      'register_subtitle': 'Register to start your mental health journey',
      'email_hint': 'name@example.com',
      'password_hint': 'Password',
      'confirm_password': 'Confirm Password',
      'username_hint': 'Full name',
      'forgot_password': 'Forgot password?',
      'or_continue_with': 'or continue with',
      'google_signin': 'Sign in with Google',
      'no_account': "Don't have an account?",
      'has_account': 'Already have an account?',
      'login_required': 'Login Required',
      'login_required_desc':
          'Please login first to use the voice recording feature.',
      'login_now': 'Login Now',
      'privacy_agree': 'I have read and agree to the',
      'privacy_agree_prefix': 'I agree to the ',
      'privacy_agree_connector': ' and ',
      'privacy_link': 'Privacy Policy',
      'auth_pass_required': 'Password is required',
      'auth_email_required': 'Email is required',
      'auth_email_invalid_format': 'Invalid email format',
      'auth_pass_min_length': 'At least 6 characters',
      'auth_confirm_required': 'Password confirmation is required',
      'auth_pass_mismatch': 'Passwords do not match',
      'auth_invalid_email_first': 'Please enter a valid email first',
      'auth_already_verified': 'Already verified? Log in',
      'auth_email_exists_title': 'Email Already Registered',
      'auth_email_exists_desc':
          'The email {email} already has an account. The password you entered does not match.',
      'auth_reset_sent': 'Password reset email sent!',
      'auth_reset_failed': 'Failed to send password reset email',
      'auth_reset_button': 'Send Reset Password',
      'try_again': 'Try Again',
      'auth_google_account_title': 'Account Registered with Google',
      'auth_google_account_desc':
          'This email is already registered with Google. Please sign in with the Google button below.',
      'auth_err_email_in_use':
          'This email already has an account. Please sign in with the correct password.',
      'auth_err_wrong_password_title': 'Wrong Password',
      'auth_err_wrong_password':
          'The password you entered is incorrect. Please try again.',
      'auth_err_invalid_email_title': 'Invalid Email',
      'auth_err_invalid_email': 'The email format you entered is invalid.',
      'auth_err_too_many_title': 'Too Many Attempts',
      'auth_err_too_many':
          'Too many login attempts. Please wait a moment before trying again.',
      'auth_err_network_title': 'Connection Failed',
      'auth_err_network':
          'Unable to reach the server. Please check your internet connection.',
      'auth_err_invalid_credential_title': 'Incorrect Email/Password',
      'auth_err_invalid_credential':
          'The email or password you entered is incorrect. Please try again.',
      'auth_err_generic_title': 'Login Failed',
      'auth_err_generic': 'Something went wrong. Please try again later.',
      'auth_has_password_desc':
          'This email is already registered with a password. Please log in with your email and password instead of Google.',
      'auth_login_with_password': 'Log in with Password',
      'auth_email_label': 'Email',
      'password_label': 'Password',
      'auth_privacy_required': 'Please check the privacy policy first',
      'auth_email_verif_note':
          'Email verification will be required before the account can be used.',
      'verif_gmail_hint': 'Check your inbox or Promotions / Social folder',
      'verif_yahoo_hint': 'Check your inbox or Bulk / Spam folder',
      'verif_outlook_hint': 'Check your inbox or Junk Email folder',
      'verif_other_hint': 'Check your inbox and spam folder',
      'verification_step': 'Verification',
      'verif_account_created': 'New Account Created!',
      'verif_email_sent_to': 'A verification email has been sent to:',
      'verif_click_link':
          'Click the link in the email to verify, then return to the app.',
      'verif_resend_sent': 'Verification email sent',
      'verif_resend_countdown': 'Resend ({count})',
      'verif_resend_button': 'Send Verification Email',
      'verif_success_title': 'Verification Successful!',
      'verif_success_desc': 'Your email has been verified. Redirecting...',
      'verif_processing': 'Logging in...',
      'setpass_title': 'Create Password',
      'auth_onboarding_title': 'Complete Your Profile',
      'auth_onboarding_desc':
          'Before using the app, you need to complete the psychological questionnaire first. This data helps us provide recommendations that match your condition.',
      'auth_onboarding_start': 'Start Now',
      'setpass_desc':
          'Create a password for your Google account so you can also log in with email and password.',
      'setpass_failed': 'Failed to save password. Please try again.',
      'setpass_button': 'Save Password',
      'bigfive_dominant': 'Dominant Trait',

      // ── App Guide ──
      'guide_title': 'App Guide',
      'guide_step1_title': 'Record Your Voice',
      'guide_step1_desc':
          'Press the microphone button and say a few sentences. AI will analyze the emotion in your voice.',
      'guide_step2_title': 'View Detection Results',
      'guide_step2_desc':
          'After the recording is complete, you will see the dominant emotion and its confidence level.',
      'guide_step3_title': 'Track Your History',
      'guide_step3_desc':
          'Visit the History page to see emotion trends and your psychological development over time.',
      'guide_step4_title': 'Read Psychological Tips',
      'guide_step4_desc':
          'Each detection comes with relevant psychological tips to help you manage your emotions.',

      // ── Terms ──
      'terms_title': 'Terms & Conditions',
      'terms_content':
          'Fem-PhysicsMonitor is a voice analysis-based mental health '
          'monitoring app. This app is educational and does not replace '
          'consultation with mental health professionals.\n\n'
          '1. Voice data is only used for local emotion analysis and is not '
          'sent to third-party servers.\n\n'
          '2. Emotion detection results are estimates and should not be used '
          'as a basis for medical diagnosis.\n\n'
          '3. Users are responsible for using the app in accordance with these terms.\n\n'
          '4. Developers are not responsible for decisions made based on the '
          "app's analysis results.",

      // ── Privacy Policy ──
      'privacy_policy': 'Privacy Policy',
      'privacy_policy_desc': 'Read the app privacy policy',
      'privacy_title': 'Privacy Policy',
      'privacy_content':
          'The Fem-Psych Monitor privacy policy explains how we collect, '
          'use, and protect your data.\n\n'
          '1. Data Collected\n'
          'Voice recordings, transcripts, emotion analysis results, Big Five '
          'scores, and psychological health scores you provide through the app.\n\n'
          '2. Data Usage\n'
          'Data is used to provide personalized emotion analysis, '
          'recommendations, and mental health monitoring.\n\n'
          '3. Storage & Security\n'
          'Recordings and analysis results are stored securely and are not '
          'shared with third parties without your consent.\n\n'
          '4. Your Rights\n'
          'You can delete your data at any time through the app settings menu.\n\n'
          '5. Contact\n'
          'If you have questions about this privacy policy, contact us via '
          'the official app email.',

      // ── Days & Months ──
      'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday', 'thu': 'Thursday',
      'fri': 'Friday', 'sat': 'Saturday', 'sun': 'Sunday',
      'jan': 'January', 'feb': 'February', 'mar': 'March', 'apr': 'April',
      'may': 'May', 'jun': 'June', 'jul': 'July', 'aug': 'August',
      'sep': 'September',
      'oct': 'October',
      'nov': 'November',
      'dec': 'December',

      // ── Live Detection Screen ──
      'live_detection_title': 'Live Emotion Detection',
      'loading_model': 'Loading TFLite model...',
      'model_not_ready': 'Model not ready. Please wait...',
      'mic_permission_required':
          'Microphone permission is required for this feature',
      'failed_start_recording': 'Failed to start recording',
      'tap_to_stop': 'Tap to stop',
      'loading_model_short': 'Loading model...',
      'tap_to_start': 'Tap to start',
      'detecting_emotion': 'Detecting emotion...',
      'emotion_detected': 'Emotion detected: ',
      'live_detection_label': 'Live Detection',
      'emotion_distribution': 'Emotion Distribution:',
      'recording_result': 'Recording Result',
      'processing_result': 'Processing result...',
      'story_prompts_title': 'Share Your Feelings',
      'story_prompts_subtitle':
          'Choose one of the questions below and share your feelings:',
      'story_prompt_tip': '💡 Press the microphone button and start talking',
      'how_to_use_title': 'How to Use',
      'guide_step_1_record': 'Touch the microphone button to start',
      'press_mic_tip': 'Press the microphone button and start talking',
      'guide_step_2_speak': 'Speak clearly for 5-10 seconds',
      'guide_step_3_stop': 'Touch again to stop',
      'guide_step_4_view': 'View your emotion detection results',

      // ── Story Prompts ──
      'story_prompt_1': 'What worries you the most today?',
      'story_prompt_2': 'Tell me about something that made you proud recently',
      'story_prompt_3': 'How have you been dealing with challenges lately?',
      'story_prompt_4': 'Who always supports you? Tell me about them',
      'story_prompt_5': 'What made you the saddest this week?',
      'story_prompt_6': 'What targets do you want to achieve this month?',
      'story_prompt_7': 'What is the best thing that happened to you recently?',
      'story_prompt_8': 'How do you feel about your life balance?',

      // ── Psych Levels ──
      'psych_excellent': 'Good',
      'psych_good': 'Fair',
      'psych_fair': 'Vulnerable',
      'psych_needs_attention': 'Needs Attention',

      // ── Emotion Translations ──
      'emotion_happy': 'Happy',
      'emotion_sad': 'Sad',
      'emotion_angry': 'Angry',
      'emotion_disgust': 'Disgust',
      'emotion_neutral': 'Neutral',
      'emotion_fear': 'Fear',

      'msg_happy':
          'Excellent! Your mood is very positive today. Keep up the good energy! 🌟',
      'msg_sad':
          'It is okay to feel sad. Take a deep breath, you are not alone. We are here for you. 💙',
      'msg_angry':
          'Strong emotion detected. Try to breathe slowly for 5 seconds to calm down. 🌿',
      'msg_disgust':
          'You might be feeling uncomfortable. Take a brief break and try to focus on positive things. 🌈',
      'msg_neutral':
          'Your condition is stable and calm today. Keep your balance! ⚖️',
      'msg_fear':
          'Anxiety detected. Remember, you are stronger than your fear. Take small steps. 🤝',

      'sugg_happy_1':
          'Great! Capture this positive moment — write down 3 things that make you happy today.',
      'sugg_happy_2': 'Use your positive energy to finish any delayed tasks.',
      'sugg_happy_3':
          'Share your happiness with those around you, positive emotions are contagious! 🌟',

      'sugg_sad_1':
          'It is okay to feel sad. Give yourself permission to feel this emotion.',
      'sugg_sad_2':
          'Try the 5-4-3-2-1 technique: name 5 things you can see to return to the present.',
      'sugg_sad_3':
          'Contact someone you trust — sharing your stories can be very helpful.',
      'sugg_sad_4':
          'Do light activities you enjoy: listen to music, make a warm tea.',

      'sugg_angry_1':
          'Pause. Take a deep breath for 4 seconds, hold for 4 seconds, exhale for 4 seconds.',
      'sugg_angry_2':
          'Identify the source of anger — write down what happened without judging.',
      'sugg_angry_3':
          'Move your body: a 10-minute walk can significantly ease tension.',
      'sugg_angry_4': 'Avoid making big decisions when your emotion is high.',

      'sugg_disgust_1':
          'This discomfort is valid. Try to identify the trigger.',
      'sugg_disgust_2':
          'Shift your focus by looking at or smelling something you like.',
      'sugg_disgust_3':
          'Clean your surroundings — a tidy environment can improve mood.',
      'sugg_disgust_4':
          'Set healthy boundaries against things that make you uncomfortable.',

      'sugg_neutral_1':
          'Your condition is stable. It is a good time to plan productive activities.',
      'sugg_neutral_2':
          'Use this calmness to meditate for 5 minutes — focus on breathing.',
      'sugg_neutral_3': 'Review your daily goals and what you have achieved.',

      'sugg_fear_1':
          'Fear is a signal, not an enemy. Ask yourself: "What am I really afraid of?"',
      'sugg_fear_2':
          'Try grounding techniques: step your feet on the floor, feel the ground.',
      'sugg_fear_3': 'Break the scary thing into small, doable steps.',
      'sugg_fear_4':
          'Remember: you have survived difficult days before. You are stronger than you think. 💪',

      'overall_exc_1':
          'Keep your positive routine! Your psychological condition is excellent.',
      'overall_exc_2': 'Share your positive energy with people around you.',
      'overall_exc_3':
          'Continue your physical & social activities that are going well.',
      'overall_exc_4': 'Keep scheduling enough rest every day.',

      'overall_good_1':
          'Your condition is good! Keep your daily life balanced.',
      'overall_good_2':
          'Spend 10 minutes a day for self-reflection or journaling.',
      'overall_good_3':
          'Maintain sleep quality — 7-8 hours helps emotional stability.',
      'overall_good_4':
          'Try deep breathing techniques when you start feeling stressed.',

      'overall_fair_1':
          'Your condition is fairly stable. Little extra effort makes a big difference.',
      'overall_fair_2':
          'Start a consistent daily routine: eating, sleeping, exercising.',
      'overall_fair_3': 'Share your feelings with someone you trust.',
      'overall_fair_4':
          'Consider trying meditation or journaling for 5 minutes/day.',
      'overall_fair_5': 'Limit exposure to negative content on social media.',

      'overall_attn_1':
          'Your condition needs more attention. You are not alone! 💙',
      'overall_attn_2':
          'It is highly recommended to talk to a counselor or psychologist.',
      'overall_attn_3':
          'Focus on basic needs: regular meals, sufficient sleep, light movement.',
      'overall_attn_4':
          'Try grounding techniques: name 5 things you can see, 4 you can touch.',
      'overall_attn_5':
          'Do not hesitate to contact mental health services if feeling overwhelmed.',

      // ── Auth Validation ──
      'email_not_registered': 'Email not registered or password incorrect',
      'email_already_registered': 'Email already registered. Please login.',
      'email_required': 'Email is required',
      'email_invalid': 'Invalid email format',
      'password_required': 'Password is required',
      'password_min_length': 'Minimum 6 characters',
      'name_required': 'Name is required',
      'password_mismatch': 'Password does not match',
      'email_verification_sent': 'Verification Email Sent',
      'email_verification_desc':
          'Please check your email inbox and click the verification link before logging in. Also check your Spam folder.',
      'email_not_verified': 'Email Not Verified',
      'email_not_verified_desc':
          'Please verify your email first by clicking the link sent to your inbox.',
      'resend_verification': 'Resend Verification Email',
      'verification_resent': 'Verification email has been resent!',
      'resend_failed': 'Failed to resend verification email',
      'google_signin_failed': 'Failed to sign in with Google',
      'check_email': 'Got It, Check Email',
      'register_failed': 'Registration failed. Please try again.',

      // ── Settings ──
      'show_onboarding_again': 'Show Onboarding Again',
      'delete_account_data': 'Delete Account & Data',
      'delete_account_desc': 'Permanently delete recording data and profile',
      'yes_show': 'Yes, Show',
      'yes_delete': 'Yes, Delete',
      'show_onboarding_title': 'Show Onboarding Again?',
      'delete_account_title': 'Delete Account & Data?',
      'delete_account_message':
          'All your recording data and profile will be permanently deleted. This action cannot be undone.',
      'backup_data': 'Backup Data',
      'backup_data_desc': 'Backup recording data to local storage',
      'restore_data': 'Restore Data',
      'restore_data_desc': 'Restore data from backup file',
      'backup_success': 'Backup Successful',
      'restore_no_backup': 'No backup file found',
      'restore_confirm': 'Restore Data?',
      'restore_confirm_desc':
          'Current data will be overwritten with data from the backup file. Continue?',
      'restore': 'Restore',
      'save_backup': 'Save Backup',
      'select_backup_file': 'Select Backup File',

      // ── Profile ──
      'select_profile_photo': 'Select Profile Photo',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'delete_photo': 'Delete Photo',
      'profile_photo_updated': 'Profile photo updated successfully',
      'failed_select_photo': 'Failed to select photo',
      'username_required': 'Username is required',

      // ── Onboarding ──
      'user': 'User',
      'start_now': 'Start Now',
      'welcome_desc':
          'A mental health app specifically for women that combines AI-based emotion analysis with Big Five (OCEAN) personality understanding to support your personal development.',
      'feature_voice_title': 'Voice & Emotion Analysis',
      'feature_voice_desc':
          'Real-time emotion detection using advanced AI. Record your voice and get in-depth analysis of your current emotional state.',
      'feature_self_title': 'Self Understanding',
      'feature_self_desc':
          'Discover your Big Five (OCEAN) personality profile and monitor mental health with science-based structured assessments.',
      'feature_growth_title': 'Personal Growth',
      'feature_growth_desc':
          'Get personalized recommendations and action suggestions for every phase of life and mental condition.',
      'psy_intro_title': "Women's Mental\nHealth",
      'psy_intro_desc':
          'Understand your mental health with a scientific approach tailored for women\'s needs.',
      'psy_about_title': 'About Mental Health Assessment',
      'psy_about_desc':
          'This questionnaire is specifically designed to measure women\'s mental well-being, using clinically validated standards. This assessment covers 4 main aspects that are often unique to women\'s experiences:',
      'psy_point_1':
          '💼 Role & Stress: Assessing pressure from social roles, work, and family',
      'psy_point_2':
          '💭 Emotional & Hormonal Regulation: Understanding hormonal fluctuations\' impact on emotional stability',
      'psy_point_3':
          '🪞 Body Image: Measuring self-perception and satisfaction with physical appearance',
      'psy_point_4':
          '🌙 Sleep Quality & Energy: Evaluating sleep patterns and daily vitality',
      'psy_note_title': 'Important Note',
      'psy_note_desc':
          'Answer honestly according to your condition. The assessment results are confidential and will only be used to provide personalized recommendations.',
      'start_assessment': 'Start Assessment',
      'result_title': 'Your Assessment Results',
      'result_subtitle':
          ', here are your personality and mental health analysis results.',
      'result_mental_health': 'Mental Health',
      'result_recommendations': 'Recommendations:',
      'completed': 'Done 🚀',
      'result_rec_1': 'Keep the positive routines going',
      'result_rec_2': 'Do activities that support mental well-being',
      'result_rec_3': 'Share your positive energy with others',
      'result_rec_4': 'Increase daily stress management',
      'result_rec_5': 'Spend more time for yourself',
      'result_rec_6': 'Explore new relaxation techniques',
      'result_rec_7': 'Consider consulting a professional',
      'result_rec_8': 'Improve sleep and rest patterns',
      'result_rec_9': 'Seek support from loved ones',
      'result_rec_10': 'Consult mental health professionals immediately',
      'result_rec_11': "Don't hesitate to seek social support",
      'result_rec_12': 'Prioritize energy-restoring activities',
      'mental_health_questionnaire': 'Mental Health Questionnaire',
      'important_note': 'Important Note',
      'continue_to_question': 'Continue to Question',
      'next': 'Next',
      'mental_health': 'Mental Health',

      // ── Big Five ──
      'bigfive_what_is': 'Big Five Psychology',
      'bigfive_what_is_desc':
          'The Big Five Personality Model (OCEAN) is a personality theory that groups human traits into 5 broad dimensions. Each person has a unique combination of these five dimensions that shapes their personality.',
      'bigfive_5dimensions': '5 Main Dimensions:',
      'bigfive_dim_o': 'Openness',
      'bigfive_dim_o_desc':
          'Imaginative, curious, and open to new experiences vs. conservative and prefers routine',
      'bigfive_dim_c': 'Conscientiousness',
      'bigfive_dim_c_desc':
          'Organized, disciplined, and responsible vs. spontaneous and less structured',
      'bigfive_dim_e': 'Extraversion',
      'bigfive_dim_e_desc':
          'Enthusiastic, sociable, and energetic vs. reserved and prefers solitude',
      'bigfive_dim_a': 'Agreeableness',
      'bigfive_dim_a_desc':
          'Trusting, cooperative, and empathetic vs. competitive and skeptical',
      'bigfive_dim_n': 'Neuroticism',
      'bigfive_dim_n_desc':
          'Anxious, sensitive, and prone to worry vs. emotionally stable and calm',
      'bigfive_ready': 'Ready to discover your personality?',
      'result_bigfive': 'Your Big Five Score',
      'bigfive_high': 'High',
      'bigfive_moderate': 'Moderate',
      'bigfive_low': 'Low',

      // ── Home ──
      'not_assessed': 'Not Assessed',
      'fill_questionnaire_to_see_score':
          'Fill mental health questionnaire to see your score',
      'mental_health_score': 'Mental Health Score',
      'emotion_impact_on_score': 'Emotion Impact on Score',
      'positive_emotions_increase':
          'Positive emotions (Happy, Neutral) increase score',
      'negative_emotions_decrease':
          'Negative emotions (Sad, Fear, Angry, Disgust) decrease it',
      'info': 'Info',

      // ── Record Detail ──
      'detail_title': 'Detection Detail',
      'detail_detection_time': 'Detection Time',
      'detail_emotion_value': 'Emotion Value',
      'detail_confidence': 'Confidence Level',
      'detail_weighted_score': 'Weighted Score',
      'detail_scale_5': '(scale -5 to +5)',
      'detail_emotion_distribution': 'Emotion Distribution',
      'detail_radar_desc':
          'Radar chart of 6 emotion intensity distribution from voice recording',
      'detail_emotion_scale': '📊 Emotion Value Scale',
      'detail_suggestion_emotion': '💡 Suggestions Based on Emotion',

      // ── Live Detection ──
      'analyzing_voice': 'Analyzing Voice Live...',
      'ready_to_listen': 'Ready to Listen',
      'story_prompt_proud':
          'Tell me about something that made you proud recently',
      'story_prompt_supporter': 'Who always supports you? Tell me about them',

      // ── Emotion Detection Screen ──
      'emotion_detection': 'Emotion Detection',
      'transcript_placeholder': 'Transcript will appear here...',
      'transcript_label': 'Transcript',
      'listening_label': 'Listening',
      'processing_transcription': 'Processing transcription...',
      'processing_transcription_first':
          'Processing transcription...\n(First model load may take longer)',
      'analyzing_text_emotion': 'Analyzing emotion from text...',
      'failed_start_recording_detail': 'Failed to start recording: {error}',
      'emotion_data_unavailable':
          'Emotion data not available. Please try recording again.',
      'emotion_score': 'Emotion Score',
      'top_emotions': 'Top Emotions',
      'available': 'Available',
      'none': 'None',
      'dominant_badge': 'DOMINANT',
      'combined_source_desc':
          'Combined voice detection (60%) + text analysis (40%)',
      'suggestion_for_emotion_name': 'Suggestions for Emotion {emotion}',
      'detected': 'Detected',
      'transcript_unavailable': 'Transcript unavailable',
      'transcript_unavailable_desc':
          'Make sure you speak clearly and\nthe Gemini API key is correct in the .env file',
      'transcript_not_recorded':
          'Transcript was not recorded for this session.',
      'text_emotions_label': 'Emotions from text:',
      'detection_source': 'Detection Source',
      'voice_source': 'Voice',
      'text_source': 'Text',
      'not_available': 'Not available',
      'combined_source_info':
          'The final result combines voice detection (60%) and text analysis (40%)',
      'score_trend_title': 'Emotion Trend Score',
      'score_trend_desc':
          'This score is used for the emotion trend chart in History',
      'base_value': 'Base Value',
      'final_confidence': 'Final Confidence',
      'emotion_score_result': 'Emotion Score Result',
      'trigger_title': 'What triggered this?',
      'trigger_not_selected': 'Not selected',
      'trigger_work': 'Work',
      'trigger_romance': 'Romance',
      'trigger_finance': 'Finance',
      'trigger_health': 'Health',
      'trigger_family': 'Family',
      'trigger_social': 'Social',
      'trigger_other': 'Other',
      'trigger_saved': 'Trigger saved',
      'trigger_chart_title': 'Emotion Triggers',

      // ── Premium Purchase ──
      'purchase_success_title': 'Purchase Successful',
      'purchase_success_desc':
          'Congratulations! You now enjoy all premium features.',
      'purchase_failed_title': 'Purchase Failed',
      'purchase_failed_desc': 'An error occurred. Please try again.',
      'restore_success_title': 'Restore Successful',
      'restore_success_desc': 'Your purchases have been restored successfully.',
      'restore_failed_title': 'Restore Failed',
      'restore_failed_desc': 'No purchases could be restored.',

      // ── Premium Screen ──
      'premium_badge': 'PREMIUM',
      'premium_active_badge': 'PREMIUM ACTIVE',
      'premium_hero_title': 'Unlock Premium',
      'premium_hero_active_title': 'Enjoying Premium',
      'premium_hero_subtitle':
          'Unlimited emotion detection & ad-free experience',
      'premium_hero_active_subtitle':
          "You're enjoying all premium features",
      'premium_chip_unlimited': 'Unlimited detection',
      'premium_chip_adfree': 'Ad-free',
      'premium_chip_secure': 'Private & secure',
      'premium_plan_weekly': 'Weekly',
      'premium_plan_monthly': 'Monthly',
      'premium_plan_yearly': 'Yearly',
      'premium_tag_weekly': 'Try first',
      'premium_tag_monthly': 'Most flexible',
      'premium_tag_yearly': 'Best value',
      'premium_period_week': '/wk',
      'premium_period_month': '/mo',
      'premium_period_year': '/yr',
      'premium_effective': '± {price}/mo',
      'premium_savings': 'Save {percent}%',
      'premium_popular': 'POPULAR',
      'premium_choose_plan': 'Choose your plan',
      'premium_cancel_anytime': 'Cancel anytime',
      'premium_secure_checkout': 'Secure checkout. Cancel anytime.',
      'premium_subscribe_terms':
          'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions auto-renew unless canceled.',
      'premium_subscribe_now': 'Subscribe Now',
      'premium_restore_tooltip': 'Restore purchases',
      'premium_active_pill': 'Active',
      'premium_expires_in': 'Premium Expires In',
      'premium_expiry_label': 'Expiry',
      'premium_benefits_title': 'Your Premium Benefits',
      'premium_benefit_unlimited': 'Unlimited detection',
      'premium_benefit_unlimited_desc':
          'Record and analyze your emotions as many times as you need',
      'premium_benefit_adfree': 'Ad-free experience',
      'premium_benefit_adfree_desc': 'Enjoy the app without any ads',
      'premium_countdown_days': 'Days',
      'premium_countdown_hours': 'Hours',
      'premium_countdown_minutes': 'Min',
      'premium_countdown_seconds': 'Sec',
      'premium_purchase_canceled': 'Purchase canceled.',
      'premium_purchase_error': 'Failed to start purchase. Please try again.',
      'premium_plan_unavailable': 'Product currently unavailable.',

      // ── Daily Detection Limit ──
      'daily_limit_title': 'Daily Limit Reached',
      'daily_limit_message':
          'You\'ve used 5 free detections today. Watch an ad to unlock 1 more detection?',
      'watch_ad': 'Watch Ad',
      'remaining_detections': 'Remaining Today',
      'remaining_unlimited': 'Unlimited',
      'remaining_prefix': 'Remaining',
      'big_five_retake_title': 'Big Five Assessment',
      'big_five_retake_desc':
          'Answer 20 short questions to discover your Big Five personality profile.',
      'big_five_saved': 'Big Five scores saved!',
      'reset_onboarding': 'Show Onboarding',
      'reset_onboarding_desc': 'Restart the initial app assessment',
      'reset_onboarding_message':
          'You will return to the initial assessment. All saved data remains safe. Continue?',
      'reset': 'Reset',
      'reward_earned_title': 'Reward Earned!',
      'reward_earned_message':
          'Thank you for watching the ad. You can now do 1 additional emotion detection.',
      'login_successful': 'Login Successful',
      'incomplete_data_title': 'Incomplete Data',
      'incomplete_data_desc': 'You need to complete the onboarding data before using the application.',
      'fill_now': 'Fill Now',
      'later': 'Later',
      'model_downloading': 'Downloading voice model...',
      'model_download_success': 'Model downloaded successfully.',
      'model_download_failed': 'Failed to download model. Check your internet connection.',
      'download_now': 'Download Now',
      'voice_model': 'Voice Model',
      'voice_model_desc': 'This model is required for voice emotion detection.',
      'psych_status_happy': 'Very Good',
      'psych_status_sad': 'Needs Attention',
      'psych_status_angry': 'Needs a Break',
      'psych_status_disgust': 'Uncomfortable',
      'psych_status_neutral': 'Stable',
      'psych_status_fear': 'Needs Support',
      'weight': 'weight',
    },
  };
}
