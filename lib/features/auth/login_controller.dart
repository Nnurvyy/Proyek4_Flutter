class LoginController {
  // Simpan data profil lengkap di sini
  final Map<String, Map<String, dynamic>> _users = {
    'admin': {
      'pass': '123',
      'role': 'Ketua',
      'teamId': 'team_A',
      'uid': 'uid_admin_001'
    },
    'hasbi': {
      'pass': 'hasbi123',
      'role': 'Anggota',
      'teamId': 'team_A',
      'uid': 'uid_hasbi_019'
    },
    'user': {
      'pass': 'user123',
      'role': 'Asisten',
      'teamId': 'team_B',
      'uid': 'uid_user_999'
    },
  };

  // Sekarang fungsi login mengembalikan Map data user jika sukses, atau null jika gagal
  Map<String, dynamic>? login(String username, String password) {
    if (_users.containsKey(username) && _users[username]!['pass'] == password) {
      // Tambahkan username ke dalam map sebelum dikirim balik
      final userData = Map<String, dynamic>.from(_users[username]!);
      userData['username'] = username; 
      return userData;
    }
    return null;
  }
}