// Sistem lokalisasi sederhana — map string manual untuk Bahasa Indonesia & Inggris.
// Tidak menggunakan package intl/flutter_localizations agar ringan.

class AppLocalizations {
  static String _currentLocale = 'id';

  static String get currentLocale => _currentLocale;

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
      'app_name': 'Fem-PhysicsMonitor',
      'app_subtitle': 'Pemantau Psikis Personal',
      'cancel': 'Batal',
      'save': 'Simpan',
      'ok': 'OK',
      'yes': 'Ya',
      'no': 'Tidak',
      'close': 'Tutup',
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
      'start_recording': 'Mulai Rekam Suara',
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
      'psych_excellent': 'Sangat Sehat',
      'psych_good': 'Baik',
      'psych_fair': 'Cukup',
      'psych_needs_attention': 'Perlu Perhatian',

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
    },

    // ════════════════════════════════════════════
    // English
    // ════════════════════════════════════════════
    'en': {
      // ── General ──
      'app_name': 'Fem-PhysicsMonitor',
      'app_subtitle': 'Personal Mental Health Monitor',
      'cancel': 'Cancel',
      'save': 'Save',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
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
      'psych_excellent': 'Excellent',
      'psych_good': 'Good',
      'psych_fair': 'Fair',
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
    },
  };
}
