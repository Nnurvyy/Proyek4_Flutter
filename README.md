# Simple Counter App (Implementasi SRP)

Proyek ini adalah aplikasi Counter sederhana yang dikembangkan menggunakan Flutter. Fokus utama dari pengembangan aplikasi ini adalah penerapan prinsip **Single Responsibility Principle (SRP)**, di mana logika bisnis dan antarmuka pengguna (UI) dipisahkan secara tegas.

## Refleksi: Mengapa Menerapkan SRP?

Penerapan SRP dalam proyek ini memberikan dampak positif pada alur kerja, membuat pengembangan lebih terstruktur dan meminimalisir risiko *bug* pada kode yang sudah berjalan.

Berikut adalah manfaat spesifik yang kami rasakan saat menambahkan fitur *History Logger*:

1.  **Fokus pada Logika (Controller)**
    Saat mengimplementasikan fitur pembatasan riwayat log (maksimal 5 aktivitas terakhir), kami hanya perlu fokus menulis kode pada `Controller`. Kami dapat menyusun logika data tanpa terdistraksi oleh urusan desain atau bagaimana data tersebut akan ditampilkan.

2.  **Fokus pada Tampilan (View)**
    Saat memberikan *feedback* visual (seperti warna hijau untuk "Tambah" dan merah untuk "Kurang"), kami cukup memodifikasi bagian `View`. Hal ini dilakukan tanpa menyentuh atau mengubah satu baris pun logika bisnis yang ada di `Controller`.

3.  **Keamanan dan Stabilitas Kode**
    Pemisahan ini menjamin bahwa penambahan fitur baru (*logging*) tidak mengganggu fungsionalitas utama (*counter*). Fitur perhitungan tetap berjalan aman karena kodenya terisolasi dari perubahan yang terjadi pada fitur riwayat.