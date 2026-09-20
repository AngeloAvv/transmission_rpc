import 'package:transmission_rpc/src/json.dart';
import 'package:transmission_rpc/src/keys/session_keys.dart';

/// Disk space available at a path, as returned by the `free-space` method.
class FreeSpace {
  /// The path that was queried.
  final String path;

  /// Free bytes available at [path].
  final int sizeBytes;

  /// Total capacity of the volume holding [path], in bytes.
  ///
  /// Null on daemons older than Transmission 4.0, which do not report it.
  final int? totalSize;

  const FreeSpace({
    required this.path,
    required this.sizeBytes,
    this.totalSize,
  });

  /// Parses the `arguments` object of a `free-space` response.
  factory FreeSpace.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return FreeSpace(
      path: reader.nonNullStringOf(SessionKeys.path),
      sizeBytes: reader.nonNullIntOf(SessionKeys.freeSpaceSizeBytes),
      totalSize: reader.intOf(SessionKeys.totalSize),
    );
  }
}
