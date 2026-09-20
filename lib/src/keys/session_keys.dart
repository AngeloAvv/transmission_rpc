import 'package:transmission_rpc/src/keys/wire_key.dart';

/// Wire names for every session-scoped RPC field, in both protocol dialects.
///
/// RPC version 18 (Transmission 4.1) renamed the whole session namespace from
/// kebab-case to snake_case, and a handful of fields changed spelling style
/// entirely (`seedRatioLimit` -> `seed_ratio_limit`). Each constant carries the
/// legacy name first and the modern one second, so a single declaration serves
/// both reading responses and building requests.
abstract final class SessionKeys {
  // session-get / session-set

  static const altSpeedDown = WireKey('alt-speed-down', 'alt_speed_down');
  static const altSpeedEnabled = WireKey(
    'alt-speed-enabled',
    'alt_speed_enabled',
  );
  static const altSpeedTimeBegin = WireKey(
    'alt-speed-time-begin',
    'alt_speed_time_begin',
  );
  static const altSpeedTimeDay = WireKey(
    'alt-speed-time-day',
    'alt_speed_time_day',
  );
  static const altSpeedTimeEnabled = WireKey(
    'alt-speed-time-enabled',
    'alt_speed_time_enabled',
  );
  static const altSpeedTimeEnd = WireKey(
    'alt-speed-time-end',
    'alt_speed_time_end',
  );
  static const altSpeedUp = WireKey('alt-speed-up', 'alt_speed_up');
  static const antiBruteForceEnabled = WireKey(
    'anti-brute-force-enabled',
    'anti_brute_force_enabled',
  );
  static const blocklistEnabled = WireKey(
    'blocklist-enabled',
    'blocklist_enabled',
  );

  /// Also the payload of the `blocklist-update` response.
  static const blocklistSize = WireKey('blocklist-size', 'blocklist_size');
  static const blocklistUrl = WireKey('blocklist-url', 'blocklist_url');

  /// The unit changed along with the name: the legacy `cache-size-mb` counts
  /// megabytes (10^6 bytes), while `cache_size_mib` counts mebibytes (2^20
  /// bytes). Values read from a legacy daemon are therefore ~5% larger than
  /// the same cache expressed in MiB.
  static const cacheSizeMib = WireKey('cache-size-mb', 'cache_size_mib');
  static const configDir = WireKey('config-dir', 'config_dir');
  static const defaultTrackers = WireKey(
    'default-trackers',
    'default_trackers',
  );
  static const dhtEnabled = WireKey('dht-enabled', 'dht_enabled');
  static const downloadDir = WireKey('download-dir', 'download_dir');
  static const downloadDirFreeSpace = WireKey(
    'download-dir-free-space',
    'download_dir_free_space',
  );
  static const downloadQueueEnabled = WireKey(
    'download-queue-enabled',
    'download_queue_enabled',
  );
  static const downloadQueueSize = WireKey(
    'download-queue-size',
    'download_queue_size',
  );
  static const encryption = WireKey.same('encryption');
  static const idleSeedingLimit = WireKey(
    'idle-seeding-limit',
    'idle_seeding_limit',
  );
  static const idleSeedingLimitEnabled = WireKey(
    'idle-seeding-limit-enabled',
    'idle_seeding_limit_enabled',
  );
  static const incompleteDir = WireKey('incomplete-dir', 'incomplete_dir');
  static const incompleteDirEnabled = WireKey(
    'incomplete-dir-enabled',
    'incomplete_dir_enabled',
  );
  static const lpdEnabled = WireKey('lpd-enabled', 'lpd_enabled');
  static const peerLimitGlobal = WireKey(
    'peer-limit-global',
    'peer_limit_global',
  );
  static const peerLimitPerTorrent = WireKey(
    'peer-limit-per-torrent',
    'peer_limit_per_torrent',
  );
  static const peerPort = WireKey('peer-port', 'peer_port');
  static const peerPortRandomOnStart = WireKey(
    'peer-port-random-on-start',
    'peer_port_random_on_start',
  );
  static const pexEnabled = WireKey('pex-enabled', 'pex_enabled');
  static const portForwardingEnabled = WireKey(
    'port-forwarding-enabled',
    'port_forwarding_enabled',
  );

  /// Added in Transmission 4.1; legacy daemons never send it.
  static const preferredTransports = WireKey(
    'preferred-transports',
    'preferred_transports',
  );
  static const queueStalledEnabled = WireKey(
    'queue-stalled-enabled',
    'queue_stalled_enabled',
  );
  static const queueStalledMinutes = WireKey(
    'queue-stalled-minutes',
    'queue_stalled_minutes',
  );
  static const renamePartialFiles = WireKey(
    'rename-partial-files',
    'rename_partial_files',
  );
  static const reqq = WireKey.same('reqq');
  static const rpcVersion = WireKey('rpc-version', 'rpc_version');
  static const rpcVersionMinimum = WireKey(
    'rpc-version-minimum',
    'rpc_version_minimum',
  );
  static const rpcVersionSemver = WireKey(
    'rpc-version-semver',
    'rpc_version_semver',
  );
  static const scriptTorrentAddedEnabled = WireKey(
    'script-torrent-added-enabled',
    'script_torrent_added_enabled',
  );
  static const scriptTorrentAddedFilename = WireKey(
    'script-torrent-added-filename',
    'script_torrent_added_filename',
  );
  static const scriptTorrentDoneEnabled = WireKey(
    'script-torrent-done-enabled',
    'script_torrent_done_enabled',
  );
  static const scriptTorrentDoneFilename = WireKey(
    'script-torrent-done-filename',
    'script_torrent_done_filename',
  );
  static const scriptTorrentDoneSeedingEnabled = WireKey(
    'script-torrent-done-seeding-enabled',
    'script_torrent_done_seeding_enabled',
  );
  static const scriptTorrentDoneSeedingFilename = WireKey(
    'script-torrent-done-seeding-filename',
    'script_torrent_done_seeding_filename',
  );
  static const seedQueueEnabled = WireKey(
    'seed-queue-enabled',
    'seed_queue_enabled',
  );
  static const seedQueueSize = WireKey('seed-queue-size', 'seed_queue_size');

