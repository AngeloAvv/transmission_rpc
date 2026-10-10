import 'package:transmission_rpc/src/json.dart';
import 'package:transmission_rpc/src/keys/session_keys.dart';

/// The peer connection encryption policy a daemon enforces.
enum SessionEncryption {
  /// Refuse unencrypted peer connections.
  required,

  /// Prefer encrypted peers but accept plaintext ones.
  preferred,

  /// Accept whatever the peer offers.
  allowed;

  /// Parses the wire spelling, accepting the pre-2.x name `tolerated` as an
  /// alias of [allowed].
  static SessionEncryption? fromWire(String? value) => switch (value) {
    'required' => SessionEncryption.required,
    'preferred' => SessionEncryption.preferred,
    'tolerated' || 'allowed' => SessionEncryption.allowed,
    _ => null,
  };

  /// The spelling to send to a daemon speaking [rpcVersion].
  ///
  /// [allowed] was called `tolerated` before RPC 18, and a legacy daemon that
  /// does not recognise the value silently falls back to [preferred] — so the
  /// version matters here.
  String wireValue(int rpcVersion) => switch (this) {
    SessionEncryption.required => 'required',
    SessionEncryption.preferred => 'preferred',
    SessionEncryption.allowed => rpcVersion >= 18 ? 'allowed' : 'tolerated',
  };
}

/// The unit names and multipliers a daemon uses when formatting sizes, speeds
/// and memory amounts in its own UI.
class Units {
  /// Bytes per memory unit step (usually 1024).
  final int? memoryBytes;

  /// Memory unit labels, smallest first (`KiB`, `MiB`, ...).
  final List<String>? memoryUnits;

  /// Bytes per size unit step.
  final int? sizeBytes;

  /// Size unit labels, smallest first.
  final List<String>? sizeUnits;

  /// Bytes per speed unit step.
  final int? speedBytes;

  /// Speed unit labels, smallest first.
  final List<String>? speedUnits;

  const Units({
    this.memoryBytes,
    this.memoryUnits,
    this.sizeBytes,
    this.sizeUnits,
    this.speedBytes,
    this.speedUnits,
  });

  /// Parses a `units` object from a `session-get` response.
  factory Units.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Units(
      memoryBytes: reader.intOf(SessionKeys.memoryBytes),
      memoryUnits: reader.listOf<String>(SessionKeys.memoryUnits),
      sizeBytes: reader.intOf(SessionKeys.sizeBytes),
      sizeUnits: reader.listOf<String>(SessionKeys.sizeUnits),
      speedBytes: reader.intOf(SessionKeys.speedBytes),
      speedUnits: reader.listOf<String>(SessionKeys.speedUnits),
    );
  }
}

/// A snapshot of a Transmission daemon's session settings and identity, as
/// returned by the `session-get` method.
///
/// Every field is nullable: a daemon only reports the settings it knows about,
/// and a `session-get` call restricted to a field subset fills in the rest with
/// nulls.
class Session {
  /// Alternative ("turtle") download speed limit, in KB/s.
  final int? altSpeedDown;
  final bool? altSpeedEnabled;
  final int? altSpeedTimeBegin;
  final int? altSpeedTimeDay;
  final bool? altSpeedTimeEnabled;
  final int? altSpeedTimeEnd;

  /// Alternative ("turtle") upload speed limit, in KB/s.
  final int? altSpeedUp;
  final bool? antiBruteForceEnabled;
  final bool? blocklistEnabled;
  final int? blocklistSize;
  final String? blocklistUrl;

  /// Disk cache size. Modern daemons report mebibytes; daemons older than
  /// Transmission 4.1 report megabytes under `cache-size-mb`.
  final int? cacheSizeMib;
  final String? configDir;
  final String? defaultTrackers;
  final bool? dhtEnabled;
  final String? downloadDir;
  final int? downloadDirFreeSpace;
  final bool? downloadQueueEnabled;
  final int? downloadQueueSize;
  final SessionEncryption? encryption;
  final bool? idleSeedingLimitEnabled;
  final int? idleSeedingLimit;
  final bool? incompleteDirEnabled;
  final String? incompleteDir;
  final bool? lpdEnabled;
  final int? peerLimitGlobal;
  final int? peerLimitPerTorrent;
  final bool? peerPortRandomOnStart;
  final int? peerPort;

