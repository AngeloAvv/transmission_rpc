/// Base class for every error this library throws.
///
/// All of them implement [Exception] rather than `Error`: they are recoverable
/// conditions a caller is expected to catch, not programmer mistakes.
sealed class TransmissionException implements Exception {
  /// Human readable description of what went wrong.
  final String message;

  /// The underlying exception, when this one wraps a lower level failure.
  final Exception? cause;

  const TransmissionException(this.message, {this.cause});
}

/// Thrown when the server rejects the credentials (HTTP 401).
///
/// Typically means the `username`/`password` passed to the `Transmission`
/// constructor are missing or wrong.
class AuthenticationError extends TransmissionException {
  const AuthenticationError(super.message, {super.cause});

  @override
  String toString() => 'AuthenticationError: $message';
}

/// Thrown when the daemon answers but the call itself failed: a non-401 HTTP
/// error, a legacy `result` other than `success`, or a JSON-RPC error object.
class RpcError extends TransmissionException {
  /// The JSON-RPC 2.0 error code (for example -32601, method not found).
  ///
  /// Null for legacy responses and for HTTP level failures, which carry no code.
  final int? code;

  const RpcError(super.message, {this.code, super.cause});

  @override
  String toString() => 'RpcError($code): $message';
}

/// Thrown when the request never reached the daemon: connection refused, DNS
/// failure, timeout, bad certificate, or a cancelled request.
class NetworkError extends TransmissionException {
  const NetworkError(super.message, {super.cause});

  @override
  String toString() => 'NetworkError: $message';
}
