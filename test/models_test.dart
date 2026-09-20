import 'package:transmission_rpc/transmission_rpc.dart';
import 'package:test/test.dart';

import 'helpers/mock_adapter.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A torrent the way Transmission 3.x / 4.0 puts it on the wire.
const legacyTorrent = <String, dynamic>{
  'id': 7,
  'name': 'debian-12.iso',
  'eta': 120,
  'status': 4,
  'percentDone': 0.42,
  'rateDownload': 512000,
  'rateUpload': 1024,
  'isFinished': false,
  'isStalled': false,
  'errorString': 'tracker gave HTTP response code 404',
  'error': 2,
  'hashString': 'deadbeef',
  'leftUntilDone': 1024,
  'sizeWhenDone': 2048,
  'uploadRatio': 1.25,
  'downloadDir': '/downloads',
  'labels': ['linux', 'iso'],
  'wanted': [1, 0],
  'peersConnected': 3,
  'peersFrom': {
    'fromCache': 0,
    'fromDht': 1,
    'fromIncoming': 2,
    'fromLpd': 0,
    'fromLtep': 0,
    'fromPex': 4,
    'fromTracker': 5,
  },
  'files': [
    {'bytesCompleted': 512, 'length': 2048, 'name': 'debian-12.iso'},
  ],
  'fileStats': [
    {'bytesCompleted': 512, 'wanted': true, 'priority': 0},
  ],
  'trackerStats': [
    {
      'announce': 'http://tracker.example/announce',
      'host': 'tracker.example',
      'id': 0,
      'isBackup': false,
      'lastAnnounceSucceeded': true,
      'lastAnnouncePeerCount': 12,
      'leecherCount': 4,
      'seederCount': 30,
      'tier': 0,
    },
  ],
};

/// The same torrent the way Transmission 4.1 (RPC 18) puts it on the wire.
const modernTorrent = <String, dynamic>{
  'id': 7,
  'name': 'debian-12.iso',
  'eta': 120,
  'status': 4,
  'percent_done': 0.42,
  'rate_download': 512000,
  'rate_upload': 1024,
  'is_finished': false,
  'is_stalled': false,
  'error_string': 'tracker gave HTTP response code 404',
  'error': 2,
  'hash_string': 'deadbeef',
  'left_until_done': 1024,
  'size_when_done': 2048,
  'upload_ratio': 1.25,
  'download_dir': '/downloads',
  'labels': ['linux', 'iso'],
  'wanted': [true, false],
  'peers_connected': 3,
  'peers_from': {
    'from_cache': 0,
    'from_dht': 1,
    'from_incoming': 2,
    'from_lpd': 0,
    'from_ltep': 0,
    'from_pex': 4,
    'from_tracker': 5,
  },
  'files': [
    {'bytes_completed': 512, 'length': 2048, 'name': 'debian-12.iso'},
  ],
  'file_stats': [
    {'bytes_completed': 512, 'wanted': true, 'priority': 0},
  ],
  'tracker_stats': [
    {
      'announce': 'http://tracker.example/announce',
      'host': 'tracker.example',
      'id': 0,
      'is_backup': false,
      'last_announce_succeeded': true,
      'last_announce_peer_count': 12,
      'leecher_count': 4,
      'seeder_count': 30,
      'tier': 0,
    },
  ],
};

const legacySession = <String, dynamic>{
  'version': '4.0.5',
  'rpc-version': 17,
  'alt-speed-down': 50,
  'alt-speed-up': 60,
  'alt-speed-enabled': false,
  'blocklist-size': 12345,
  'cache-size-mb': 4,
  'download-dir': '/downloads',
  'encryption': 'tolerated',
  'peer-limit-global': 200,
  'peer-port': 51413,
  'seedRatioLimit': 2.0,
  'seedRatioLimited': true,
  'speed-limit-down': 1000,
  'speed-limit-down-enabled': true,
  'units': {
    'memory-bytes': 1024,
    'memory-units': ['KiB', 'MiB'],
    'speed-bytes': 1000,
    'speed-units': ['kB/s', 'MB/s'],
  },
};

