// A small command-line tour of transmission_rpc.
//
// Configure it through the environment, then run it:
//
//   TRANSMISSION_URL=http://nas.local:9091/transmission/rpc \
//   TRANSMISSION_USER=transmission \
//   TRANSMISSION_PASSWORD=hunter2 \
//   dart run example/transmission_rpc_example.dart
//
// With no environment at all it talks to a daemon on localhost with default
// settings. It only reads: the calls that would change anything are guarded
// behind opt-in environment variables, so running it is harmless.

import 'dart:io';

import 'package:transmission_rpc/transmission_rpc.dart';

Future<void> main() async {
  final env = Platform.environment;

  final transmission = Transmission(
    baseUrl:
        env['TRANSMISSION_URL'] ?? 'http://localhost:9091/transmission/rpc',
    username: env['TRANSMISSION_USER'],
    password: env['TRANSMISSION_PASSWORD'],
    // Uncomment to see every request and response:
    // logLevel: LogLevel.debug,
    timeout: const Duration(seconds: 10),
  );

  try {
    await _printDaemonInfo(transmission);
    await _printTorrents(transmission);
    await _maybeAddMagnet(transmission, env['TRANSMISSION_ADD_MAGNET']);
    await _maybeStopTorrent(transmission, env['TRANSMISSION_STOP_ID']);
  } on AuthenticationError catch (e) {
    stderr.writeln('Authentication failed: ${e.message}');
    stderr.writeln('Set TRANSMISSION_USER and TRANSMISSION_PASSWORD.');
    exitCode = 77;
  } on RpcError catch (e) {
    stderr.writeln('The daemon refused the request: ${e.message} (${e.code})');
    exitCode = 1;
  } on NetworkError catch (e) {
    stderr.writeln('Could not reach the daemon: ${e.message}');
    stderr.writeln('Set TRANSMISSION_URL if it is not on localhost:9091.');
    exitCode = 69;
  }
}

/// Prints what the daemon is and which RPC dialect the client detected.
Future<void> _printDaemonInfo(Transmission transmission) async {
  // session() is also what settles the RPC version detection, so it is a good
  // first call.
  final session = await transmission.session();

  print('Transmission ${session.version ?? 'unknown'}');
  print(
    '  RPC version   : ${transmission.rpcVersion}'
    '${transmission.rpcVersion >= 18 ? ' (JSON-RPC 2.0 dialect)' : ' (legacy dialect)'}',
  );
  print('  RPC semver    : ${transmission.rpcVersionSemver ?? 'not reported'}');
  print('  Download dir  : ${session.downloadDir ?? 'unknown'}');

  final stats = await transmission.sessionStats();
  print(
    '  Torrents      : ${stats.torrentCount ?? 0} '
    '(${stats.activeTorrentCount ?? 0} active, '
    '${stats.pausedTorrentCount ?? 0} paused)',
  );
  print(
    '  Speed         : '
    '${_kbps(stats.downloadSpeed)} down / ${_kbps(stats.uploadSpeed)} up',
  );

  final downloadDir = session.downloadDir;
  if (downloadDir != null) {
    final space = await transmission.freeSpace(downloadDir);
    print('  Free space    : ${_gib(space.sizeBytes)} in ${space.path}');
  }
  print('');
}

/// Lists the torrents with their name, progress and status.
Future<void> _printTorrents(Transmission transmission) async {
  final torrents = await transmission.torrents(
    fields: [
      TorrentField.id,
      TorrentField.name,
      TorrentField.percentDone,
      TorrentField.status,
      TorrentField.rateDownload,
      TorrentField.rateUpload,
    ],
  );

  if (torrents.isEmpty) {
    print('No torrents.');
    return;
  }

  print('${torrents.length} torrent(s):');
  for (final torrent in torrents) {
    final percent = ((torrent.percentDone ?? 0) * 100).toStringAsFixed(1);
    print(
      '  [${torrent.id}] ${torrent.name ?? '<unnamed>'}\n'
      '        ${percent.padLeft(5)}%  ${_status(torrent.status)}'
      '  ${_kbps(torrent.rateDownload)} down'
      '  ${_kbps(torrent.rateUpload)} up',
    );
  }
  print('');
}

/// Adds [magnet] — but only when TRANSMISSION_ADD_MAGNET is set, so that a
/// plain run of this example never changes anything.
Future<void> _maybeAddMagnet(Transmission transmission, String? magnet) async {
  if (magnet == null) {
    print('Set TRANSMISSION_ADD_MAGNET=<magnet link> to add a torrent.');
    return;
  }

  final result = await transmission.addTorrent(
    filename: magnet,
    paused: true,
    labels: ['added-by-example'],
    // downloadDir: '/mnt/media/downloads',
    // sequentialDownloadFromPiece: 0, // Transmission 4.1+
  );

  // Only id, name and hashString are populated on the returned torrent.
  final torrent = result.torrent;
  if (result.isDuplicate) {
    print('Already there: [${torrent.id}] ${torrent.name ?? magnet}');
  } else {
    print('Added (paused): [${torrent.id}] ${torrent.name ?? magnet}');
  }
}

/// Stops the torrent whose id is in TRANSMISSION_STOP_ID, when it is set.
Future<void> _maybeStopTorrent(Transmission transmission, String? rawId) async {
  if (rawId == null) {
    print('Set TRANSMISSION_STOP_ID=<torrent id> to stop a torrent.');
    return;
  }

  final id = int.tryParse(rawId);
  if (id == null) {
    stderr.writeln('TRANSMISSION_STOP_ID is not a number: $rawId');
    return;
  }

  await transmission.stopTorrents([id]);
  print('Stopped torrent $id.');

  // The other torrent controls look the same:
  //
  //   await transmission.startTorrents([id]);
  //   await transmission.startTorrentsNow([id]);
  //   await transmission.verifyTorrents([id]);
  //   await transmission.reannounceTorrents([id]);
  //   await transmission.moveQueueOnTop([id]);
  //   await transmission.setTorrents(ids: [id], uploadLimit: 100,
  //       uploadLimited: true);
  //   await transmission.moveTorrents([id], location: '/mnt/archive',
  //       move: true);
  //   await transmission.removeTorrents([id], deleteLocalData: false);
}

String _status(TorrentStatus? status) => switch (status) {
  TorrentStatus.stopped => 'stopped',
  TorrentStatus.checkWait => 'queued to verify',
  TorrentStatus.check => 'verifying',
  TorrentStatus.downloadWait => 'queued to download',
  TorrentStatus.download => 'downloading',
  TorrentStatus.seedWait => 'queued to seed',
  TorrentStatus.seed => 'seeding',
  null => 'unknown',
};

String _kbps(int? bytesPerSecond) =>
    '${((bytesPerSecond ?? 0) / 1024).toStringAsFixed(1)} kB/s';

String _gib(int bytes) =>
    '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
