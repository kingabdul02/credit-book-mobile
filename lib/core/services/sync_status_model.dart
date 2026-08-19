class SyncStatusModel {
  final int pendingCount;
  final int conflictCount;
  final String? lastSyncedAt;
  final bool isActive;

  const SyncStatusModel({
    required this.pendingCount,
    required this.conflictCount,
    this.lastSyncedAt,
    this.isActive = true,
  });

  factory SyncStatusModel.fromJson(Map<String, dynamic> json) {
    final sync = json['sync'] as Map<String, dynamic>? ?? json;
    return SyncStatusModel(
      pendingCount: (sync['pending_count'] as int?) ?? 0,
      conflictCount: (sync['conflict_count'] as int?) ?? 0,
      lastSyncedAt: sync['last_synced_at'] as String?,
      isActive: true,
    );
  }

  bool get hasConflicts => conflictCount > 0;
  bool get hasPending => pendingCount > 0;

  bool get isStale {
    if (lastSyncedAt == null) return true;
    final last = DateTime.tryParse(lastSyncedAt!)?.toLocal();
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes > 5;
  }

  String get formattedLastSync {
    if (lastSyncedAt == null) return 'Never synced';
    final date = DateTime.tryParse(lastSyncedAt!)?.toLocal();
    if (date == null) return 'Unknown';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static SyncStatusModel get empty => const SyncStatusModel(pendingCount: 0, conflictCount: 0);
}
