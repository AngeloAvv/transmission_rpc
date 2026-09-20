import 'package:transmission_rpc/transmission_rpc.dart';
import 'package:test/test.dart';

import 'helpers/mock_adapter.dart';

void main() {
  group('TorrentField.wireName', () {
    test('legacy (17) spells fields the camelCase way', () {
      expect(TorrentField.percentDone.wireName(17), 'percentDone');
      expect(TorrentField.activityDate.wireName(17), 'activityDate');
      expect(TorrentField.rateDownload.wireName(17), 'rateDownload');
      expect(
        TorrentField.webseedsSendingToUs.wireName(17),
        'webseedsSendingToUs',
      );
    });

    test('v18 spells the same fields snake_case', () {
      expect(TorrentField.percentDone.wireName(18), 'percent_done');
      expect(TorrentField.activityDate.wireName(18), 'activity_date');
      expect(TorrentField.rateDownload.wireName(18), 'rate_download');
      expect(
        TorrentField.webseedsSendingToUs.wireName(18),
        'webseeds_sending_to_us',
      );
    });

    test('fields that never changed keep one spelling', () {
      for (final field in [
        TorrentField.id,
        TorrentField.name,
        TorrentField.eta,
        TorrentField.status,
        TorrentField.labels,
      ]) {
        expect(field.wireName(17), field.wireName(18), reason: '$field');
      }
      expect(TorrentField.id.wireName(17), 'id');
      expect(TorrentField.id.wireName(18), 'id');
    });

    test('a version above 18 still uses the modern spelling', () {
      expect(TorrentField.percentDone.wireName(19), 'percent_done');
    });
  });

  group('WireKey', () {
    test('forVersion picks the spelling for the dialect', () {
      const key = WireKey('percentDone', 'percent_done');
      expect(key.forVersion(17), 'percentDone');
      expect(key.forVersion(18), 'percent_done');
    });

    test('WireKey.same uses one spelling for both', () {
      const key = WireKey.same('id');
      expect(key.forVersion(17), 'id');
      expect(key.forVersion(18), 'id');
      expect(key.toString(), 'id');
    });
  });

  group('fields with no legacy spelling', () {
    test('a field added in 4.1 is spelled the same in both dialects', () {
      expect(
        TorrentField.sequentialDownload.wireName(17),
        'sequential_download',
      );
      expect(
        TorrentField.sequentialDownload.wireName(17),
        TorrentField.sequentialDownload.wireName(18),
      );
      expect(
        TorrentField.sequentialDownloadFromPiece.wireName(17),
        'sequential_download_from_piece',
      );
      expect(
        TorrentField.sequentialDownloadFromPiece.wireName(17),
        TorrentField.sequentialDownloadFromPiece.wireName(18),
      );
    });

    test('a field added in 4.2 is spelled the same in both dialects', () {
      expect(TorrentField.webseedsEx.wireName(17), 'webseeds_ex');
      expect(
        TorrentField.webseedsEx.wireName(17),
        TorrentField.webseedsEx.wireName(18),
      );
    });

    test('a renamed field, by contrast, differs between the two', () {
      expect(
        TorrentField.webseedsSendingToUs.wireName(17),
        isNot(TorrentField.webseedsSendingToUs.wireName(18)),
      );
      expect(
        TorrentField.percentDone.wireName(17),
        isNot(TorrentField.percentDone.wireName(18)),
      );
    });
  });

  group('TorrentField.defaults', () {
    test('holds 20 fields', () {
      expect(TorrentField.defaults, hasLength(20));
    });

    test('covers the essentials a torrent list needs', () {
      expect(
        TorrentField.defaults,
        containsAll([
          TorrentField.id,
          TorrentField.name,
          TorrentField.eta,
          TorrentField.status,
          TorrentField.percentDone,
        ]),
      );
    });

    test('has no duplicates', () {
      expect(
        TorrentField.defaults.toSet(),
        hasLength(TorrentField.defaults.length),
      );
    });
  });

  group('torrent-get fields on the wire', () {
    test('legacy asks for camelCase field names', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'torrents': []}));

      await h.client.torrents(
        fields: [
          TorrentField.id,
          TorrentField.percentDone,
          TorrentField.rateDownload,
        ],
      );

      expect(h.mock.lastArguments['fields'], [
        'id',
        'percentDone',
        'rateDownload',
      ]);
    });

    test('v18 asks for snake_case field names', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success({'torrents': []}));

      await h.client.torrents(
        fields: [
          TorrentField.id,
          TorrentField.percentDone,
          TorrentField.rateDownload,
        ],
      );

      expect(h.mock.lastArguments['fields'], [
        'id',
        'percent_done',
        'rate_download',
      ]);
    });

    test(
      'the default field list goes out in the dialect of the daemon',
      () async {
        final legacy = buildClient();
        legacy.mock.respondWith(legacySuccess({'torrents': []}));
        await legacy.client.torrents();
        expect(legacy.mock.lastArguments['fields'], contains('percentDone'));
        expect(
          legacy.mock.lastArguments['fields'],
          isNot(contains('percent_done')),
        );

        final modern = await buildV18Client();
        modern.mock.respondWith(v18Success({'torrents': []}));
        await modern.client.torrents();
        expect(modern.mock.lastArguments['fields'], contains('percent_done'));
        expect(
          modern.mock.lastArguments['fields'],
          isNot(contains('percentDone')),
        );
      },
    );
  });

  group('session-set arguments on the wire', () {
    test('legacy sends kebab-case alt-speed-down', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setSession(altSpeedDown: 50);

      expect(h.mock.lastArguments, {'alt-speed-down': 50});
    });

    test('v18 sends snake_case alt_speed_down', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success());

      await h.client.setSession(altSpeedDown: 50);

      expect(h.mock.lastArguments, {'alt_speed_down': 50});
    });

    test('only the arguments that were passed are sent', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setSession(speedLimitUp: 100, speedLimitUpEnabled: true);

      expect(h.mock.lastArguments, {
        'speed-limit-up-enabled': true,
        'speed-limit-up': 100,
      });
    });

    test('legacy sends kebab-case tcp-enabled and utp-enabled', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setSession(
        // ignore: deprecated_member_use_from_same_package
        tcpEnabled: false,
        // ignore: deprecated_member_use_from_same_package
        utpEnabled: true,
      );

      expect(h.mock.lastArguments, {'tcp-enabled': false, 'utp-enabled': true});
    });

    test('v18 sends snake_case tcp_enabled and utp_enabled', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success());

      await h.client.setSession(
        // ignore: deprecated_member_use_from_same_package
        tcpEnabled: false,
        // ignore: deprecated_member_use_from_same_package
        utpEnabled: true,
      );

      expect(h.mock.lastArguments, {'tcp_enabled': false, 'utp_enabled': true});
    });

    test('sequential-download has one spelling in both dialects', () async {
      final legacy = buildClient();
      legacy.mock.respondWith(legacySuccess());
      await legacy.client.setSession(sequentialDownload: true);
      expect(legacy.mock.lastArguments, {'sequential_download': true});

      final modern = await buildV18Client();
      modern.mock.respondWith(v18Success());
      await modern.client.setSession(sequentialDownload: true);
      expect(modern.mock.lastArguments, {'sequential_download': true});
    });
  });

  group('torrent-remove arguments on the wire', () {
    test('legacy sends delete-local-data', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.removeTorrents([1], deleteLocalData: true);

      expect(h.mock.lastArguments, {
        'ids': [1],
        'delete-local-data': true,
      });
    });

    test('v18 sends delete_local_data', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success());

      await h.client.removeTorrents([1], deleteLocalData: true);

      expect(h.mock.lastArguments, {
        'ids': [1],
        'delete_local_data': true,
      });
    });
  });

  group('torrent-set arguments on the wire', () {
    test('legacy sends the sequential fields under their one name', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.setTorrents(
        ids: [1],
        sequentialDownload: true,
        sequentialDownloadFromPiece: 42,
      );

      expect(h.mock.lastArguments, {
        'ids': [1],
        'sequential_download': true,
        'sequential_download_from_piece': 42,
      });
    });

    test('v18 sends exactly the same names', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Success());

      await h.client.setTorrents(
        ids: [1],
        sequentialDownload: true,
        sequentialDownloadFromPiece: 42,
      );

      expect(h.mock.lastArguments, {
        'ids': [1],
        'sequential_download': true,
        'sequential_download_from_piece': 42,
      });
    });
  });

  group('torrent-add arguments on the wire', () {
    test('legacy sends sequential_download_from_piece unchanged', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({
          'torrent-added': {'id': 3, 'name': 'debian-12.iso'},
        }),
      );

      await h.client.addTorrent(
        filename: 'x.torrent',
        sequentialDownloadFromPiece: 7,
      );

      expect(h.mock.lastArguments, {
        'filename': 'x.torrent',
        'sequential_download_from_piece': 7,
      });
    });

    test('v18 sends exactly the same name', () async {
      final h = await buildV18Client();
      h.mock.respondWith(
        v18Success({
          'torrent_added': {'id': 3, 'name': 'debian-12.iso'},
        }),
      );

      await h.client.addTorrent(
        filename: 'x.torrent',
        sequentialDownloadFromPiece: 7,
      );

      expect(h.mock.lastArguments, {
        'filename': 'x.torrent',
        'sequential_download_from_piece': 7,
      });
    });
  });
}
