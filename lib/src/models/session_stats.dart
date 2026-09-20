import 'package:transmission_rpc/src/json.dart';
import 'package:transmission_rpc/src/keys/session_keys.dart';

/// Transfer totals accumulated over a period, as reported by `session-stats`.
class Stats {
  /// Bytes uploaded during the period.
  final int? uploadedBytes;

  /// Bytes downloaded during the period.
  final int? downloadedBytes;

  /// Number of files added during the period.
  final int? filesAdded;

  /// Number of daemon sessions counted in the period.
  final int? sessionCount;

  /// Seconds the daemon was running during the period.
  final int? secondsActive;

  const Stats({
    this.uploadedBytes,
    this.downloadedBytes,
    this.filesAdded,
    this.sessionCount,
    this.secondsActive,
  });

  /// Parses a `cumulative-stats` or `current-stats` object.
  factory Stats.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Stats(
      uploadedBytes: reader.intOf(SessionKeys.uploadedBytes),
      downloadedBytes: reader.intOf(SessionKeys.downloadedBytes),
      filesAdded: reader.intOf(SessionKeys.filesAdded),
      sessionCount: reader.intOf(SessionKeys.sessionCount),
      secondsActive: reader.intOf(SessionKeys.secondsActive),
    );
  }
}

/// Live counters and transfer totals for the daemon, as returned by the
/// `session-stats` method.
class SessionStats {
  /// Torrents currently transferring data.
  final int? activeTorrentCount;

  /// Aggregate download rate, in bytes per second.
  final int? downloadSpeed;

  /// Torrents currently paused.
  final int? pausedTorrentCount;

  /// Total torrents known to the daemon.
  final int? torrentCount;

  /// Aggregate upload rate, in bytes per second.
  final int? uploadSpeed;

  /// Totals accumulated since the daemon was first configured.
  final Stats? cumulativeStats;

  /// Totals accumulated since the daemon last started.
  final Stats? currentStats;

  const SessionStats({
    this.activeTorrentCount,
    this.downloadSpeed,
    this.pausedTorrentCount,
    this.torrentCount,
    this.uploadSpeed,
    this.cumulativeStats,
    this.currentStats,
  });

  /// Parses the `arguments` object of a `session-stats` response.
  factory SessionStats.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return SessionStats(
      activeTorrentCount: reader.intOf(SessionKeys.activeTorrentCount),
      downloadSpeed: reader.intOf(SessionKeys.downloadSpeed),
      pausedTorrentCount: reader.intOf(SessionKeys.pausedTorrentCount),
      torrentCount: reader.intOf(SessionKeys.torrentCount),
      uploadSpeed: reader.intOf(SessionKeys.uploadSpeed),
      cumulativeStats: reader.objectOf(
        SessionKeys.cumulativeStats,
        Stats.fromJson,
      ),
      currentStats: reader.objectOf(SessionKeys.currentStats, Stats.fromJson),
    );
  }
}
