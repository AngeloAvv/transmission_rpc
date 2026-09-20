import 'package:transmission_rpc/transmission_rpc.dart';
import 'package:test/test.dart';

import 'helpers/mock_adapter.dart';

/// A torrent payload small enough to read, rich enough to assert on.
const torrentPayload = <String, dynamic>{
  'id': 3,
  'name': 'ubuntu-24.04.iso',
  'eta': 60,
  'status': 4,
  'percentDone': 0.5,
};

/// Asserts the last request was [method] in the legacy envelope, carrying
/// exactly [arguments] when they are given.
void expectCall(
  MockHttpClientAdapter mock,
  String method, [
  Map<String, dynamic>? arguments,
]) {
  expect(mock.requestCount, 1);
  expect(mock.lastMethod, method);
  expect(mock.lastBody.containsKey('jsonrpc'), isFalse);
  if (arguments != null) expect(mock.lastArguments, arguments);
}

void main() {
  // -------------------------------------------------------------------------
  // Torrents
  // -------------------------------------------------------------------------

  group('torrents', () {
    test(
      'asks torrent-get for the default fields and parses the list',
      () async {
        final h = buildClient();
        h.mock.respondWith(
          legacySuccess({
            'torrents': [torrentPayload],
          }),
        );

        final torrents = await h.client.torrents();

        expectCall(h.mock, 'torrent-get');
        expect(h.mock.lastArguments['fields'], hasLength(20));
        expect(h.mock.lastArguments.containsKey('ids'), isFalse);
        expect(torrents, hasLength(1));
        expect(torrents.single.name, 'ubuntu-24.04.iso');
        expect(torrents.single.status, TorrentStatus.download);
      },
    );

    test('sends only the fields it was asked for', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'torrents': []}));

      await h.client.torrents(fields: [TorrentField.id, TorrentField.name]);

      expect(h.mock.lastArguments['fields'], ['id', 'name']);
    });

    test(
      'returns an empty list when the daemon sends no torrents key',
      () async {
        final h = buildClient();
        h.mock.respondWith(legacySuccess());

        expect(await h.client.torrents(), isEmpty);
      },
    );

    test('throws RpcError when the daemon rejects the call', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('invalid argument'));

      await expectLater(h.client.torrents(), throwsA(isA<RpcError>()));
    });
  });

  group('activeTorrents', () {
    test('asks torrent-get with the recently-active selector', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({
          'torrents': [torrentPayload],
        }),
      );

      final torrents = await h.client.activeTorrents();

      expectCall(h.mock, 'torrent-get');
      expect(h.mock.lastArguments['ids'], 'recently-active');
      expect(torrents.single.id, 3);
    });

    test('throws RpcError when the daemon rejects the call', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('invalid argument'));

      await expectLater(h.client.activeTorrents(), throwsA(isA<RpcError>()));
    });
  });

  group('addTorrent', () {
    test('sends torrent-add with only the arguments that were given', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'torrent-added': torrentPayload}));

      await h.client.addTorrent(
        filename: 'magnet:?xt=urn:btih:deadbeef',
        downloadDir: '/downloads',
        labels: ['linux'],
        paused: true,
        peerLimit: 30,
        bandwidthPriority: 1,
        filesWanted: [0, 1],
        filesUnwanted: [2],
        priorityHigh: [0],
      );

      expectCall(h.mock, 'torrent-add', {
        'filename': 'magnet:?xt=urn:btih:deadbeef',
        'download-dir': '/downloads',
        'labels': ['linux'],
        'paused': true,
        'peer-limit': 30,
        'bandwidthPriority': 1,
        'files-wanted': [0, 1],
        'files-unwanted': [2],
        'priority-high': [0],
      });
    });

    test('sends metainfo when no filename is given', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'torrent-added': torrentPayload}));

      final result = await h.client.addTorrent(metainfo: 'ZDg6YW5ub3VuY2U=');

      expectCall(h.mock, 'torrent-add', {'metainfo': 'ZDg6YW5ub3VuY2U='});
      expect(result.isDuplicate, isFalse);
      expect(result.torrent.id, torrentPayload['id']);
    });

    test('reports a torrent the daemon already had', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'torrent-duplicate': torrentPayload}));

      final result = await h.client.addTorrent(filename: 'x.torrent');

      expect(result.isDuplicate, isTrue);
      expect(result.torrent.id, torrentPayload['id']);
    });

    test('throws when the daemon answers with neither torrent', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await expectLater(
        h.client.addTorrent(filename: 'x.torrent'),
        throwsA(isA<RpcError>()),
      );
    });

    test('throws RpcError on a duplicate torrent', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('duplicate torrent'));

      await expectLater(
        h.client.addTorrent(filename: 'x.torrent'),
        throwsA(
          isA<RpcError>().having(
            (e) => e.message,
            'message',
            'duplicate torrent',
          ),
        ),
      );
    });
  });

  group('removeTorrents', () {
    test('sends torrent-remove keeping the data by default', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.removeTorrents([1, 2]);

      expectCall(h.mock, 'torrent-remove', {
        'ids': [1, 2],
        'delete-local-data': false,
      });
    });

    test('sends delete-local-data when asked to', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.removeTorrents([1], deleteLocalData: true);

      expect(h.mock.lastArguments['delete-local-data'], isTrue);
    });

    test('throws RpcError for an unknown torrent', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(
        h.client.removeTorrents([99]),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('moveTorrents', () {
    test('sends torrent-set-location without moving data by default', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.moveTorrents([1], location: '/other');

      expectCall(h.mock, 'torrent-set-location', {
        'ids': [1],
        'location': '/other',
        'move': false,
      });
    });

    test('sends move: true when the data should follow', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.moveTorrents([1], location: '/other', move: true);

      expect(h.mock.lastArguments['move'], isTrue);
    });

    test('throws RpcError when the location is not usable', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('permission denied'));

      await expectLater(
        h.client.moveTorrents([1], location: '/root'),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('renameTorrent', () {
    test('sends torrent-rename-path with the old path and new name', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.renameTorrent([1], path: 'old.iso', name: 'new.iso');

      expectCall(h.mock, 'torrent-rename-path', {
        'ids': [1],
        'name': 'new.iso',
        'path': 'old.iso',
      });
    });

    test('throws RpcError when the path does not exist', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such file'));

      await expectLater(
        h.client.renameTorrent([1], path: 'nope', name: 'x'),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('startTorrents', () {
    test('sends torrent-start with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.startTorrents([1, 2]);

      expectCall(h.mock, 'torrent-start', {
        'ids': [1, 2],
      });
    });

    test('throws RpcError when the daemon refuses', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(h.client.startTorrents([9]), throwsA(isA<RpcError>()));
    });
  });

  group('startTorrentsNow', () {
    test('sends torrent-start-now with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.startTorrentsNow([4]);

      expectCall(h.mock, 'torrent-start-now', {
        'ids': [4],
      });
    });

    test('throws RpcError when the daemon refuses', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(
        h.client.startTorrentsNow([9]),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('stopTorrents', () {
    test('sends torrent-stop with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.stopTorrents([1]);

      expectCall(h.mock, 'torrent-stop', {
        'ids': [1],
      });
    });

    test('throws AuthenticationError on HTTP 401', () async {
      final h = buildClient();
      h.mock.respondWith(unauthorized());

      await expectLater(
        h.client.stopTorrents([1]),
        throwsA(isA<AuthenticationError>()),
      );
    });
  });

  group('reannounceTorrents', () {
    test('sends torrent-reannounce with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.reannounceTorrents([1, 5]);

      expectCall(h.mock, 'torrent-reannounce', {
        'ids': [1, 5],
      });
    });

    test('throws NetworkError when the daemon is unreachable', () async {
      final client = buildNetworkErrorClient();

      await expectLater(
        client.reannounceTorrents([1]),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  group('verifyTorrents', () {
    test('sends torrent-verify with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.verifyTorrents([2]);

      expectCall(h.mock, 'torrent-verify', {
        'ids': [2],
      });
    });

    test('throws RpcError when the daemon refuses', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(h.client.verifyTorrents([9]), throwsA(isA<RpcError>()));
    });
  });

  group('moveQueueOnTop', () {
    test('sends queue-move-top with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.moveQueueOnTop([1]);

      expectCall(h.mock, 'queue-move-top', {
        'ids': [1],
      });
    });

    test('throws RpcError when the daemon refuses', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(h.client.moveQueueOnTop([9]), throwsA(isA<RpcError>()));
    });
  });

  group('moveQueueUp', () {
    test('sends queue-move-up with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.moveQueueUp([1]);

      expectCall(h.mock, 'queue-move-up', {
        'ids': [1],
      });
    });

    test('throws RpcError when the daemon refuses', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(h.client.moveQueueUp([9]), throwsA(isA<RpcError>()));
    });
  });

  group('moveQueueDown', () {
    test('sends queue-move-down with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.moveQueueDown([1]);

      expectCall(h.mock, 'queue-move-down', {
        'ids': [1],
      });
    });

    test('throws RpcError when the daemon refuses', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(h.client.moveQueueDown([9]), throwsA(isA<RpcError>()));
    });
  });

  group('moveQueueOnBottom', () {
    test('sends queue-move-bottom with the ids', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.moveQueueOnBottom([1]);

      expectCall(h.mock, 'queue-move-bottom', {
        'ids': [1],
      });
    });

    test('throws RpcError when the daemon refuses', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(
        h.client.moveQueueOnBottom([9]),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('setTorrents', () {
    test('sends torrent-set with only the arguments that were given', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setTorrents(
        ids: [1],
        downloadLimit: 500,
        downloadLimited: true,
        seedRatioLimit: 2.5,
        labels: ['seeding'],
        group: 'slow',
        queuePosition: 0,
      );

      expectCall(h.mock, 'torrent-set', {
        'ids': [1],
        'downloadLimit': 500,
        'downloadLimited': true,
        'seedRatioLimit': 2.5,
        'labels': ['seeding'],
        'group': 'slow',
        'queuePosition': 0,
      });
    });

    test('sends an empty argument map when nothing was given', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setTorrents();

      expectCall(h.mock, 'torrent-set', <String, dynamic>{});
    });

    test('throws RpcError when an argument is rejected', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('invalid argument'));

      await expectLater(
        h.client.setTorrents(ids: [1], downloadLimit: -1),
        throwsA(isA<RpcError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Session
  // -------------------------------------------------------------------------

  group('session', () {
    test(
      'sends session-get with no arguments and parses the settings',
      () async {
        final h = buildClient();
        h.mock.respondWith(
          legacySuccess({'version': '4.0.5', 'download-dir': '/downloads'}),
        );

        final session = await h.client.session();

        expect(h.mock.lastBody, {'method': 'session-get'});
        expect(session.version, '4.0.5');
        expect(session.downloadDir, '/downloads');
      },
    );

    test('throws AuthenticationError on HTTP 401', () async {
      final h = buildClient();
      h.mock.respondWith(unauthorized());

      await expectLater(
        h.client.session(),
        throwsA(isA<AuthenticationError>()),
      );
    });
  });

  group('setSession', () {
    test('sends session-set with the settings that were given', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setSession(
        downloadDir: '/new',
        speedLimitDown: 500,
        speedLimitDownEnabled: true,
        encryption: SessionEncryption.required,
        seedRatioLimit: 1.5,
      );

      expectCall(h.mock, 'session-set', {
        'download-dir': '/new',
        'encryption': 'required',
        'seedRatioLimit': 1.5,
        'speed-limit-down-enabled': true,
        'speed-limit-down': 500,
      });
    });

    test('throws RpcError when a setting is rejected', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('invalid argument'));

      await expectLater(
        h.client.setSession(peerPort: -1),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('sessionStats', () {
    test('sends session-stats and parses the counters', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({'torrentCount': 5, 'downloadSpeed': 1000}),
      );

      final stats = await h.client.sessionStats();

      expect(h.mock.lastBody, {'method': 'session-stats'});
      expect(stats.torrentCount, 5);
      expect(stats.downloadSpeed, 1000);
    });

    test('throws NetworkError when the daemon is unreachable', () async {
      final client = buildNetworkErrorClient();

      await expectLater(client.sessionStats(), throwsA(isA<NetworkError>()));
    });
  });

  group('closeSession', () {
    test('sends session-close with no arguments', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.closeSession();

      expect(h.mock.lastBody, {'method': 'session-close'});
    });

    test('throws RpcError when the daemon refuses to shut down', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('not allowed'));

      await expectLater(h.client.closeSession(), throwsA(isA<RpcError>()));
    });
  });

  group('blocklist', () {
    test('sends blocklist-update and returns the new rule count', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'blocklist-size': 393006}));

      final size = await h.client.blocklist();

      expect(h.mock.lastBody, {'method': 'blocklist-update'});
      expect(size, 393006);
    });

    test('throws RpcError when the blocklist cannot be fetched', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('gotBlocklist: HTTP error 404'));

      await expectLater(h.client.blocklist(), throwsA(isA<RpcError>()));
    });
  });

  group('testPort', () {
    test('sends port-test with the protocol and parses the answer', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({'port-is-open': true, 'ipProtocol': 'ipv4'}),
      );

      final result = await h.client.testPort(IpProtocol.ipv4);

      expectCall(h.mock, 'port-test', {'ipProtocol': 'ipv4'});
      expect(result.portIsOpen, isTrue);
      expect(result.ipProtocol, IpProtocol.ipv4);
    });

    test('throws RpcError when the test cannot run', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('port-test failed'));

      await expectLater(
        h.client.testPort(IpProtocol.ipv6),
        throwsA(isA<RpcError>()),
      );
    });
  });

  group('freeSpace', () {
    test('sends free-space for the path and parses the answer', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({'path': '/downloads', 'size-bytes': 1024}),
      );

      final free = await h.client.freeSpace('/downloads');

      expectCall(h.mock, 'free-space', {'path': '/downloads'});
      expect(free.path, '/downloads');
      expect(free.sizeBytes, 1024);
    });

    test('throws RpcError for a path the daemon cannot reach', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('No such file or directory'));

      await expectLater(h.client.freeSpace('/nope'), throwsA(isA<RpcError>()));
    });
  });

  // -------------------------------------------------------------------------
  // Bandwidth groups
  // -------------------------------------------------------------------------

  group('groups', () {
    test('sends group-get and parses the group list', () async {
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
            {
              'name': 'fast',
              'honorsSessionLimits': true,
              'speed-limit-down-enabled': true,
              'speed-limit-down': 10000,
              'speed-limit-up-enabled': false,
              'speed-limit-up': 2000,
            },
          ],
        }),
      );

      final groups = await h.client.groups();

      expect(h.mock.lastBody, {'method': 'group-get'});
      expect(groups.map((g) => g.name), ['slow', 'fast']);
      expect(groups.first.speedLimitDown, 100);
    });

    test('returns an empty list when the daemon knows no groups', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      expect(await h.client.groups(), isEmpty);
    });

    test('throws RpcError on daemons without group support', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('method name not recognized'));

      await expectLater(h.client.groups(), throwsA(isA<RpcError>()));
    });
  });

  group('setGroup', () {
    test('sends group-set with every limit', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setGroup(
        name: 'slow',
        honorsSessionLimits: true,
        speedLimitDownEnabled: true,
        speedLimitUpEnabled: false,
        speedLimitDown: 100,
        speedLimitUp: 20,
      );

      expectCall(h.mock, 'group-set', {
        'name': 'slow',
        'honorsSessionLimits': true,
        'speed-limit-down-enabled': true,
        'speed-limit-up-enabled': false,
        'speed-limit-down': 100,
        'speed-limit-up': 20,
      });
    });

    test('throws RpcError on daemons without group support', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('method name not recognized'));

      await expectLater(
        h.client.setGroup(
          name: 'slow',
          honorsSessionLimits: true,
          speedLimitDownEnabled: true,
          speedLimitUpEnabled: true,
          speedLimitDown: 1,
          speedLimitUp: 1,
        ),
        throwsA(isA<RpcError>()),
      );
    });
  });
}
