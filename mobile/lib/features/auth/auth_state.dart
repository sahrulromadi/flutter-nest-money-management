enum AuthPhase {
  /// Lagi ngecek secure storage pas app baru buka.
  loading,

  /// Belum ada token — perlu login.
  loggedOut,

  /// Ada token, siap dipakai. (Fitur PIN/biometric dihapus — plan 025.)
  unlocked,
}