const modernSession = <String, dynamic>{
  'version': '4.1.0',
  'rpc_version': 18,
  'rpc_version_semver': '4.1.0',
  'alt_speed_down': 50,
  'alt_speed_up': 60,
  'alt_speed_enabled': false,
  'blocklist_size': 12345,
  'cache_size_mib': 4,
  'download_dir': '/downloads',
  'encryption': 'allowed',
  'peer_limit_global': 200,
  'peer_port': 51413,
  'seed_ratio_limit': 2.0,
  'seed_ratio_limited': true,
  'speed_limit_down': 1000,
  'speed_limit_down_enabled': true,
  'units': {
    'memory_bytes': 1024,
    'memory_units': ['KiB', 'MiB'],
    'speed_bytes': 1000,
    'speed_units': ['kB/s', 'MB/s'],
  },
};

const legacySessionStats = <String, dynamic>{
  'activeTorrentCount': 2,
  'downloadSpeed': 123456,
  'pausedTorrentCount': 1,
  'torrentCount': 3,
  'uploadSpeed': 654,
  'cumulative-stats': {
    'uploadedBytes': 100,
    'downloadedBytes': 200,
    'filesAdded': 3,
    'sessionCount': 4,
    'secondsActive': 500,
  },
  'current-stats': {
    'uploadedBytes': 10,
    'downloadedBytes': 20,
    'filesAdded': 1,
    'sessionCount': 1,
    'secondsActive': 50,
  },
};

const modernSessionStats = <String, dynamic>{
  'active_torrent_count': 2,
  'download_speed': 123456,
  'paused_torrent_count': 1,
  'torrent_count': 3,
  'upload_speed': 654,
  'cumulative_stats': {
    'uploaded_bytes': 100,
    'downloaded_bytes': 200,
    'files_added': 3,
    'session_count': 4,
    'seconds_active': 500,
  },
  'current_stats': {
    'uploaded_bytes': 10,
    'downloaded_bytes': 20,
    'files_added': 1,
    'session_count': 1,
    'seconds_active': 50,
  },
};

/// Fetches a single torrent from a legacy daemon answering with [payload].
Future<Torrent> parseLegacyTorrent(Map<String, dynamic> payload) async {
  final h = buildClient();
  h.mock.respondWith(
    legacySuccess({
      'torrents': [payload],
    }),
  );
  return (await h.client.torrents()).single;
}

/// Fetches a single torrent from an RPC 18 daemon answering with [payload].
Future<Torrent> parseModernTorrent(Map<String, dynamic> payload) async {
  final h = await buildV18Client();
  h.mock.respondWith(
    v18Success({
      'torrents': [payload],
    }),
  );
  return (await h.client.torrents()).single;
}

