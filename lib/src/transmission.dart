import 'dart:convert';
import 'dart:io';

import 'package:transmission_rpc/src/fields.dart';
import 'package:transmission_rpc/src/json.dart';
import 'package:transmission_rpc/src/errors.dart';
import 'package:transmission_rpc/src/keys/session_keys.dart';
import 'package:transmission_rpc/src/keys/wire_key.dart';
import 'package:transmission_rpc/src/keys/torrent_keys.dart';
import 'package:transmission_rpc/src/models/free_space.dart';
import 'package:transmission_rpc/src/models/group.dart';
import 'package:transmission_rpc/src/models/ip_protocol.dart';
import 'package:transmission_rpc/src/models/session.dart';
import 'package:transmission_rpc/src/models/session_stats.dart';
import 'package:transmission_rpc/src/models/test_port.dart';
import 'package:transmission_rpc/src/models/torrent.dart';
import 'package:transmission_rpc/src/rpc_client.dart';
import 'package:dio/dio.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

/// Default address of a Transmission daemon on the local machine.
const _defaultBaseUrl = 'http://localhost:9091/transmission/rpc';

/// A client for a Transmission daemon.
///
/// ```dart
/// final transmission = Transmission(baseUrl: 'http://nas:9091/transmission/rpc');
/// for (final torrent in await transmission.torrents()) {
///   print('${torrent.name}: ${torrent.percentDone}');
/// }
/// ```
///
/// The RPC dialect of the daemon is detected on the fly, so the same code works
/// against Transmission 2.x, 3.x and 4.x. Every method throws
/// [AuthenticationError], [RpcError] or [NetworkError] on failure.
class Transmission {
  final RpcClient _client;
  final Talker? _logger;

  Transmission._(this._client, this._logger);

