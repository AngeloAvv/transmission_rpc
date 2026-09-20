import 'package:transmission_rpc/src/errors.dart';
import 'package:transmission_rpc/src/keys/wire_key.dart';

/// Reads values out of a decoded RPC payload without caring which protocol
/// dialect produced it.
///
/// Every lookup tries the modern field name first and falls back to the legacy
/// one, so a response from Transmission 3.x parses exactly as well as one from
/// 4.1+ — no version detection needed on the way in.
extension type Json(Map<String, dynamic> map) {
  /// The raw value for [key], whichever spelling the server used.
  Object? raw(WireKey key) => map[key.modern] ?? map[key.legacy];

  /// Reads [key] as an `int`, accepting any JSON number.
  int? intOf(WireKey key) => (raw(key) as num?)?.toInt();

  /// Reads [key] as a `double`, accepting any JSON number.
  double? doubleOf(WireKey key) => (raw(key) as num?)?.toDouble();

  /// Reads [key] as a `String`.
  String? stringOf(WireKey key) => raw(key) as String?;

  /// Reads [key] as a `bool`, accepting `0`/`1` as well as `true`/`false`
  /// (older daemons send integers for some flags).
  bool? boolOf(WireKey key) => switch (raw(key)) {
    final bool value => value,
    final num value => value != 0,
    _ => null,
  };

  /// Reads [key] as a `String` the spec guarantees is present.
  ///
  /// Throws [RpcError] if the response is missing it.
  String nonNullStringOf(WireKey key) => stringOf(key) ?? _missing(key);

  /// Reads [key] as an `int` the spec guarantees is present.
  ///
  /// Throws [RpcError] if the response is missing it.
  int nonNullIntOf(WireKey key) => intOf(key) ?? _missing(key);

  /// Reads [key] as a `bool` the spec guarantees is present.
  ///
  /// Throws [RpcError] if the response is missing it.
  bool nonNullBoolOf(WireKey key) => boolOf(key) ?? _missing(key);

  Never _missing(WireKey key) =>
      throw RpcError('Response is missing required field "$key"');

  /// Reads [key] as a list of primitives of type [T].
  List<T>? listOf<T>(WireKey key) {
    final value = raw(key);
    if (value is! List) return null;
    return value.whereType<T>().toList(growable: false);
  }

  /// Reads [key] as a list of numbers mapped through [convert].
  List<T>? numListOf<T extends num>(WireKey key, T Function(num) convert) {
    final value = raw(key);
    if (value is! List) return null;
    return value.whereType<num>().map(convert).toList(growable: false);
  }

  /// Reads [key] as a nested object parsed by [parse].
  T? objectOf<T>(WireKey key, T Function(Map<String, dynamic>) parse) {
    final value = raw(key);
    if (value is! Map) return null;
    return parse(Map<String, dynamic>.from(value));
  }

  /// Reads [key] as a list of nested objects parsed by [parse].
  List<T>? objectListOf<T>(
    WireKey key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final value = raw(key);
    if (value is! List) return null;
    return value
        .whereType<Map>()
        .map((element) => parse(Map<String, dynamic>.from(element)))
        .toList(growable: false);
  }
}

/// Builds an RPC argument map for a server speaking [rpcVersion], picking the
/// right spelling for each key and dropping entries whose value is null.
Map<String, dynamic> rpcArgs(int rpcVersion, Map<WireKey, Object?> entries) => {
  for (final entry in entries.entries)
    if (entry.value != null) entry.key.forVersion(rpcVersion): entry.value,
};