void main() {
  group('Torrent parsing', () {
    test('a legacy camelCase payload fills every field', () async {
      final torrent = await parseLegacyTorrent(legacyTorrent);

      expect(torrent.id, 7);
      expect(torrent.name, 'debian-12.iso');
      expect(torrent.percentDone, 0.42);
      expect(torrent.rateDownload, 512000);
      expect(torrent.rateUpload, 1024);
      expect(torrent.isFinished, isFalse);
      expect(torrent.isStalled, isFalse);
      expect(torrent.errorString, 'tracker gave HTTP response code 404');
      expect(torrent.error, 2);
      expect(torrent.hashString, 'deadbeef');
      expect(torrent.leftUntilDone, 1024);
      expect(torrent.sizeWhenDone, 2048);
      expect(torrent.uploadRatio, 1.25);
      expect(torrent.downloadDir, '/downloads');
      expect(torrent.labels, ['linux', 'iso']);
      expect(torrent.peersConnected, 3);
      expect(torrent.status, TorrentStatus.download);
    });

    test('a legacy payload fills the nested objects', () async {
      final torrent = await parseLegacyTorrent(legacyTorrent);

      expect(torrent.peersFrom?.fromDht, 1);
      expect(torrent.peersFrom?.fromIncoming, 2);
      expect(torrent.peersFrom?.fromPex, 4);
      expect(torrent.peersFrom?.fromTracker, 5);

      expect(torrent.files, hasLength(1));
      expect(torrent.files?.single.bytesCompleted, 512);
      expect(torrent.files?.single.length, 2048);
      expect(torrent.files?.single.name, 'debian-12.iso');

      expect(torrent.fileStats?.single.bytesCompleted, 512);
      expect(torrent.fileStats?.single.wanted, isTrue);
      expect(torrent.fileStats?.single.priority, 0);

      final tracker = torrent.trackerStats?.single;
      expect(tracker?.announce, 'http://tracker.example/announce');
      expect(tracker?.host, 'tracker.example');
      expect(tracker?.lastAnnounceSucceeded, isTrue);
      expect(tracker?.lastAnnouncePeerCount, 12);
      expect(tracker?.leecherCount, 4);
      expect(tracker?.seederCount, 30);
      expect(tracker?.isBackup, isFalse);
    });

    test('a snake_case payload fills exactly the same fields', () async {
      final torrent = await parseModernTorrent(modernTorrent);

      expect(torrent.id, 7);
      expect(torrent.percentDone, 0.42);
      expect(torrent.rateDownload, 512000);
      expect(torrent.rateUpload, 1024);
      expect(torrent.isFinished, isFalse);
      expect(torrent.errorString, 'tracker gave HTTP response code 404');
      expect(torrent.hashString, 'deadbeef');
      expect(torrent.leftUntilDone, 1024);
      expect(torrent.sizeWhenDone, 2048);
      expect(torrent.uploadRatio, 1.25);
      expect(torrent.downloadDir, '/downloads');
      expect(torrent.peersConnected, 3);
      expect(torrent.status, TorrentStatus.download);
    });

    test('a snake_case payload fills the nested objects', () async {
      final torrent = await parseModernTorrent(modernTorrent);

      expect(torrent.peersFrom?.fromDht, 1);
      expect(torrent.peersFrom?.fromPex, 4);
      expect(torrent.files?.single.bytesCompleted, 512);
      expect(torrent.fileStats?.single.wanted, isTrue);
      expect(torrent.trackerStats?.single.lastAnnouncePeerCount, 12);
      expect(torrent.trackerStats?.single.seederCount, 30);
    });

    test('unrequested fields stay null instead of throwing', () async {
      final torrent = await parseLegacyTorrent({'id': 1, 'name': 'x'});

      expect(torrent.id, 1);
      expect(torrent.percentDone, isNull);
      expect(torrent.peersFrom, isNull);
      expect(torrent.files, isNull);
      expect(torrent.status, isNull);
    });

    test('wanted accepts 1/0 integers', () async {
      final torrent = await parseLegacyTorrent({
        'wanted': [1, 0, 1],
      });
      expect(torrent.wanted, [true, false, true]);
    });

    test('wanted accepts true/false booleans', () async {
      final torrent = await parseLegacyTorrent({
        'wanted': [true, false],
      });
      expect(torrent.wanted, [true, false]);
    });

    test('integer booleans parse as booleans', () async {
      final torrent = await parseLegacyTorrent({
        'isFinished': 1,
        'isPrivate': 0,
      });
      expect(torrent.isFinished, isTrue);
      expect(torrent.isPrivate, isFalse);
    });

    test('an integer where a double is expected still parses', () async {
      final torrent = await parseLegacyTorrent({
        'percentDone': 1,
        'uploadRatio': 2,
      });
      expect(torrent.percentDone, 1.0);
      expect(torrent.uploadRatio, 2.0);
    });

    test('webseeds_ex fills the per-webseed state', () async {
      final torrent = await parseModernTorrent({
        'id': 7,
        'webseeds_ex': [
          {
            'url': 'https://mirror.example/debian-12.iso',
            'is_downloading': true,
            'download_bytes_per_second': 4096,
          },
          {
            'url': 'https://backup.example/debian-12.iso',
            'is_downloading': false,
            'download_bytes_per_second': 0,
          },
        ],
      });

      expect(torrent.webseedsEx, hasLength(2));
      expect(
        torrent.webseedsEx?.first.url,
        'https://mirror.example/debian-12.iso',
      );
      expect(torrent.webseedsEx?.first.isDownloading, isTrue);
      expect(torrent.webseedsEx?.first.downloadBytesPerSecond, 4096);
      expect(
        torrent.webseedsEx?.last.url,
        'https://backup.example/debian-12.iso',
      );
      expect(torrent.webseedsEx?.last.isDownloading, isFalse);
      expect(torrent.webseedsEx?.last.downloadBytesPerSecond, 0);
    });

    test('webseeds_ex keeps its one spelling on a legacy daemon', () async {
      final torrent = await parseLegacyTorrent({
        'id': 7,
        'webseeds': ['https://mirror.example/debian-12.iso'],
        'webseeds_ex': [
          {
            'url': 'https://mirror.example/debian-12.iso',
            'is_downloading': true,
            'download_bytes_per_second': 512,
          },
        ],
      });

      expect(torrent.webseeds, ['https://mirror.example/debian-12.iso']);
      expect(
        torrent.webseedsEx?.single.url,
        'https://mirror.example/debian-12.iso',
      );
      expect(torrent.webseedsEx?.single.isDownloading, isTrue);
      expect(torrent.webseedsEx?.single.downloadBytesPerSecond, 512);
    });

    test('a webseed the daemon sent no state for stays null', () async {
      final torrent = await parseModernTorrent({
        'webseeds_ex': [
          {'url': 'https://mirror.example/debian-12.iso'},
        ],
      });

      expect(
        torrent.webseedsEx?.single.url,
        'https://mirror.example/debian-12.iso',
      );
      expect(torrent.webseedsEx?.single.isDownloading, isNull);
      expect(torrent.webseedsEx?.single.downloadBytesPerSecond, isNull);
    });

    test('a payload without webseeds_ex leaves the list null', () async {
      final torrent = await parseModernTorrent({'id': 7});

      expect(torrent.webseedsEx, isNull);
    });

    test('the sequential download fields parse in both dialects', () async {
      const payload = <String, dynamic>{
        'id': 1,
        'sequential_download': true,
        'sequential_download_from_piece': 12,
      };

      final legacy = await parseLegacyTorrent(payload);
      expect(legacy.sequentialDownload, isTrue);
      expect(legacy.sequentialDownloadFromPiece, 12);

      final modern = await parseModernTorrent(payload);
      expect(modern.sequentialDownload, isTrue);
      expect(modern.sequentialDownloadFromPiece, 12);
    });

    test('peers carry the fields Transmission 4.1 and 4.2 added', () async {
      final torrent = await parseModernTorrent({
        'id': 7,
        'peers': [
          {
            'address': '10.0.0.1',
            'peer_id': '-TR410Z-abcdefgh',
            'supports_holepunch': true,
            'bytes_to_client': 4096,
            'bytes_to_peer': 512,
            'rate_to_client': 1000,
          },
        ],
      });

      final peer = torrent.peers?.single;
      expect(peer?.address, '10.0.0.1');
      expect(peer?.peerId, '-TR410Z-abcdefgh');
      expect(peer?.supportsHolepunch, isTrue);
      expect(peer?.bytesToClient, 4096);
      expect(peer?.bytesToPeer, 512);
      expect(peer?.rateToClient, 1000);
    });

    test('the new peer fields keep one spelling on a legacy daemon', () async {
      final torrent = await parseLegacyTorrent({
        'id': 7,
        'peers': [
          {
            'address': '10.0.0.1',
            'clientName': 'Transmission 4.0.5',
            'peer_id': '-TR405Z-abcdefgh',
            'supports_holepunch': false,
            'bytes_to_client': 1,
            'bytes_to_peer': 2,
          },
        ],
      });

      final peer = torrent.peers?.single;
      expect(peer?.clientName, 'Transmission 4.0.5');
      expect(peer?.peerId, '-TR405Z-abcdefgh');
      expect(peer?.supportsHolepunch, isFalse);
      expect(peer?.bytesToClient, 1);
      expect(peer?.bytesToPeer, 2);
    });

    test('a peer the daemon sent no 4.1 fields for stays null', () async {
      final torrent = await parseModernTorrent({
        'peers': [
          {'address': '10.0.0.1'},
        ],
      });

      final peer = torrent.peers?.single;
      expect(peer?.peerId, isNull);
      expect(peer?.supportsHolepunch, isNull);
      expect(peer?.bytesToClient, isNull);
      expect(peer?.bytesToPeer, isNull);
    });

    test('peersFrom counts the peers found by holepunching', () async {
      final legacy = await parseLegacyTorrent({
        'peersFrom': {'fromDht': 1, 'from_holepunch': 6},
      });
      expect(legacy.peersFrom?.fromDht, 1);
      expect(legacy.peersFrom?.fromHolepunch, 6);

      final modern = await parseModernTorrent({
        'peers_from': {'from_dht': 1, 'from_holepunch': 6},
      });
      expect(modern.peersFrom?.fromDht, 1);
      expect(modern.peersFrom?.fromHolepunch, 6);
    });

    test('a peersFrom block without holepunch counts stays null', () async {
      final torrent = await parseLegacyTorrent({
        'peersFrom': {'fromDht': 1},
      });

      expect(torrent.peersFrom?.fromHolepunch, isNull);
    });

    test('trackerStats carries the downloader count', () async {
      final legacy = await parseLegacyTorrent({
        'trackerStats': [
          {
            'host': 'tracker.example',
            'downloadCount': 9,
            'downloader_count': 3,
          },
        ],
      });
      expect(legacy.trackerStats?.single.downloadCount, 9);
      expect(legacy.trackerStats?.single.downloaderCount, 3);

      final modern = await parseModernTorrent({
        'tracker_stats': [
          {
            'host': 'tracker.example',
            'download_count': 9,
            'downloader_count': 3,
          },
        ],
      });
      expect(modern.trackerStats?.single.downloadCount, 9);
      expect(modern.trackerStats?.single.downloaderCount, 3);
    });
  });

  group('TorrentStatus', () {
    test('codes 0..6 map to the seven states', () {
      expect(TorrentStatus.fromCode(0), TorrentStatus.stopped);
      expect(TorrentStatus.fromCode(1), TorrentStatus.checkWait);
      expect(TorrentStatus.fromCode(2), TorrentStatus.check);
      expect(TorrentStatus.fromCode(3), TorrentStatus.downloadWait);
      expect(TorrentStatus.fromCode(4), TorrentStatus.download);
      expect(TorrentStatus.fromCode(5), TorrentStatus.seedWait);
      expect(TorrentStatus.fromCode(6), TorrentStatus.seed);
    });

    test('each status reports its own code back', () {
      for (final status in TorrentStatus.values) {
        expect(TorrentStatus.fromCode(status.code), status);
      }
    });

    test('an unknown or missing code yields null, never an exception', () {
      expect(TorrentStatus.fromCode(7), isNull);
      expect(TorrentStatus.fromCode(-1), isNull);
      expect(TorrentStatus.fromCode(null), isNull);
    });

    test('an out-of-range status in a payload leaves the field null', () async {
      final torrent = await parseLegacyTorrent({'id': 1, 'status': 99});
      expect(torrent.status, isNull);
    });
  });

  group('Session parsing', () {
    test('a legacy kebab-case payload fills every field', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess(legacySession));

      final session = await h.client.session();

      expect(session.version, '4.0.5');
      expect(session.altSpeedDown, 50);
      expect(session.altSpeedUp, 60);
      expect(session.altSpeedEnabled, isFalse);
      expect(session.blocklistSize, 12345);
      expect(session.cacheSizeMib, 4);
      expect(session.downloadDir, '/downloads');
      expect(session.peerLimitGlobal, 200);
      expect(session.peerPort, 51413);
      expect(session.seedRatioLimit, 2.0);
      expect(session.seedRatioLimited, isTrue);
      expect(session.speedLimitDown, 1000);
      expect(session.speedLimitDownEnabled, isTrue);
      expect(session.units?.memoryBytes, 1024);
      expect(session.units?.memoryUnits, ['KiB', 'MiB']);
      expect(session.units?.speedUnits, ['kB/s', 'MB/s']);
    });

    test('a snake_case payload fills exactly the same fields', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success(modernSession));

      final session = await h.client.session();

      expect(session.version, '4.1.0');
      expect(session.altSpeedDown, 50);
      expect(session.altSpeedUp, 60);
      expect(session.blocklistSize, 12345);
      expect(session.cacheSizeMib, 4);
      expect(session.downloadDir, '/downloads');
      expect(session.peerLimitGlobal, 200);
      expect(session.seedRatioLimit, 2.0);
      expect(session.speedLimitDownEnabled, isTrue);
      expect(session.units?.memoryBytes, 1024);
      expect(session.units?.speedUnits, ['kB/s', 'MB/s']);
      expect(session.rpcVersion, 18);
      expect(session.rpcVersionSemver, '4.1.0');
    });

    test('encryption "tolerated" is read as allowed', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'encryption': 'tolerated'}));

      expect((await h.client.session()).encryption, SessionEncryption.allowed);
    });

    test('the other encryption spellings round-trip', () {
      expect(SessionEncryption.fromWire('allowed'), SessionEncryption.allowed);
      expect(
        SessionEncryption.fromWire('preferred'),
        SessionEncryption.preferred,
      );
      expect(
        SessionEncryption.fromWire('required'),
        SessionEncryption.required,
      );
      expect(SessionEncryption.fromWire('nonsense'), isNull);
      expect(SessionEncryption.fromWire(null), isNull);
      expect(SessionEncryption.allowed.wireValue(18), 'allowed');
      expect(SessionEncryption.allowed.wireValue(17), 'tolerated');
      expect(SessionEncryption.required.wireValue(17), 'required');
    });

    test('a legacy payload reports tcp-enabled and utp-enabled', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({'tcp-enabled': true, 'utp-enabled': false}),
      );

      final session = await h.client.session();

      expect(session.tcpEnabled, isTrue);
      expect(session.utpEnabled, isFalse);
    });

    test('a snake_case payload reports the same two flags', () async {
      final h = await buildV18Client();
      h.mock.respondWith(
        v18Success({'tcp_enabled': false, 'utp_enabled': true}),
      );

      final session = await h.client.session();

      expect(session.tcpEnabled, isFalse);
      expect(session.utpEnabled, isTrue);
    });

    test(
      'a payload carrying neither transport flag leaves both null',
      () async {
        final h = buildClient();
        h.mock.respondWith(legacySuccess({'version': '4.0.5'}));

        final session = await h.client.session();

        expect(session.tcpEnabled, isNull);
        expect(session.utpEnabled, isNull);
      },
    );
  });

  group('SessionStats parsing', () {
    test('a legacy payload fills the counters and both stat blocks', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess(legacySessionStats));

      final stats = await h.client.sessionStats();

      expect(stats.activeTorrentCount, 2);
      expect(stats.downloadSpeed, 123456);
      expect(stats.pausedTorrentCount, 1);
      expect(stats.torrentCount, 3);
      expect(stats.uploadSpeed, 654);
      expect(stats.cumulativeStats?.uploadedBytes, 100);
      expect(stats.cumulativeStats?.downloadedBytes, 200);
      expect(stats.cumulativeStats?.filesAdded, 3);
      expect(stats.cumulativeStats?.sessionCount, 4);
      expect(stats.cumulativeStats?.secondsActive, 500);
      expect(stats.currentStats?.uploadedBytes, 10);
      expect(stats.currentStats?.secondsActive, 50);
    });

    test('a snake_case payload fills exactly the same fields', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success(modernSessionStats));

      final stats = await h.client.sessionStats();

      expect(stats.activeTorrentCount, 2);
      expect(stats.downloadSpeed, 123456);
      expect(stats.torrentCount, 3);
      expect(stats.cumulativeStats?.downloadedBytes, 200);
      expect(stats.currentStats?.filesAdded, 1);
    });
  });

  group('FreeSpace parsing', () {
    test('a legacy payload uses size-bytes and reports no total', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({'path': '/downloads', 'size-bytes': 9876543210}),
      );

      final free = await h.client.freeSpace('/downloads');

      expect(free.path, '/downloads');
      expect(free.sizeBytes, 9876543210);
      expect(free.totalSize, isNull);
    });

    test('a snake_case payload also carries total_size', () async {
      final h = await buildV18Client();
      h.mock.respondWith(
        v18Success({
          'path': '/downloads',
          'size_bytes': 9876543210,
          'total_size': 99999999999,
        }),
      );

      final free = await h.client.freeSpace('/downloads');

      expect(free.path, '/downloads');
      expect(free.sizeBytes, 9876543210);
      expect(free.totalSize, 99999999999);
    });

    test('throws RpcError when the daemon omits size-bytes', () {
      expect(
        () => FreeSpace.fromJson({'path': '/downloads'}),
        throwsA(isA<RpcError>()),
      );
    });

    test('throws RpcError when the daemon omits path', () {
      expect(
        () => FreeSpace.fromJson({'size-bytes': 9876543210}),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('TestPort parsing', () {
    test('a legacy payload reports the port and protocol', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({'port-is-open': true, 'ipProtocol': 'ipv4'}),
      );

      final result = await h.client.testPort(IpProtocol.ipv4);

      expect(result.portIsOpen, isTrue);
      expect(result.ipProtocol, IpProtocol.ipv4);
    });

    test('a snake_case payload reports the same', () async {
      final h = await buildV18Client();
      h.mock.respondWith(
        v18Success({'port_is_open': false, 'ip_protocol': 'ipv6'}),
      );

      final result = await h.client.testPort(IpProtocol.ipv6);

      expect(result.portIsOpen, isFalse);
      expect(result.ipProtocol, IpProtocol.ipv6);
    });

    test('a pre-4.0 payload without a protocol still parses', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'port-is-open': true}));

      final result = await h.client.testPort(IpProtocol.ipv4);

      expect(result.portIsOpen, isTrue);
      expect(result.ipProtocol, isNull);
    });

    test('throws RpcError when the daemon omits port-is-open', () {
      expect(
        () => TestPort.fromJson({'ip-protocol': 'ipv4'}),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('Group parsing', () {
    test('a legacy payload fills every group field', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({
          'group': [
            {
              'name': 'slow',
              'honorsSessionLimits': true,
              'speed-limit-down-enabled': true,
              'speed-limit-down': 100,
              'speed-limit-up-enabled': false,
              'speed-limit-up': 20,
            },
          ],
        }),
      );

      final group = (await h.client.groups()).single;

      expect(group.name, 'slow');
      expect(group.honorsSessionLimits, isTrue);
      expect(group.speedLimitDownEnabled, isTrue);
      expect(group.speedLimitDown, 100);
      expect(group.speedLimitUpEnabled, isFalse);
      expect(group.speedLimitUp, 20);
    });

    test('a snake_case payload fills exactly the same fields', () async {
      final h = await buildV18Client();
      h.mock.respondWith(
        v18Success({
          'group': [
            {
              'name': 'slow',
              'honors_session_limits': true,
              'speed_limit_down_enabled': true,
              'speed_limit_down': 100,
              'speed_limit_up_enabled': false,
              'speed_limit_up': 20,
            },
          ],
        }),
      );

      final group = (await h.client.groups()).single;

      expect(group.name, 'slow');
      expect(group.honorsSessionLimits, isTrue);
      expect(group.speedLimitDown, 100);
      expect(group.speedLimitUpEnabled, isFalse);
      expect(group.speedLimitUp, 20);
    });

    test('throws RpcError when the daemon omits a required field', () {
      expect(
        () => Group.fromJson({
          'honorsSessionLimits': true,
          'speed-limit-down-enabled': true,
          'speed-limit-down': 100,
          'speed-limit-up-enabled': false,
          'speed-limit-up': 20,
        }),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('blocklist parsing', () {
    test('a legacy payload reports blocklist-size', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'blocklist-size': 42}));

      expect(await h.client.blocklist(), 42);
    });

    test('a snake_case payload reports blocklist_size', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success({'blocklist_size': 42}));

      expect(await h.client.blocklist(), 42);
    });

    test('a payload without a size falls back to 0', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      expect(await h.client.blocklist(), 0);
    });
  });
}
