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
      'privacy_link': 'Kebijakan Privasi',

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
      'email_verification_desc': 'Silakan cek inbox email Anda dan klik link verifikasi sebelum login. Periksa juga folder Spam.',
      'email_not_verified': 'Email Belum Diverifikasi',
      'email_not_verified_desc': 'Silakan verifikasi email Anda terlebih dahulu dengan mengklik link yang telah dikirim ke inbox Anda.',
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
      'show_onboarding_message': 'Aplikasi akan menampilkan splash screen dan pertanyaan MBTI kembali. Data Anda tidak akan dihapus.',
      'delete_account_title': 'Hapus Akun & Data?',
      'delete_account_message': 'Semua data rekaman dan profil Anda akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
      'backup_data': 'Backup Data',
      'backup_data_desc': 'Cadangkan data rekaman ke penyimpanan lokal',
      'restore_data': 'Restore Data',
      'restore_data_desc': 'Pulihkan data dari file backup',
      'backup_success': 'Backup Berhasil',
      'restore_no_backup': 'Tidak ada file backup ditemukan',
      'restore_confirm': 'Pulihkan Data?',
      'restore_confirm_desc': 'Data saat ini akan ditimpa dengan data dari file backup. Lanjutkan?',
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
      'welcome_desc': 'Aplikasi kesehatan mental khusus perempuan yang menggabungkan analisis emosi berbasis AI dengan pemahaman kepribadian Big Five (OCEAN) untuk mendukung perkembangan diri Anda.',
      'feature_voice_title': 'Analisis Suara & Emosi',
      'feature_voice_desc': 'Deteksi emosi secara real-time menggunakan AI canggih. Rekam suara Anda dan dapatkan analisis mendalam tentang state emosi saat ini.',
      'feature_self_title': 'Pemahaman Diri',
      'feature_self_desc': 'Kenali tipe kepribadian Big Five (OCEAN) dan pantau kesehatan mental dengan asesmen terstruktur berbasis sains.',
      'feature_growth_title': 'Pengembangan Diri',
      'feature_growth_desc': 'Dapatkan rekomendasi dan saran tindakan yang dipersonalisasi untuk setiap fase kehidupan dan kondisi mental Anda.',
      'mbti_intro_title': 'Psikologi MBTI',
      'mbti_intro_subtitle': 'Kenali tipe kepribadianmu',
      'mbti_what_is': 'Apa itu MBTI?',
      'mbti_what_is_desc': 'Myers-Briggs Type Indicator (MBTI) adalah alat ukur kepribadian yang disusun berdasarkan teori tipe psikologis Carl Jung. Tes ini membantu memahami cara Anda memproses informasi, mengambil keputusan, dan berinteraksi dengan dunia.',
      'mbti_4dimensions': '4 Dimensi Utama:',
      'mbti_dimension_ei': 'Orientasi Energi',
      'mbti_dimension_ei_desc': 'Dari mana Anda mendapatkan energi: Ekstrovert (luar) atau Introvert (dalam)',
      'mbti_dimension_sn': 'Pemrosesan Info',
      'mbti_dimension_sn_desc': 'Bagaimana Anda mengolah informasi: Sensing (fakta) atau Intuition (konsep)',
      'mbti_dimension_tf': 'Pengambilan Keputusan',
      'mbti_dimension_tf_desc': 'Basis keputusan Anda: Thinking (logika) atau Feeling (nilai/perasaan)',
      'mbti_dimension_jp': 'Gaya Hidup',
      'mbti_dimension_jp_desc': 'Cara Anda menghadapi dunia: Judging (terencana) atau Perceiving (fleksibel)',
      'mbti_know_question': 'Apakah Anda sudah mengetahui tipe MBTI Anda?',
      'mbti_not_know': 'Saya Belum Tahu',
      'mbti_not_know_desc': 'Ikuti tes MBTI untuk mengetahui tipe kepribadian Anda',
      'mbti_already_know': 'Saya Sudah Tahu',
      'mbti_already_know_desc': 'Pilih tipe MBTI Anda dari daftar yang tersedia',
      'psy_intro_title': 'Kesehatan Mental\nPerempuan',
      'psy_intro_desc': 'Pahami kesehatan mental Anda dengan pendekatan saintifik yang disesuaikan untuk kebutuhan perempuan.',
      'psy_about_title': 'Tentang Asesmen Kesehatan Mental',
      'psy_about_desc': 'Kuesioner ini dirancang khusus untuk mengukur kesejahteraan mental perempuan, menggunakan standar klinis yang telah divalidasi. Asesmen ini mencakup 4 aspek utama yang seringkali unik bagi pengalaman perempuan:',
      'psy_point_1': '💼 Beban Peran & Stres: Menilai tekanan dari peran sosial, pekerjaan, dan keluarga',
      'psy_point_2': '💭 Regulasi Emosi & Hormonal: Memahami dampak fluktuasi hormon terhadap stabilitas emosi',
      'psy_point_3': '🪞 Citra Tubuh (Body Image): Mengukur persepsi diri dan kepuasan terhadap fisik',
      'psy_point_4': '🌙 Kualitas Tidur & Energi: Evaluasi pola tidur dan tingkat vitalitas harian',
      'psy_note_title': 'Catatan Penting',
      'psy_note_desc': 'Jawablah dengan jujur sesuai kondisi Anda selama ini. Hasil asesmen ini bersifat rahasia dan hanya akan digunakan untuk memberikan rekomendasi yang dipersonalisasi.',
      'start_assessment': 'Mulai Asesmen',
      'result_title': 'Hasil Asesmen Anda',
      'result_subtitle': ', berikut adalah hasil analisis kepribadian dan kesehatan mental Anda.',
      'result_mbti': 'Tipe MBTI Anda',
      'result_mental_health': 'Kesehatan Mental',
      'result_mbti_detail': 'Detail Skor MBTI',
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
      'result_rec_10': 'Segera konsultasikan dengan profesional kesehatan mental',
      'result_rec_11': 'Jangan ragu untuk mencari dukungan sosial',
      'result_rec_12': 'Prioritaskan aktivitas yang memulihkan energi',
      'yes_i_know': 'Ya, Saya Sudah Tahu',
      'no_i_want_test': 'Belum, Saya Ingin Tes',
      'confirm_continue': 'Konfirmasi & Lanjut',
      'understanding_differences': 'Memahami Perbedaan',
      'mental_health_questionnaire': 'Kuesioner Kesehatan Mental',
      'important_note': 'Catatan Penting',
      'continue_to_question': 'Lanjut ke Pertanyaan',
      'next': 'Next',
      'mental_health': 'Kesehatan Mental',
      'mbti_result': 'Ini kepribadianmu:',
      'dimension_energy': 'Energi',
      'dimension_information': 'Informasi',
      'dimension_decisions': 'Keputusan',
      'dimension_lifestyle': 'Gaya Hidup',

      // ── Big Five ──
      'bigfive_what_is': 'Psikologi Big Five',
      'bigfive_what_is_desc': 'Model Big Five Personality (OCEAN) adalah teori kepribadian yang mengelompokkan sifat manusia ke dalam 5 dimensi utama yang luas. Setiap orang memiliki kombinasi unik dari kelima dimensi ini yang membentuk kepribadian mereka.',
      'bigfive_5dimensions': '5 Dimensi Utama:',
      'bigfive_dim_o': 'Keterbukaan',
      'bigfive_dim_o_desc': 'Imajinatif, ingin tahu, dan terbuka terhadap hal-hal baru vs. konservatif dan suka rutinitas',
      'bigfive_dim_c': 'Kehati-hatian',
      'bigfive_dim_c_desc': 'Terorganisir, disiplin, dan bertanggung jawab vs. spontan dan kurang terstruktur',
      'bigfive_dim_e': 'Ekstraversi',
      'bigfive_dim_e_desc': 'Bersemangat, suka bergaul, dan energik vs. pendiam dan lebih suka menyendiri',
      'bigfive_dim_a': 'Keramahan',
      'bigfive_dim_a_desc': 'Percaya, kooperatif, dan penuh empati vs. kompetitif dan skeptis',
      'bigfive_dim_n': 'Neurotisisme',
      'bigfive_dim_n_desc': 'Cemas, sensitif, dan mudah khawatir vs. stabil emosi dan tenang',
      'bigfive_ready': 'Siap mulai mengenali kepribadian Anda?',
      'result_bigfive': 'Skor Big Five Anda',
      'bigfive_high': 'Tinggi',
      'bigfive_moderate': 'Sedang',
      'bigfive_low': 'Rendah',

      // ── Home ──
      'not_assessed': 'Belum Dinilai',
      'fill_questionnaire_to_see_score': 'Isi kuesioner kesehatan mental untuk melihat skor Anda',
      'mental_health_score': 'Skor Kesehatan Mental',
      'emotion_impact_on_score': 'Dampak Emosi terhadap Skor',
      'positive_emotions_increase': 'Emosi positif (Happy, Neutral) meningkatkan skor',
      'negative_emotions_decrease': 'Emosi negatif (Sad, Fear, Angry, Disgust) menurunkannya',
      'info': 'Info',

      // ── Record Detail ──
      'detail_title': 'Detail Deteksi',
      'detail_detection_time': 'Waktu Deteksi',
      'detail_emotion_value': 'Nilai Emosi',
      'detail_confidence': 'Tingkat Kepercayaan',
      'detail_weighted_score': 'Skor Berbobot',
      'detail_scale_5': '(skala -5 s/d +5)',
      'detail_emotion_distribution': 'Distribusi Emosi',
      'detail_radar_desc': 'Grafik radar distribusi intensitas 6 jenis emosi dari rekaman suara',
      'detail_emotion_scale': '📊 Skala Nilai Emosi',
      'detail_suggestion_mbti': '💡 Saran Berdasarkan MBTI & Emosi',
      'detail_suggestion_emotion': '💡 Saran Berdasarkan Emosi',

      // ── Live Detection ──
      'analyzing_voice': 'Menganalisis Suara Live...',
      'ready_to_listen': 'Siap Mendengarkan',
      'story_prompt_proud': 'Ceritakan hal yang membuatmu bangga akhir-akhir ini',
      'story_prompt_supporter': 'Siapa yang selalu mendukungmu? Ceritakan tentang mereka',

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
      'emotion_data_unavailable': 'Data emosi tidak tersedia. Silakan coba rekam ulang.',
      'emotion_score': 'Skor Emosi',
      'top_emotions': 'Top Emosi',
      'available': 'Tersedia',
      'none': 'Tidak ada',
      'dominant_badge': 'DOMINAN',
      'combined_source_desc': 'Gabungan deteksi suara (60%) + analisis teks (40%)',
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
      'purchase_success_desc': 'Selamat! Anda sekarang menikmati semua fitur premium.',
      'purchase_failed_title': 'Pembelian Gagal',
      'purchase_failed_desc': 'Terjadi kesalahan. Silakan coba lagi.',
      'restore_success_title': 'Pemulihan Berhasil',
      'restore_success_desc': 'Pembelian Anda berhasil dipulihkan.',
      'restore_failed_title': 'Pemulihan Gagal',
      'restore_failed_desc': 'Tidak ada pembelian yang dapat dipulihkan.',

      // ── Daily Detection Limit ──
      'daily_limit_title': 'Batas Harian Tercapai',
      'daily_limit_message': 'Kamu telah menggunakan 5 deteksi gratis hari ini. Tonton iklan untuk mendapatkan 1 deteksi tambahan?',
      'watch_ad': 'Tonton Iklan',
      'remaining_detections': 'Sisa Deteksi Hari Ini',
      'remaining_unlimited': 'Tak Terbatas',
      'remaining_prefix': 'Sisa',
      'big_five_retake_title': 'Tes Big Five',
      'big_five_retake_desc': 'Jawab 20 pertanyaan singkat untuk mengetahui profil kepribadian Big Five-mu.',
      'big_five_saved': 'Skor Big Five berhasil disimpan!',
      'reset_onboarding': 'Tampilkan Onboarding',
      'reset_onboarding_desc': 'Ulangi asesmen awal aplikasi',
      'reset_onboarding_message': 'Anda akan kembali ke asesmen awal. Semua data yang sudah tersimpan tetap aman. Lanjutkan?',
      'reset': 'Reset',
      'reward_earned_title': 'Reward Didapatkan!',
      'reward_earned_message': 'Terima kasih telah menonton iklan. Kamu bisa melakukan 1 deteksi emosi tambahan sekarang.',
      'login_successful': 'Login Berhasil',
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
      'privacy_link': 'Privacy Policy',

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
      'email_verification_desc': 'Please check your email inbox and click the verification link before logging in. Also check your Spam folder.',
      'email_not_verified': 'Email Not Verified',
      'email_not_verified_desc': 'Please verify your email first by clicking the link sent to your inbox.',
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
      'show_onboarding_message': 'The app will show the splash screen and MBTI questions again. Your data will not be deleted.',
      'delete_account_title': 'Delete Account & Data?',
      'delete_account_message': 'All your recording data and profile will be permanently deleted. This action cannot be undone.',
      'backup_data': 'Backup Data',
      'backup_data_desc': 'Backup recording data to local storage',
      'restore_data': 'Restore Data',
      'restore_data_desc': 'Restore data from backup file',
      'backup_success': 'Backup Successful',
      'restore_no_backup': 'No backup file found',
      'restore_confirm': 'Restore Data?',
      'restore_confirm_desc': 'Current data will be overwritten with data from the backup file. Continue?',
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
      'welcome_desc': 'A mental health app specifically for women that combines AI-based emotion analysis with Big Five (OCEAN) personality understanding to support your personal development.',
      'feature_voice_title': 'Voice & Emotion Analysis',
      'feature_voice_desc': 'Real-time emotion detection using advanced AI. Record your voice and get in-depth analysis of your current emotional state.',
      'feature_self_title': 'Self Understanding',
      'feature_self_desc': 'Discover your Big Five (OCEAN) personality profile and monitor mental health with science-based structured assessments.',
      'feature_growth_title': 'Personal Growth',
      'feature_growth_desc': 'Get personalized recommendations and action suggestions for every phase of life and mental condition.',
      'mbti_intro_title': 'MBTI Psychology',
      'mbti_intro_subtitle': 'Discover your personality type',
      'mbti_what_is': 'What is MBTI?',
      'mbti_what_is_desc': 'Myers-Briggs Type Indicator (MBTI) is a personality assessment tool based on Carl Jung\'s psychological type theory. This test helps you understand how you process information, make decisions, and interact with the world.',
      'mbti_4dimensions': '4 Main Dimensions:',
      'mbti_dimension_ei': 'Energy Orientation',
      'mbti_dimension_ei_desc': 'Where you get energy: Extrovert (outward) or Introvert (inward)',
      'mbti_dimension_sn': 'Information Processing',
      'mbti_dimension_sn_desc': 'How you process information: Sensing (facts) or Intuition (concepts)',
      'mbti_dimension_tf': 'Decision Making',
      'mbti_dimension_tf_desc': 'Basis of your decisions: Thinking (logic) or Feeling (values/feelings)',
      'mbti_dimension_jp': 'Lifestyle',
      'mbti_dimension_jp_desc': 'How you face the world: Judging (planned) or Perceiving (flexible)',
      'mbti_know_question': 'Do you already know your MBTI type?',
      'mbti_not_know': "I Don't Know Yet",
      'mbti_not_know_desc': 'Take the MBTI test to discover your personality type',
      'mbti_already_know': 'I Already Know',
      'mbti_already_know_desc': 'Select your MBTI type from the available list',
      'psy_intro_title': "Women's Mental\nHealth",
      'psy_intro_desc': 'Understand your mental health with a scientific approach tailored for women\'s needs.',
      'psy_about_title': 'About Mental Health Assessment',
      'psy_about_desc': 'This questionnaire is specifically designed to measure women\'s mental well-being, using clinically validated standards. This assessment covers 4 main aspects that are often unique to women\'s experiences:',
      'psy_point_1': '💼 Role & Stress: Assessing pressure from social roles, work, and family',
      'psy_point_2': '💭 Emotional & Hormonal Regulation: Understanding hormonal fluctuations\' impact on emotional stability',
      'psy_point_3': '🪞 Body Image: Measuring self-perception and satisfaction with physical appearance',
      'psy_point_4': '🌙 Sleep Quality & Energy: Evaluating sleep patterns and daily vitality',
      'psy_note_title': 'Important Note',
      'psy_note_desc': 'Answer honestly according to your condition. The assessment results are confidential and will only be used to provide personalized recommendations.',
      'start_assessment': 'Start Assessment',
      'result_title': 'Your Assessment Results',
      'result_subtitle': ', here are your personality and mental health analysis results.',
      'result_mbti': 'Your MBTI Type',
      'result_mental_health': 'Mental Health',
      'result_mbti_detail': 'MBTI Score Details',
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
      'yes_i_know': 'Yes, I Know',
      'no_i_want_test': 'No, I Want to Test',
      'confirm_continue': 'Confirm & Continue',
      'understanding_differences': 'Understanding Differences',
      'mental_health_questionnaire': 'Mental Health Questionnaire',
      'important_note': 'Important Note',
      'continue_to_question': 'Continue to Question',
      'next': 'Next',
      'mental_health': 'Mental Health',
      'mbti_result': 'Your personality is:',
      'dimension_energy': 'Energy',
      'dimension_information': 'Information',
      'dimension_decisions': 'Decisions',
      'dimension_lifestyle': 'Lifestyle',

      // ── Big Five ──
      'bigfive_what_is': 'Big Five Psychology',
      'bigfive_what_is_desc': 'The Big Five Personality Model (OCEAN) is a personality theory that groups human traits into 5 broad dimensions. Each person has a unique combination of these five dimensions that shapes their personality.',
      'bigfive_5dimensions': '5 Main Dimensions:',
      'bigfive_dim_o': 'Openness',
      'bigfive_dim_o_desc': 'Imaginative, curious, and open to new experiences vs. conservative and prefers routine',
      'bigfive_dim_c': 'Conscientiousness',
      'bigfive_dim_c_desc': 'Organized, disciplined, and responsible vs. spontaneous and less structured',
      'bigfive_dim_e': 'Extraversion',
      'bigfive_dim_e_desc': 'Enthusiastic, sociable, and energetic vs. reserved and prefers solitude',
      'bigfive_dim_a': 'Agreeableness',
      'bigfive_dim_a_desc': 'Trusting, cooperative, and empathetic vs. competitive and skeptical',
      'bigfive_dim_n': 'Neuroticism',
      'bigfive_dim_n_desc': 'Anxious, sensitive, and prone to worry vs. emotionally stable and calm',
      'bigfive_ready': 'Ready to discover your personality?',
      'result_bigfive': 'Your Big Five Score',
      'bigfive_high': 'High',
      'bigfive_moderate': 'Moderate',
      'bigfive_low': 'Low',

      // ── Home ──
      'not_assessed': 'Not Assessed',
      'fill_questionnaire_to_see_score': 'Fill mental health questionnaire to see your score',
      'mental_health_score': 'Mental Health Score',
      'emotion_impact_on_score': 'Emotion Impact on Score',
      'positive_emotions_increase': 'Positive emotions (Happy, Neutral) increase score',
      'negative_emotions_decrease': 'Negative emotions (Sad, Fear, Angry, Disgust) decrease it',
      'info': 'Info',

      // ── Record Detail ──
      'detail_title': 'Detection Detail',
      'detail_detection_time': 'Detection Time',
      'detail_emotion_value': 'Emotion Value',
      'detail_confidence': 'Confidence Level',
      'detail_weighted_score': 'Weighted Score',
      'detail_scale_5': '(scale -5 to +5)',
      'detail_emotion_distribution': 'Emotion Distribution',
      'detail_radar_desc': 'Radar chart of 6 emotion intensity distribution from voice recording',
      'detail_emotion_scale': '📊 Emotion Value Scale',
      'detail_suggestion_mbti': '💡 Suggestions Based on MBTI & Emotion',
      'detail_suggestion_emotion': '💡 Suggestions Based on Emotion',

      // ── Live Detection ──
      'analyzing_voice': 'Analyzing Voice Live...',
      'ready_to_listen': 'Ready to Listen',
      'story_prompt_proud': 'Tell me about something that made you proud recently',
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
      'emotion_data_unavailable': 'Emotion data not available. Please try recording again.',
      'emotion_score': 'Emotion Score',
      'top_emotions': 'Top Emotions',
      'available': 'Available',
      'none': 'None',
      'dominant_badge': 'DOMINANT',
      'combined_source_desc': 'Combined voice detection (60%) + text analysis (40%)',
      'suggestion_for_emotion_name': 'Suggestions for Emotion {emotion}',
      'detected': 'Detected',
      'transcript_unavailable': 'Transcript unavailable',
      'transcript_unavailable_desc':
          'Make sure you speak clearly and\nthe Gemini API key is correct in the .env file',
      'transcript_not_recorded': 'Transcript was not recorded for this session.',
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
      'purchase_success_desc': 'Congratulations! You now enjoy all premium features.',
      'purchase_failed_title': 'Purchase Failed',
      'purchase_failed_desc': 'An error occurred. Please try again.',
      'restore_success_title': 'Restore Successful',
      'restore_success_desc': 'Your purchases have been restored successfully.',
      'restore_failed_title': 'Restore Failed',
      'restore_failed_desc': 'No purchases could be restored.',

      // ── Daily Detection Limit ──
      'daily_limit_title': 'Daily Limit Reached',
      'daily_limit_message': 'You\'ve used 5 free detections today. Watch an ad to unlock 1 more detection?',
      'watch_ad': 'Watch Ad',
      'remaining_detections': 'Remaining Today',
      'remaining_unlimited': 'Unlimited',
      'remaining_prefix': 'Remaining',
      'big_five_retake_title': 'Big Five Assessment',
      'big_five_retake_desc': 'Answer 20 short questions to discover your Big Five personality profile.',
      'big_five_saved': 'Big Five scores saved!',
      'reset_onboarding': 'Show Onboarding',
      'reset_onboarding_desc': 'Restart the initial app assessment',
      'reset_onboarding_message': 'You will return to the initial assessment. All saved data remains safe. Continue?',
      'reset': 'Reset',
      'reward_earned_title': 'Reward Earned!',
      'reward_earned_message': 'Thank you for watching the ad. You can now do 1 additional emotion detection.',
      'login_successful': 'Login Successful',
    },
  };
}