  /// Transport preference order, Transmission 4.1+ only.
  final List<String>? preferredTransports;
  final bool? pexEnabled;
  final bool? portForwardingEnabled;
  final bool? queueStalledEnabled;
  final int? queueStalledMinutes;
  final int? reqq;
  final bool? renamePartialFiles;
  final int? rpcVersionMinimum;
  final String? rpcVersionSemver;
  final int? rpcVersion;
  final bool? scriptTorrentAddedEnabled;
  final String? scriptTorrentAddedFilename;
  final bool? scriptTorrentDoneEnabled;
  final String? scriptTorrentDoneFilename;
  final bool? scriptTorrentDoneSeedingEnabled;
  final String? scriptTorrentDoneSeedingFilename;
  final bool? seedQueueEnabled;
  final int? seedQueueSize;
  final double? seedRatioLimit;
  final bool? seedRatioLimited;
  final bool? sessionSequentialDownload;
  final String? sessionId;
  final bool? speedLimitDownEnabled;
  final int? speedLimitDown;
  final bool? speedLimitUpEnabled;
  final int? speedLimitUp;
  final bool? startAddedTorrents;
  final bool? trashOriginalTorrentFiles;

  /// Deprecated since Transmission 4.1 in favour of [preferredTransports].
  final bool? tcpEnabled;
  final Units? units;

  /// Deprecated since Transmission 4.1 in favour of [preferredTransports].
  final bool? utpEnabled;
  final String? version;

  const Session({
    this.altSpeedDown,
    this.altSpeedEnabled,
    this.altSpeedTimeBegin,
    this.altSpeedTimeDay,
    this.altSpeedTimeEnabled,
    this.altSpeedTimeEnd,
    this.altSpeedUp,
    this.antiBruteForceEnabled,
    this.blocklistEnabled,
    this.blocklistSize,
    this.blocklistUrl,
    this.cacheSizeMib,
    this.configDir,
    this.defaultTrackers,
    this.dhtEnabled,
    this.downloadDir,
    this.downloadDirFreeSpace,
    this.downloadQueueEnabled,
    this.downloadQueueSize,
    this.encryption,
    this.idleSeedingLimitEnabled,
    this.idleSeedingLimit,
    this.incompleteDirEnabled,
    this.incompleteDir,
    this.lpdEnabled,
    this.peerLimitGlobal,
    this.peerLimitPerTorrent,
    this.peerPortRandomOnStart,
    this.peerPort,
    this.preferredTransports,
    this.pexEnabled,
    this.portForwardingEnabled,
    this.queueStalledEnabled,
    this.queueStalledMinutes,
    this.reqq,
    this.renamePartialFiles,
    this.rpcVersionMinimum,
    this.rpcVersionSemver,
    this.rpcVersion,
    this.scriptTorrentAddedEnabled,
    this.scriptTorrentAddedFilename,
    this.scriptTorrentDoneEnabled,
    this.scriptTorrentDoneFilename,
    this.scriptTorrentDoneSeedingEnabled,
    this.scriptTorrentDoneSeedingFilename,
    this.seedQueueEnabled,
    this.seedQueueSize,
    this.seedRatioLimit,
    this.seedRatioLimited,
    this.sessionSequentialDownload,
    this.sessionId,
    this.speedLimitDownEnabled,
    this.speedLimitDown,
    this.speedLimitUpEnabled,
    this.speedLimitUp,
    this.startAddedTorrents,
    this.trashOriginalTorrentFiles,
    this.tcpEnabled,
    this.units,
    this.utpEnabled,
    this.version,
  });

