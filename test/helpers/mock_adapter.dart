import 'dart:convert';

import 'package:transmission_rpc/transmission_rpc.dart';
import 'package:dio/dio.dart';

/// The CSRF token header Transmission uses for its 409 handshake.
const csrfHeader = 'X-Transmission-Session-Id';

/// The header a Transmission 4.1+ daemon advertises its RPC version on.
const rpcVersionHeader = 'X-Transmission-Rpc-Version';

/// Answers one request; set it on a [MockHttpClientAdapter] before the call.
typedef AdapterHandler = Future<MockResponse> Function(RequestOptions options);

/// A canned HTTP response.
///
/// A Dio [ResponseBody] wraps a single-subscription stream, so it can only be
/// delivered once; a [MockResponse] remembers the bytes instead and builds a
/// fresh body for every request it answers.
class MockResponse {
  final String body;
  final int statusCode;
  final Map<String, List<String>> headers;

  const MockResponse(this.body, this.statusCode, this.headers);

  /// A fresh [ResponseBody] carrying this response.
  ResponseBody build() =>
      ResponseBody.fromString(body, statusCode, headers: headers);
}

/// A [HttpClientAdapter] that answers with pre-programmed responses and
/// remembers every request it was asked to send.
///
/// ```dart
/// final h = buildClient();
/// h.mock.respondWith(legacySuccess({'torrents': []}));
/// await h.client.torrents();
/// expect(h.mock.lastMethod, 'torrent-get');
/// ```
class MockHttpClientAdapter implements HttpClientAdapter {
  /// Answers the next request. Set it directly for full control, or use
  /// [respondWith] / [respondInOrder].
  AdapterHandler? handler;

  /// Every request the adapter was handed, oldest first.
  ///
  /// Dio reuses the same [RequestOptions] instance when a request is replayed
  /// after the CSRF handshake, so assert on [sentHeaders] and [sentBodies],
  /// which are snapshots taken at send time.
  final List<RequestOptions> requests = <RequestOptions>[];

  /// Headers as they were at the moment each request went out.
  final List<Map<String, dynamic>> sentHeaders = <Map<String, dynamic>>[];

  /// Request bodies as they were at the moment each request went out.
  final List<Map<String, dynamic>> sentBodies = <Map<String, dynamic>>[];

  /// Answers every request with [response].
  void respondWith(MockResponse response) {
    handler = (_) async => response;
  }

  /// Answers the requests with [responses] in order; once they run out the last
  /// one is repeated.
  void respondInOrder(List<MockResponse> responses) {
    assert(responses.isNotEmpty, 'respondInOrder needs at least one response');
    var index = 0;
    handler = (_) async {
      final response = responses[index.clamp(0, responses.length - 1)];
      index++;
      return response;
    };
  }

  /// Forgets every recorded request, keeping the current [handler].
  void reset() {
    requests.clear();
    sentHeaders.clear();
    sentBodies.clear();
  }

  /// How many requests actually went out.
  int get requestCount => requests.length;

  /// The body of the most recent request.
  Map<String, dynamic> get lastBody => sentBodies.last;

  /// The RPC method name of the most recent request.
  String get lastMethod => lastBody['method'] as String;

  /// The arguments of the most recent request, whichever envelope carried them.
  Map<String, dynamic> get lastArguments {
    final args = lastBody['arguments'] ?? lastBody['params'];
    return args == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(args as Map);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final h = handler;
    if (h == null) {
      throw StateError(
        'MockHttpClientAdapter has no handler. Call respondWith(), '
        'respondInOrder() or set handler before the request.',
      );
    }
    requests.add(options);
    sentHeaders.add(Map<String, dynamic>.from(options.headers));
    final data = options.data;
    sentBodies.add(
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
    return (await h(options)).build();
  }

  @override
  void close({bool force = false}) {}
}

/// An adapter whose every request dies before reaching a daemon.
class NetworkErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'Simulated network failure',
    );
  }

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Response builders
// ---------------------------------------------------------------------------

MockResponse _json(
  Object body,
  int status, {
  Map<String, List<String>> headers = const {},
}) => MockResponse(body is String ? body : jsonEncode(body), status, {
  Headers.contentTypeHeader: [Headers.jsonContentType],
  ...headers,
});

/// `{"result": "success", "arguments": {...}}` — the legacy success envelope.
MockResponse legacySuccess([Map<String, dynamic> arguments = const {}]) =>
    _json({'result': 'success', 'arguments': arguments}, 200);

/// `{"result": "<message>"}` — how a legacy daemon reports a failed call.
MockResponse legacyError(String message) => _json({'result': message}, 200);

/// `{"jsonrpc": "2.0", "result": {...}, "id": 1}` — the v18 success envelope.
MockResponse v18Success([Map<String, dynamic> result = const {}]) =>
    _json({'jsonrpc': '2.0', 'result': result, 'id': 1}, 200);

/// `{"jsonrpc": "2.0", "error": {"code": .., "message": ..}, "id": 1}`.
MockResponse v18Error(String message, {int code = -32600}) => _json({
  'jsonrpc': '2.0',
  'error': {'code': code, 'message': message},
  'id': 1,
}, 200);

/// HTTP 401, which the client turns into an [AuthenticationError].
MockResponse unauthorized() => _json('', 401);

/// The 409 a Transmission daemon answers with when the CSRF token is missing
/// or stale, optionally advertising its RPC version the way 4.1+ does.
MockResponse csrfChallenge({String sessionId = 'abc', String? rpcVersion}) =>
    _json(
      <String, dynamic>{},
      409,
      headers: {
        csrfHeader: [sessionId],
        if (rpcVersion != null) rpcVersionHeader: [rpcVersion],
      },
    );

// ---------------------------------------------------------------------------
// Client builders
// ---------------------------------------------------------------------------

/// A [Transmission] plus the mock adapter that answers for it.
typedef TestClient = ({Transmission client, MockHttpClientAdapter mock});

/// Builds a [Transmission] talking to a [MockHttpClientAdapter].
///
/// The client starts out speaking the legacy dialect, like a freshly
/// constructed one against an unknown daemon.
TestClient buildClient() {
  final mock = MockHttpClientAdapter();
  final dio = Dio()..httpClientAdapter = mock;
  final client = Transmission(
    baseUrl: 'http://localhost:9091/transmission/rpc',
    httpClient: dio,
  );
  return (client: client, mock: mock);
}

/// Builds a [Transmission] that has already learned its daemon speaks RPC 18,
/// by priming it with a `session-get` that reports the version.
///
/// The recorded requests are cleared, so the next call is the first one a test
/// has to reason about.
Future<TestClient> buildV18Client() async {
  final h = buildClient();
  h.mock.respondWith(
    legacySuccess({'rpc_version': 18, 'rpc_version_semver': '4.1.0'}),
  );
  await h.client.session();
  h.mock.reset();
  return h;
}

/// Builds a [Transmission] whose every request fails to reach a daemon.
Transmission buildNetworkErrorClient() {
  final dio = Dio()..httpClientAdapter = NetworkErrorAdapter();
  return Transmission(
    baseUrl: 'http://localhost:9091/transmission/rpc',
    httpClient: dio,
  );
}
