import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:talker/talker.dart';
import 'package:test/test.dart';
import 'package:transmission_rpc/transmission_rpc.dart';

import 'helpers/mock_adapter.dart';

/// Everything [talker] has recorded, as the text a shared log would contain.
String historyText(Talker talker) =>
    talker.history.map((entry) => entry.generateTextMessage()).join('\n');

void main() {
  group('logging', () {
    const username = 'alice';
    const password = 's3cret-passw0rd';
    final basicToken = base64Encode(utf8.encode('$username:$password'));

    late MockHttpClientAdapter mock;
    late Talker talker;

    Transmission buildLoggingClient({Dio? dio, bool credentials = true}) {
      mock = MockHttpClientAdapter();
      talker = Talker();
      final client = dio ?? Dio();
      client.httpClientAdapter = mock;
      return Transmission(
        baseUrl: 'http://localhost:9091/transmission/rpc',
        username: credentials ? username : null,
        password: credentials ? password : null,
        logLevel: LogLevel.debug,
        talker: talker,
        httpClient: client,
      );
    }

    test('keeps the Basic credentials out of the log history', () async {
      final client = buildLoggingClient();
      mock.respondInOrder([
        csrfChallenge(sessionId: 'session-123'),
        legacySuccess({'torrents': []}),
      ]);

      await client.torrents();

      // The credentials really were sent to the daemon...
      expect(mock.sentHeaders.last['authorization'], 'Basic $basicToken');

      // ...but never reached the log, whichever way they are spelled.
      final log = historyText(talker);
      expect(log, isNot(contains(basicToken)));
      expect(log, isNot(contains(password)));
      expect(log, isNot(contains(base64Encode(utf8.encode(username)))));
    });

    test('still logs the other request headers', () async {
      final client = buildLoggingClient();
      mock.respondInOrder([
        csrfChallenge(sessionId: 'session-123'),
        legacySuccess({'torrents': []}),
      ]);

      await client.torrents();

      final log = historyText(talker);
      // The request log is there and its header block is not empty: the
      // Authorization entry is masked, not the whole block dropped.
      expect(log, contains('Headers:'));
      expect(log, contains('authorization'));
      // The anti-CSRF token is not a secret and helps diagnose RPC issues.
      expect(log, contains('X-Transmission-Session-Id'));
      expect(log, contains('session-123'));
      expect(log, contains('content-type'));
    });

    test('masks an Authorization header however it is capitalised', () async {
      // A caller-supplied Dio can carry its own header, spelled differently.
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer top-secret-token';
      final client = buildLoggingClient(dio: dio, credentials: false);
      mock.respondWith(legacySuccess({'torrents': []}));

      await client.torrents();

      expect(historyText(talker), isNot(contains('top-secret-token')));
    });
  });
}