  /// Parses the `arguments` object of a `session-get` response, from a daemon
  /// speaking either protocol dialect.
  factory Session.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Session(
      altSpeedDown: reader.intOf(SessionKeys.altSpeedDown),
      altSpeedEnabled: reader.boolOf(SessionKeys.altSpeedEnabled),
      altSpeedTimeBegin: reader.intOf(SessionKeys.altSpeedTimeBegin),
      altSpeedTimeDay: reader.intOf(SessionKeys.altSpeedTimeDay),
      altSpeedTimeEnabled: reader.boolOf(SessionKeys.altSpeedTimeEnabled),
      altSpeedTimeEnd: reader.intOf(SessionKeys.altSpeedTimeEnd),
      altSpeedUp: reader.intOf(SessionKeys.altSpeedUp),
      antiBruteForceEnabled: reader.boolOf(SessionKeys.antiBruteForceEnabled),
      blocklistEnabled: reader.boolOf(SessionKeys.blocklistEnabled),
      blocklistSize: reader.intOf(SessionKeys.blocklistSize),
      blocklistUrl: reader.stringOf(SessionKeys.blocklistUrl),
      cacheSizeMib: reader.intOf(SessionKeys.cacheSizeMib),
      configDir: reader.stringOf(SessionKeys.configDir),
      defaultTrackers: reader.stringOf(SessionKeys.defaultTrackers),
      dhtEnabled: reader.boolOf(SessionKeys.dhtEnabled),
      downloadDir: reader.stringOf(SessionKeys.downloadDir),
      downloadDirFreeSpace: reader.intOf(SessionKeys.downloadDirFreeSpace),
      downloadQueueEnabled: reader.boolOf(SessionKeys.downloadQueueEnabled),
      downloadQueueSize: reader.intOf(SessionKeys.downloadQueueSize),
      encryption: SessionEncryption.fromWire(
        reader.stringOf(SessionKeys.encryption),
      ),
      idleSeedingLimitEnabled: reader.boolOf(
        SessionKeys.idleSeedingLimitEnabled,
      ),
      idleSeedingLimit: reader.intOf(SessionKeys.idleSeedingLimit),
      incompleteDirEnabled: reader.boolOf(SessionKeys.incompleteDirEnabled),
      incompleteDir: reader.stringOf(SessionKeys.incompleteDir),
      lpdEnabled: reader.boolOf(SessionKeys.lpdEnabled),
      peerLimitGlobal: reader.intOf(SessionKeys.peerLimitGlobal),
      peerLimitPerTorrent: reader.intOf(SessionKeys.peerLimitPerTorrent),
      peerPortRandomOnStart: reader.boolOf(SessionKeys.peerPortRandomOnStart),
      peerPort: reader.intOf(SessionKeys.peerPort),
      preferredTransports: reader.listOf<String>(
        SessionKeys.preferredTransports,
      ),
      pexEnabled: reader.boolOf(SessionKeys.pexEnabled),
      portForwardingEnabled: reader.boolOf(SessionKeys.portForwardingEnabled),
      queueStalledEnabled: reader.boolOf(SessionKeys.queueStalledEnabled),
      queueStalledMinutes: reader.intOf(SessionKeys.queueStalledMinutes),
      reqq: reader.intOf(SessionKeys.reqq),
      renamePartialFiles: reader.boolOf(SessionKeys.renamePartialFiles),
      rpcVersionMinimum: reader.intOf(SessionKeys.rpcVersionMinimum),
      rpcVersionSemver: reader.stringOf(SessionKeys.rpcVersionSemver),
      rpcVersion: reader.intOf(SessionKeys.rpcVersion),
      scriptTorrentAddedEnabled: reader.boolOf(
        SessionKeys.scriptTorrentAddedEnabled,
      ),
      scriptTorrentAddedFilename: reader.stringOf(
        SessionKeys.scriptTorrentAddedFilename,
      ),
      scriptTorrentDoneEnabled: reader.boolOf(
        SessionKeys.scriptTorrentDoneEnabled,
      ),
      scriptTorrentDoneFilename: reader.stringOf(
        SessionKeys.scriptTorrentDoneFilename,
      ),
      scriptTorrentDoneSeedingEnabled: reader.boolOf(
        SessionKeys.scriptTorrentDoneSeedingEnabled,
      ),
      scriptTorrentDoneSeedingFilename: reader.stringOf(
        SessionKeys.scriptTorrentDoneSeedingFilename,
      ),
      seedQueueEnabled: reader.boolOf(SessionKeys.seedQueueEnabled),
      seedQueueSize: reader.intOf(SessionKeys.seedQueueSize),
      seedRatioLimit: reader.doubleOf(SessionKeys.seedRatioLimit),
      seedRatioLimited: reader.boolOf(SessionKeys.seedRatioLimited),
      sessionSequentialDownload: reader.boolOf(SessionKeys.sequentialDownload),
      sessionId: reader.stringOf(SessionKeys.sessionId),
      speedLimitDownEnabled: reader.boolOf(SessionKeys.speedLimitDownEnabled),
      speedLimitDown: reader.intOf(SessionKeys.speedLimitDown),
      speedLimitUpEnabled: reader.boolOf(SessionKeys.speedLimitUpEnabled),
      speedLimitUp: reader.intOf(SessionKeys.speedLimitUp),
      startAddedTorrents: reader.boolOf(SessionKeys.startAddedTorrents),
      trashOriginalTorrentFiles: reader.boolOf(
        SessionKeys.trashOriginalTorrentFiles,
      ),
      tcpEnabled: reader.boolOf(SessionKeys.tcpEnabled),
      units: reader.objectOf(SessionKeys.units, Units.fromJson),
      utpEnabled: reader.boolOf(SessionKeys.utpEnabled),
      version: reader.stringOf(SessionKeys.version),
    );
  }
}