  /// One of the few legacy names that was camelCase rather than kebab-case.
  static const seedRatioLimit = WireKey('seedRatioLimit', 'seed_ratio_limit');

  /// Legacy camelCase, like [seedRatioLimit].
  static const seedRatioLimited = WireKey(
    'seedRatioLimited',
    'seed_ratio_limited',
  );

  /// Only exists from RPC 18 (Transmission 4.1) on, so there is no legacy
  /// spelling to fall back to.
  static const sequentialDownload = WireKey.same('sequential_download');
  static const sessionId = WireKey('session-id', 'session_id');
  static const speedLimitDown = WireKey('speed-limit-down', 'speed_limit_down');
  static const speedLimitDownEnabled = WireKey(
    'speed-limit-down-enabled',
    'speed_limit_down_enabled',
  );
  static const speedLimitUp = WireKey('speed-limit-up', 'speed_limit_up');
  static const speedLimitUpEnabled = WireKey(
    'speed-limit-up-enabled',
    'speed_limit_up_enabled',
  );
  static const startAddedTorrents = WireKey(
    'start-added-torrents',
    'start_added_torrents',
  );

  /// Deprecated since Transmission 4.1 in favour of [preferredTransports];
  /// still reported by older daemons.
  static const tcpEnabled = WireKey('tcp-enabled', 'tcp_enabled');
  static const trashOriginalTorrentFiles = WireKey(
    'trash-original-torrent-files',
    'trash_original_torrent_files',
  );
  static const units = WireKey.same('units');

  /// Deprecated since Transmission 4.1 in favour of [preferredTransports];
  /// still reported by older daemons.
  static const utpEnabled = WireKey('utp-enabled', 'utp_enabled');
  static const version = WireKey.same('version');

  // session-get: the nested `units` object

  static const memoryBytes = WireKey('memory-bytes', 'memory_bytes');
  static const memoryUnits = WireKey('memory-units', 'memory_units');
  static const sizeBytes = WireKey('size-bytes', 'size_bytes');
  static const sizeUnits = WireKey('size-units', 'size_units');
  static const speedBytes = WireKey('speed-bytes', 'speed_bytes');
  static const speedUnits = WireKey('speed-units', 'speed_units');

  // session-stats

  static const activeTorrentCount = WireKey(
    'activeTorrentCount',
    'active_torrent_count',
  );
  static const downloadSpeed = WireKey('downloadSpeed', 'download_speed');
  static const pausedTorrentCount = WireKey(
    'pausedTorrentCount',
    'paused_torrent_count',
  );
  static const torrentCount = WireKey('torrentCount', 'torrent_count');
  static const uploadSpeed = WireKey('uploadSpeed', 'upload_speed');

  /// The two nested stats objects are kebab-case in the legacy dialect even
  /// though their contents are camelCase.
  static const cumulativeStats = WireKey(
    'cumulative-stats',
    'cumulative_stats',
  );
  static const currentStats = WireKey('current-stats', 'current_stats');
  static const uploadedBytes = WireKey('uploadedBytes', 'uploaded_bytes');
  static const downloadedBytes = WireKey('downloadedBytes', 'downloaded_bytes');
  static const filesAdded = WireKey('filesAdded', 'files_added');
  static const sessionCount = WireKey('sessionCount', 'session_count');
  static const secondsActive = WireKey('secondsActive', 'seconds_active');

  // free-space

  static const path = WireKey.same('path');
  static const freeSpaceSizeBytes = WireKey('size-bytes', 'size_bytes');

  /// Added in Transmission 4.0 and already snake_case there, so both dialects
  /// spell it the same way; daemons older than 4.0 omit it entirely.
  static const totalSize = WireKey.same('total_size');

  // groups

  /// The key the `group-get` response nests its list of groups under.
  ///
  /// The request argument that selects a single group is a different name:
  /// `group` on legacy daemons, `name` from RPC 18 on — use [groupName] for
  /// that, not this constant.
  static const group = WireKey.same('group');
  static const honorsSessionLimits = WireKey(
    'honorsSessionLimits',
    'honors_session_limits',
  );
  static const groupName = WireKey.same('name');
  static const groupSpeedLimitDown = WireKey(
    'speed-limit-down',
    'speed_limit_down',
  );
  static const groupSpeedLimitDownEnabled = WireKey(
    'speed-limit-down-enabled',
    'speed_limit_down_enabled',
  );
  static const groupSpeedLimitUp = WireKey('speed-limit-up', 'speed_limit_up');
  static const groupSpeedLimitUpEnabled = WireKey(
    'speed-limit-up-enabled',
    'speed_limit_up_enabled',
  );

  // port-test

  static const portIsOpen = WireKey('port-is-open', 'port_is_open');

  /// The `port-test` request argument and response field.
  ///
  /// Only exists from Transmission 4.1 on — before that `port-test` took no
  /// arguments and daemons simply ignore the extra one.
  static const ipProtocol = WireKey('ipProtocol', 'ip_protocol');
}
