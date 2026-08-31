enum AuthPhase {
  /// Lagi ngecek secure storage pas app baru buka.
  loading,

  /// Belum ada token — perlu login.
  loggedOut,

  /// Baru login, belum ada PIN — perlu setup PIN dulu.
  needsPinSetup,

  /// Ada token & PIN, tapi session ini belum di-unlock.
  locked,

  /// Siap dipake.
  unlocked,
}
