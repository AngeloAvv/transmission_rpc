import 'package:transmission_rpc/transmission_rpc.dart';
import 'package:test/test.dart';

import 'helpers/mock_adapter.dart';

void main() {
  group('legacy envelope', () {
    test('wraps the call in {method, arguments} and no jsonrpc key', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.startTorrents([1]);

      expect(h.mock.requestCount, 1);
      expect(h.mock.lastBody, {
        'method': 'torrent-start',
        'arguments': {
          'ids': [1],
        },
      });
      expect(h.mock.lastBody.containsKey('jsonrpc'), isFalse);
      expect(h.mock.lastBody.containsKey('id'), isFalse);
    });

    test('omits arguments entirely for a call that takes none', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess());

      await h.client.closeSession();

      expect(h.mock.lastBody, {'method': 'session-close'});
    });

    test('assumes RPC 17 until told otherwise', () {
      final h = buildClient();
      expect(h.client.rpcVersion, 17);
      expect(h.client.rpcVersionSemver, isNull);
    });
  });

  group('version detection', () {
    test('a 409 advertising semver 6.0.0 upgrades the next request', () async {
      final h = buildClient();
      h.mock.respondInOrder([
        csrfChallenge(rpcVersion: '6.0.0'),
        legacySuccess(),
        v18Success(),
      ]);

      // First call: legacy envelope, 409 handshake, replay.
      await h.client.startTorrents([1]);
      expect(h.client.rpcVersion, 18);

      h.mock.reset();
      await h.client.startTorrents([2]);

      expect(h.mock.lastBody['jsonrpc'], '2.0');
      expect(h.mock.lastBody['method'], 'torrent_start');
      expect(h.mock.lastBody['params'], {
        'ids': [2],
      });
      expect(h.mock.lastBody['id'], isA<int>());
      expect(h.mock.lastBody.containsKey('arguments'), isFalse);
    });

    test('a 409 advertising a bare 18 upgrades too', () async {
      final h = buildClient();
      h.mock.respondInOrder([csrfChallenge(rpcVersion: '18'), legacySuccess()]);

      await h.client.stopTorrents([1]);

      expect(h.client.rpcVersion, 18);
    });

    test(
      'a 409 advertising semver 5.0.0 stays on the legacy dialect',
      () async {
        final h = buildClient();
        h.mock.respondInOrder([
          csrfChallenge(rpcVersion: '5.0.0'),
          legacySuccess(),
        ]);

        await h.client.stopTorrents([1]);
        expect(h.client.rpcVersion, 17);

        h.mock.reset();
        await h.client.stopTorrents([2]);
        expect(h.mock.lastBody['method'], 'torrent-stop');
      },
    );

    test('session() carrying rpc_version/semver upgrades the client', () async {
      final h = buildClient();
      h.mock.respondWith(
        legacySuccess({'rpc_version': 18, 'rpc_version_semver': '4.1.0'}),
      );

      await h.client.session();

      expect(h.client.rpcVersion, 18);
      expect(h.client.rpcVersionSemver, '4.1.0');
    });

    test('session() of a 3.x daemon leaves the client on legacy', () async {
      final h = buildClient();
      h.mock.respondWith(legacySuccess({'rpc-version': 17, 'version': '3.00'}));

      await h.client.session();

      expect(h.client.rpcVersion, 17);
      expect(h.client.rpcVersionSemver, isNull);
    });
  });

  group('CSRF handshake', () {
    test('replays the request with the token from the 409', () async {
      final h = buildClient();
      h.mock.respondInOrder([
        csrfChallenge(sessionId: 'abc'),
        legacySuccess({'torrents': []}),
      ]);

      final torrents = await h.client.torrents();

      expect(torrents, isEmpty);
      expect(h.mock.requestCount, 2);
      expect(h.mock.sentHeaders[0][csrfHeader], isNull);
      expect(h.mock.sentHeaders[1][csrfHeader], 'abc');
    });

    test('reuses the token on subsequent calls without a second 409', () async {
      final h = buildClient();
      h.mock.respondInOrder([
        csrfChallenge(sessionId: 'abc'),
        legacySuccess(),
        legacySuccess(),
      ]);

      await h.client.stopTorrents([1]);
      h.mock.reset();
      await h.client.stopTorrents([2]);

      expect(h.mock.requestCount, 1);
      expect(h.mock.sentHeaders.single[csrfHeader], 'abc');
    });
  });

  group('errors', () {
    test('legacy non-success result becomes an RpcError', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('no such torrent'));

      await expectLater(
        h.client.stopTorrents([99]),
        throwsA(
          isA<RpcError>().having(
            (e) => e.message,
            'message',
            'no such torrent',
          ),
        ),
      );
    });

    test('v18 error object becomes an RpcError carrying its code', () async {
      final h = await buildV18Client();
      h.mock.respondWith(v18Error('Method not found', code: -32601));

      await expectLater(
        h.client.stopTorrents([1]),
        throwsA(
          isA<RpcError>()
              .having((e) => e.code, 'code', -32601)
              .having((e) => e.message, 'message', 'Method not found'),
        ),
      );
    });

    test('HTTP 401 becomes an AuthenticationError', () async {
      final h = buildClient();
      h.mock.respondWith(unauthorized());

      await expectLater(
        h.client.session(),
        throwsA(isA<AuthenticationError>()),
      );
    });

    test('a connection failure becomes a NetworkError', () async {
      final client = buildNetworkErrorClient();

      await expectLater(client.session(), throwsA(isA<NetworkError>()));
    });

    test('every error is a TransmissionException', () async {
      final h = buildClient();
      h.mock.respondWith(legacyError('boom'));

      await expectLater(
        h.client.session(),
        throwsA(isA<TransmissionException>()),
      );
    });
  });
}
