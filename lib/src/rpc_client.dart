import 'package:transmission_rpc/src/errors.dart';
import 'package:dio/dio.dart';
import 'package:talker/talker.dart';

const _csrfHeader = 'X-Transmission-Session-Id';

/// Dio lowercases every response header name, so this must stay lowercase.
const _rpcVersionHeader = 'x-transmission-rpc-version';

/// Sends Transmission RPC calls over HTTP, hiding the difference between the
/// legacy protocol and the JSON-RPC 2.0 one introduced in Transmission 4.1.
///
/// The client starts out assuming the legacy protocol and upgrades itself the
/// moment the daemon reveals a newer RPC version, either through the
/// `X-Transmission-Rpc-Version` header of a 409 handshake or through the
/// `rpc-version` fields returned by `session-get`.
class RpcClient {
  /// The last RPC version that used the legacy envelope.
  ///
  /// Assumed until a newer daemon is detected: every Transmission build still
  /// understands the legacy protocol, so guessing low is always safe whereas
  /// guessing high breaks older daemons.
  static const int defaultRpcVersion = 17;

  final Dio _dio;
  final Talker? _logger;

  int _rpcVersion = defaultRpcVersion;
  String? _rpcVersionSemver;
  int _id = 0;

  /// Wraps [dio] and installs the CSRF and version-detection interceptors on it.
  RpcClient(this._dio, {Talker? logger}) : _logger = logger {
    // Order matters: Dio fires error interceptors FIFO, so the detector must
    // see the 409 before the CSRF interceptor swallows it by replaying.
    _dio.interceptors.add(_VersionDetectorInterceptor(this));
    _dio.interceptors.add(_CsrfInterceptor(dio: _dio, logger: logger));
  }

  /// RPC version of the connected daemon; 17 until a newer one is detected.
  int get rpcVersion => _rpcVersion;

  /// Semver string reported by the daemon, or null if not seen yet.
  String? get rpcVersionSemver => _rpcVersionSemver;

  /// Performs [method] with [args] and returns the response arguments.
  ///
  /// Throws [AuthenticationError], [RpcError] or [NetworkError].
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    _logger?.debug('RPC $method');
    final raw = await _post(_envelope(method, args));
    final result = _unwrap(raw);
    _absorbVersion(result);
    return result;
  }

  Map<String, dynamic> _envelope(String method, Map<String, dynamic>? args) {
    if (_rpcVersion >= 18) {
      return {
        'jsonrpc': '2.0',
        'method': method.replaceAll('-', '_'),
        'params': args ?? <String, dynamic>{},
        'id': ++_id,
      };
    }
    // Legacy daemons can reject an explicit `arguments: null`, so omit it.
    return {'method': method, if (args != null) 'arguments': args};
  }

  /// Unwraps a response body.
  ///
  /// The shape decides, not the detected version: a request sent as legacy and
  /// replayed after the version was upgraded mid-handshake still comes back in
  /// the dialect it was sent in.
  Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final isJsonRpc = raw.containsKey('jsonrpc') || raw['result'] is Map;
    if (isJsonRpc) {
      final error = raw['error'];
      if (error is Map) {
        throw RpcError(
          error['message'] as String? ?? 'unknown',
          code: error['code'] as int?,
        );
      }
      final result = raw['result'];
      // Some methods answer with no payload at all.
      return result is Map<String, dynamic> ? result : <String, dynamic>{};
    }

    final result = raw['result'];
    if (result != 'success') {
      throw RpcError(result as String? ?? 'unknown');
    }
    final args = raw['arguments'];
    return args is Map<String, dynamic> ? args : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('', data: body);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e, stackTrace) {
      _logger?.error('RPC request failed', e, stackTrace);
      if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw AuthenticationError(
            'Authentication failed (HTTP 401)',
            cause: e,
          );
        }
        int? code;
        final data = e.response?.data;
        if (data is Map) {
          final errorObj = data['error'];
          if (errorObj is Map) code = errorObj['code'] as int?;
        }
        throw RpcError(
          e.message ?? 'Server error (HTTP $statusCode)',
          code: code,
          cause: e,
        );
      }
      throw NetworkError(e.message ?? 'Network error', cause: e);
    }
  }

  /// Picks up the version fields a `session-get` response carries, so callers
  /// never have to feed the version back in themselves.
  void _absorbVersion(Map<String, dynamic> args) {
    final semver = (args['rpc_version_semver'] ?? args['rpc-version-semver']);
    if (semver is String) {
      _rpcVersionSemver = semver;
      if ((int.tryParse(semver.split('.').first) ?? 0) >= 6) _upgrade(18);
    }
    final version = (args['rpc_version'] ?? args['rpc-version']);
    if (version is int && version >= 18) _upgrade(version);
  }

  /// Raises the detected version; a detected 18 is never downgraded.
  void _upgrade(int version) {
    if (version > _rpcVersion) _rpcVersion = version;
  }

  /// Called by [_VersionDetectorInterceptor] for the 409 handshake header,
  /// which carries either a semver string ("6.0.0") or a bare integer ("18").
  void _detectFromHeader(String value) {
    final head = int.tryParse(value.split('.').first);
    if (head == null) return;
    // A semver major of 6 (Transmission 4.1.0+) corresponds to RPC 18.
    // A bare integer in this header is the RPC version itself.
    final threshold = value.contains('.') ? 6 : 18;
    if (head >= threshold) _upgrade(18);
  }
}

/// Reads the RPC version advertised on a 409 response and lets the error
/// continue downstream so [_CsrfInterceptor] can still replay the request.
class _VersionDetectorInterceptor extends QueuedInterceptor {
  final RpcClient _client;

  _VersionDetectorInterceptor(this._client);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 409) {
      final value = err.response!.headers.value(_rpcVersionHeader);
      if (value != null) _client._detectFromHeader(value);
    }
    super.onError(err, handler);
  }
}

/// Handles the `X-Transmission-Session-Id` handshake: a 409 carries the token
/// to use, which is stored and the original request replayed with it.
///
/// Queued so that concurrent calls do not all stampede for a fresh token.
class _CsrfInterceptor extends QueuedInterceptor {
  final Dio dio;
  final Talker? logger;

  String? _token;

  _CsrfInterceptor({required this.dio, this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null) options.headers[_csrfHeader] = _token;
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 409) {
      super.onError(err, handler);
      return;
    }

    final options = err.requestOptions;
    if (_token == options.headers[_csrfHeader]) {
      // Our token is the one that was rejected — take the server's fresh one.
      _token = err.response!.headers.value(_csrfHeader) ?? _token;
    }
    options.headers[_csrfHeader] = _token;

    logger?.debug('Retrying request with new CSRF token');

    try {
      handler.resolve(await dio.fetch(options));
    } on DioException catch (e, stackTrace) {
      logger?.error('Retry after CSRF handshake failed', e, stackTrace);
      handler.reject(e);
    } catch (error, stackTrace) {
      // Every path must complete the handler, otherwise the caller's Future
      // never resolves.
      logger?.error('Retry after CSRF handshake failed', error, stackTrace);
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          message: 'Retry after CSRF handshake failed: $error',
        ),
      );
    }
  }
}
