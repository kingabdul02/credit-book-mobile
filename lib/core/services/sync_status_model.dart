class SyncStatusModel {
  final int pendingCount;
  final int conflictCount;
  final int failedCount;
  final int syncedCount;
  final String? lastSyncedAt;
  final bool isActive;
  final bool isSyncing;

  const SyncStatusModel({
    required this.pendingCount,
    required this.conflictCount,
    this.failedCount = 0,
    this.syncedCount = 0,
    this.lastSyncedAt,
    this.isActive = true,
    this.isSyncing = false,
  });

  factory SyncStatusModel.fromJson(Map<String, dynamic> json) {
    final sync = json['sync'] as Map<String, dynamic>? ?? json;
    return SyncStatusModel(
      pendingCount: (sync['pending_count'] as int?) ?? 0,
      conflictCount: (sync['conflict_count'] as int?) ?? 0,
      failedCount: (sync['failed_count'] as int?) ?? 0,
      syncedCount: (sync['synced_count'] as int?) ?? 0,
      lastSyncedAt: sync['last_synced_at'] as String?,
      isActive: true,
      isSyncing: (sync['is_syncing'] as bool?) ?? false,
    );
  }

  SyncStatusModel copyWith({
    int? pendingCount,
    int? conflictCount,
    int? failedCount,
    int? syncedCount,
    String? lastSyncedAt,
    bool? isActive,
    bool? isSyncing,
  }) {
    return SyncStatusModel(
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      failedCount: failedCount ?? this.failedCount,
      syncedCount: syncedCount ?? this.syncedCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isActive: isActive ?? this.isActive,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  bool get hasConflicts => conflictCount > 0;
  bool get hasPending => pendingCount > 0;
  bool get hasFailed => failedCount > 0;

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

  static SyncStatusModel get empty => const SyncStatusModel(
        pendingCount: 0,
        conflictCount: 0,
        failedCount: 0,
        syncedCount: 0,
      );
}