  /// Connects to the daemon at [baseUrl].
  ///
  /// [username] and [password] are sent as HTTP basic auth when both are given.
  /// Pass [logLevel] to switch logging on: requests, responses and errors are
  /// then written to [talker], or to a private [Talker] when none is supplied.
  /// Pass [httpClient] to supply a pre-configured [Dio] — useful for proxies,
  /// custom certificates, or a fake adapter in tests; [baseUrl] and [timeout]
  /// are applied to it as well.
  factory Transmission({
    String baseUrl = _defaultBaseUrl,
    String? username,
    String? password,
    LogLevel? logLevel,
    Talker? talker,
    Duration timeout = const Duration(seconds: 30),
    Dio? httpClient,
  }) {
    final logger = logLevel == null
        ? null
        : talker ??
              Talker(
                logger: TalkerLogger(
                  settings: TalkerLoggerSettings(level: logLevel),
                ),
              );

    final dio = httpClient ?? Dio();
    dio.options = dio.options.copyWith(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      sendTimeout: timeout,
      receiveTimeout: timeout,
      headers: {
        ...dio.options.headers,
        if (username != null && password != null)
          HttpHeaders.authorizationHeader:
              'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
    );

    if (logger != null) {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: logger,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: true,
            printResponseMessage: true,
          ),
        ),
      );
    }

    return Transmission._(RpcClient(dio, logger: logger), logger);
  }

  /// RPC version of the connected daemon.
  ///
  /// 17 until the daemon reveals a newer one; 18 or above means the daemon
  /// speaks the JSON-RPC 2.0 dialect of Transmission 4.1+.
  int get rpcVersion => _client.rpcVersion;

  /// Semver version of the RPC protocol the daemon speaks (for example
  /// `5.3.0` for Transmission 4.0, `6.0.0` for 4.1).
  ///
  /// Null until a call that carries it — such as [session] — has completed.
  String? get rpcVersionSemver => _client.rpcVersionSemver;

  Map<String, dynamic> _args(Map<WireKey, Object?> entries) =>
      rpcArgs(_client.rpcVersion, entries);

  // ---------------------------------------------------------------------------
  // Torrents
  // ---------------------------------------------------------------------------

  /// Returns the torrents known to the daemon, each carrying [fields].
  Future<List<Torrent>> torrents({
    List<TorrentField> fields = TorrentField.defaults,
  }) => _torrents(fields, null);

  /// Returns the torrents that changed since the previous call, plus the ids of
  /// the ones that were removed being dropped — the daemon's `recently-active`
  /// filter.
  Future<List<Torrent>> activeTorrents({
    List<TorrentField> fields = TorrentField.defaults,
  }) => _torrents(
    fields,
    // The sentinel itself was renamed by RPC 18, like everything else.
    _client.rpcVersion >= 18 ? 'recently_active' : 'recently-active',
  );

  Future<List<Torrent>> _torrents(
    List<TorrentField> fields,
    Object? ids,
  ) async {
    final result = await _client.call('torrent-get', {
      // `fields` and `ids` are spelled the same in both dialects.
      'fields': fields
          .map((field) => field.wireName(_client.rpcVersion))
          .toList(growable: false),
      if (ids != null) 'ids': ids,
    });
    final torrents = result['torrents'];
    if (torrents is! List) return const [];
    return torrents
        .map((torrent) => Torrent.fromJson(Map<String, dynamic>.from(torrent as Map)))
        .toList(growable: false);
  }

  /// Adds a torrent, either from a [filename] (a path, URL or magnet link) or
  /// from base64-encoded `.torrent` contents in [metainfo].
  ///
  /// The returned [AddTorrentResult] carries the torrent the daemon now holds
  /// and whether it was already there.
  Future<AddTorrentResult> addTorrent({
    String? filename,
    String? metainfo,
    String? downloadDir,
    String? cookies,
    List<String>? labels,
    bool? paused,
    int? peerLimit,
    int? bandwidthPriority,
    List<int>? filesWanted,
    List<int>? filesUnwanted,
    List<int>? priorityHigh,
    List<int>? priorityLow,
    List<int>? priorityNormal,
    int? sequentialDownloadFromPiece,
  }) async {
    _logger?.info('Adding torrent ${filename ?? '<metainfo>'}');
    final result = await _client.call(
      'torrent-add',
      _args({
        TorrentKeys.filename: filename,
        TorrentKeys.metainfo: metainfo,
        TorrentKeys.addDownloadDir: downloadDir,
        TorrentKeys.cookies: cookies,
        TorrentKeys.labels: labels,
        TorrentKeys.paused: paused,
        TorrentKeys.peerLimit: peerLimit,
        TorrentKeys.bandwidthPriority: bandwidthPriority,
        TorrentKeys.filesWanted: filesWanted,
        TorrentKeys.filesUnwanted: filesUnwanted,
        TorrentKeys.priorityHigh: priorityHigh,
        TorrentKeys.priorityLow: priorityLow,
        TorrentKeys.priorityNormal: priorityNormal,
        TorrentKeys.sequentialDownloadFromPiece: sequentialDownloadFromPiece,
      }),
    );

    final reader = Json(result);
    final added = reader.objectOf(TorrentKeys.torrentAdded, Torrent.fromJson);
    if (added != null) return AddTorrentResult(torrent: added);

    final duplicate = reader.objectOf(
      TorrentKeys.torrentDuplicate,
      Torrent.fromJson,
    );
    if (duplicate != null) {
      return AddTorrentResult(torrent: duplicate, isDuplicate: true);
    }

    throw const RpcError('torrent-add returned no torrent');
  }

  /// Removes the torrents [ids], optionally deleting the downloaded data.
  Future<void> removeTorrents(
    List<int> ids, {
    bool deleteLocalData = false,
  }) async {
    await _client.call(
      'torrent-remove',
      _args({
        TorrentKeys.ids: ids,
        TorrentKeys.deleteLocalData: deleteLocalData,
      }),
    );
  }

  /// Moves the torrents [ids] to [location], relocating their data when [move]
  /// is true and simply looking for it there when it is false.
  Future<void> moveTorrents(
    List<int> ids, {
    required String location,
    bool move = false,
  }) async {
    await _client.call(
      'torrent-set-location',
      _args({
        TorrentKeys.ids: ids,
        TorrentKeys.location: location,
        TorrentKeys.move: move,
      }),
    );
  }

  /// Renames [path] inside the torrents [ids] to [name].
  Future<void> renameTorrent(
    List<int> ids, {
    String? name,
    String? path,
  }) async {
    await _client.call(
      'torrent-rename-path',
      _args({
        TorrentKeys.ids: ids,
        TorrentKeys.name: name,
        TorrentKeys.path: path,
      }),
    );
  }

  /// Starts the torrents [ids], respecting the download queue.
  Future<void> startTorrents(List<int> ids) =>
      _torrentAction('torrent-start', ids);

  /// Starts the torrents [ids] immediately, bypassing the download queue.
  Future<void> startTorrentsNow(List<int> ids) =>
      _torrentAction('torrent-start-now', ids);

  /// Stops the torrents [ids].
  Future<void> stopTorrents(List<int> ids) =>
      _torrentAction('torrent-stop', ids);

  /// Asks the daemon to re-announce the torrents [ids] to their trackers.
  Future<void> reannounceTorrents(List<int> ids) =>
      _torrentAction('torrent-reannounce', ids);

  /// Verifies the local data of the torrents [ids].
  Future<void> verifyTorrents(List<int> ids) =>
      _torrentAction('torrent-verify', ids);

  /// Moves the torrents [ids] to the top of the queue.
  Future<void> moveQueueOnTop(List<int> ids) =>
      _torrentAction('queue-move-top', ids);

  /// Moves the torrents [ids] one position up in the queue.
  Future<void> moveQueueUp(List<int> ids) =>
      _torrentAction('queue-move-up', ids);

  /// Moves the torrents [ids] one position down in the queue.
  Future<void> moveQueueDown(List<int> ids) =>
      _torrentAction('queue-move-down', ids);

  /// Moves the torrents [ids] to the bottom of the queue.
  Future<void> moveQueueOnBottom(List<int> ids) =>
      _torrentAction('queue-move-bottom', ids);

  Future<void> _torrentAction(String method, List<int> ids) async {
    _logger?.info('$method $ids');
    await _client.call(method, _args({TorrentKeys.ids: ids}));
  }

  /// Changes settings of the torrents [ids].
  ///
  /// Only the arguments that are non-null are sent.
  Future<void> setTorrents({
    List<int>? ids,
    int? bandwidthPriority,
    int? downloadLimit,
    bool? downloadLimited,
    List<int>? filesUnwanted,
    List<int>? filesWanted,
    String? group,
    bool? honorsSessionLimits,
    List<String>? labels,
    String? location,
    int? peerLimit,
    List<int>? priorityHigh,
    List<int>? priorityLow,
    List<int>? priorityNormal,
    int? queuePosition,
    int? seedIdleLimit,
    int? seedIdleMode,
    double? seedRatioLimit,
    int? seedRatioMode,
    bool? sequentialDownload,
    int? sequentialDownloadFromPiece,
    String? trackerList,
    @Deprecated('Deprecated since Transmission 4.0; use trackerList instead')
    List<String>? trackerAdd,
    @Deprecated('Deprecated since Transmission 4.0; use trackerList instead')
    List<String>? trackerRemove,
    @Deprecated('Deprecated since Transmission 4.0; use trackerList instead')
    List<String>? trackerReplace,
    int? uploadLimit,
    bool? uploadLimited,
  }) async {
    _logger?.info('Updating torrent(s) $ids');
    await _client.call(
      'torrent-set',
      _args({
        TorrentKeys.ids: ids,
        TorrentKeys.bandwidthPriority: bandwidthPriority,
        TorrentKeys.downloadLimit: downloadLimit,
        TorrentKeys.downloadLimited: downloadLimited,
        TorrentKeys.filesUnwanted: filesUnwanted,
        TorrentKeys.filesWanted: filesWanted,
        TorrentKeys.group: group,
        TorrentKeys.honorsSessionLimits: honorsSessionLimits,
        TorrentKeys.labels: labels,
        TorrentKeys.location: location,
        TorrentKeys.peerLimit: peerLimit,
        TorrentKeys.priorityHigh: priorityHigh,
        TorrentKeys.priorityLow: priorityLow,
        TorrentKeys.priorityNormal: priorityNormal,
        TorrentKeys.queuePosition: queuePosition,
        TorrentKeys.seedIdleLimit: seedIdleLimit,
        TorrentKeys.seedIdleMode: seedIdleMode,
        TorrentKeys.seedRatioLimit: seedRatioLimit,
        TorrentKeys.seedRatioMode: seedRatioMode,
        TorrentKeys.sequentialDownload: sequentialDownload,
        TorrentKeys.sequentialDownloadFromPiece: sequentialDownloadFromPiece,
        TorrentKeys.trackerList: trackerList,
        TorrentKeys.trackerAdd: trackerAdd,
        TorrentKeys.trackerRemove: trackerRemove,
        TorrentKeys.trackerReplace: trackerReplace,
        TorrentKeys.uploadLimit: uploadLimit,
        TorrentKeys.uploadLimited: uploadLimited,
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Returns the daemon's settings.
  ///
  /// This is also what teaches the client which RPC dialect the daemon speaks,
  /// so calling it once after connecting is a good idea.
  Future<Session> session() async {
    final result = await _client.call('session-get');
    return Session.fromJson(result);
  }

  /// Changes the daemon's settings. Only non-null arguments are sent.
  Future<void> setSession({
    int? altSpeedDown,
    bool? altSpeedEnabled,
    int? altSpeedTimeBegin,
    int? altSpeedTimeDay,
    bool? altSpeedTimeEnabled,
    int? altSpeedTimeEnd,
    int? altSpeedUp,
    bool? blocklistEnabled,
    String? blocklistUrl,
    int? cacheSizeMib,
    String? defaultTrackers,
    bool? dhtEnabled,
    String? downloadDir,
    bool? downloadQueueEnabled,
    int? downloadQueueSize,
    SessionEncryption? encryption,
    bool? idleSeedingLimitEnabled,
    int? idleSeedingLimit,
    bool? incompleteDirEnabled,
    String? incompleteDir,
    bool? lpdEnabled,
    int? peerLimitGlobal,
    int? peerLimitPerTorrent,
    bool? peerPortRandomOnStart,
    int? peerPort,
    bool? pexEnabled,
    bool? portForwardingEnabled,
    List<String>? preferredTransports,
    bool? queueStalledEnabled,
    int? queueStalledMinutes,
    bool? renamePartialFiles,
    bool? scriptTorrentAddedEnabled,
    String? scriptTorrentAddedFilename,
    bool? scriptTorrentDoneEnabled,
    String? scriptTorrentDoneFilename,
    bool? scriptTorrentDoneSeedingEnabled,
    String? scriptTorrentDoneSeedingFilename,
    bool? seedQueueEnabled,
    int? seedQueueSize,
    double? seedRatioLimit,
    bool? seedRatioLimited,
    bool? sequentialDownload,
    bool? speedLimitDownEnabled,
    int? speedLimitDown,
    bool? speedLimitUpEnabled,
    int? speedLimitUp,
    bool? startAddedTorrents,
    @Deprecated(
      'Deprecated since Transmission 4.1; use preferredTransports instead',
    )
    bool? tcpEnabled,
    bool? trashOriginalTorrentFiles,
    @Deprecated(
      'Deprecated since Transmission 4.1; use preferredTransports instead',
    )
    bool? utpEnabled,
  }) async {
    _logger?.info('Updating session settings');
    await _client.call(
      'session-set',
      _args({
        SessionKeys.altSpeedDown: altSpeedDown,
        SessionKeys.altSpeedEnabled: altSpeedEnabled,
        SessionKeys.altSpeedTimeBegin: altSpeedTimeBegin,
        SessionKeys.altSpeedTimeDay: altSpeedTimeDay,
        SessionKeys.altSpeedTimeEnabled: altSpeedTimeEnabled,
        SessionKeys.altSpeedTimeEnd: altSpeedTimeEnd,
        SessionKeys.altSpeedUp: altSpeedUp,
        SessionKeys.blocklistEnabled: blocklistEnabled,
        SessionKeys.blocklistUrl: blocklistUrl,
        SessionKeys.cacheSizeMib: cacheSizeMib,
        SessionKeys.defaultTrackers: defaultTrackers,
        SessionKeys.dhtEnabled: dhtEnabled,
        SessionKeys.downloadDir: downloadDir,
        SessionKeys.downloadQueueEnabled: downloadQueueEnabled,
        SessionKeys.downloadQueueSize: downloadQueueSize,
        SessionKeys.encryption: encryption?.wireValue(_client.rpcVersion),
        SessionKeys.idleSeedingLimitEnabled: idleSeedingLimitEnabled,
        SessionKeys.idleSeedingLimit: idleSeedingLimit,
        SessionKeys.incompleteDirEnabled: incompleteDirEnabled,
        SessionKeys.incompleteDir: incompleteDir,
        SessionKeys.lpdEnabled: lpdEnabled,
        SessionKeys.peerLimitGlobal: peerLimitGlobal,
        SessionKeys.peerLimitPerTorrent: peerLimitPerTorrent,
        SessionKeys.peerPortRandomOnStart: peerPortRandomOnStart,
        SessionKeys.peerPort: peerPort,
        SessionKeys.pexEnabled: pexEnabled,
        SessionKeys.portForwardingEnabled: portForwardingEnabled,
        SessionKeys.preferredTransports: preferredTransports,
        SessionKeys.queueStalledEnabled: queueStalledEnabled,
        SessionKeys.queueStalledMinutes: queueStalledMinutes,
        SessionKeys.renamePartialFiles: renamePartialFiles,
        SessionKeys.scriptTorrentAddedEnabled: scriptTorrentAddedEnabled,
        SessionKeys.scriptTorrentAddedFilename: scriptTorrentAddedFilename,
        SessionKeys.scriptTorrentDoneEnabled: scriptTorrentDoneEnabled,
        SessionKeys.scriptTorrentDoneFilename: scriptTorrentDoneFilename,
        SessionKeys.scriptTorrentDoneSeedingEnabled:
            scriptTorrentDoneSeedingEnabled,
        SessionKeys.scriptTorrentDoneSeedingFilename:
            scriptTorrentDoneSeedingFilename,
        SessionKeys.seedQueueEnabled: seedQueueEnabled,
        SessionKeys.seedQueueSize: seedQueueSize,
        SessionKeys.seedRatioLimit: seedRatioLimit,
        SessionKeys.seedRatioLimited: seedRatioLimited,
        SessionKeys.sequentialDownload: sequentialDownload,
        SessionKeys.speedLimitDownEnabled: speedLimitDownEnabled,
        SessionKeys.speedLimitDown: speedLimitDown,
        SessionKeys.speedLimitUpEnabled: speedLimitUpEnabled,
        SessionKeys.speedLimitUp: speedLimitUp,
        SessionKeys.startAddedTorrents: startAddedTorrents,
        SessionKeys.tcpEnabled: tcpEnabled,
        SessionKeys.trashOriginalTorrentFiles: trashOriginalTorrentFiles,
        SessionKeys.utpEnabled: utpEnabled,
      }),
    );
  }

  /// Returns transfer statistics for the current session and for all time.
  Future<SessionStats> sessionStats() async =>
      SessionStats.fromJson(await _client.call('session-stats'));

  /// Tells the daemon to shut down.
  Future<void> closeSession() async {
    _logger?.info('Closing session');
    await _client.call('session-close');
  }

  /// Updates the blocklist and returns the number of rules it now holds.
  Future<int> blocklist() async {
    final result = await _client.call('blocklist-update');
    return Json(result).intOf(SessionKeys.blocklistSize) ?? 0;
  }

  /// Asks the daemon whether its peer port is reachable from the outside.
  Future<TestPort> testPort(IpProtocol protocol) async {
    final result = await _client.call(
      'port-test',
      _args({SessionKeys.ipProtocol: protocol.wireValue}),
    );
    return TestPort.fromJson(result);
  }

  /// Returns how much space is free in [path] on the daemon's machine.
  Future<FreeSpace> freeSpace(String path) async {
    final result = await _client.call(
      'free-space',
      _args({SessionKeys.path: path}),
    );
    return FreeSpace.fromJson(result);
  }

  // ---------------------------------------------------------------------------
  // Bandwidth groups (Transmission 4.0+)
  // ---------------------------------------------------------------------------

  /// Returns the bandwidth groups defined on the daemon.
  Future<List<Group>> groups() async {
    final result = await _client.call('group-get');
    final groups = result['group'];
    if (groups is! List) return const [];
    return groups
        .map((group) => Group.fromJson(Map<String, dynamic>.from(group as Map)))
        .toList(growable: false);
  }

  /// Creates or updates the bandwidth group [name].
  Future<void> setGroup({
    required String name,
    required bool honorsSessionLimits,
    required bool speedLimitDownEnabled,
    required bool speedLimitUpEnabled,
    required int speedLimitDown,
    required int speedLimitUp,
  }) async {
    _logger?.info('Updating bandwidth group $name');
    await _client.call(
      'group-set',
      _args({
        SessionKeys.groupName: name,
        SessionKeys.honorsSessionLimits: honorsSessionLimits,
        SessionKeys.groupSpeedLimitDownEnabled: speedLimitDownEnabled,
        SessionKeys.groupSpeedLimitUpEnabled: speedLimitUpEnabled,
        SessionKeys.groupSpeedLimitDown: speedLimitDown,
        SessionKeys.groupSpeedLimitUp: speedLimitUp,
      }),
    );
  }
}
