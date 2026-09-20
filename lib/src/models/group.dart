import 'package:transmission_rpc/src/json.dart';
import 'package:transmission_rpc/src/keys/session_keys.dart';

/// A bandwidth group (Transmission 4.0+), as returned by `group-get`.
///
/// Torrents assigned to a group share its speed limits.
class Group {
  /// Whether the group's torrents also obey the global session limits.
  final bool honorsSessionLimits;

  /// The group's name, used to reference it from a torrent.
  final String name;

  /// Whether the group's download limit is applied.
  final bool speedLimitDownEnabled;

  /// Whether the group's upload limit is applied.
  final bool speedLimitUpEnabled;

  /// Download limit for the group, in KB/s.
  final int speedLimitDown;

  /// Upload limit for the group, in KB/s.
  final int speedLimitUp;

  const Group({
    required this.honorsSessionLimits,
    required this.name,
    required this.speedLimitDownEnabled,
    required this.speedLimitUpEnabled,
    required this.speedLimitDown,
    required this.speedLimitUp,
  });

  /// Parses one entry of the `group` list in a `group-get` response.
  factory Group.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Group(
      honorsSessionLimits: reader.nonNullBoolOf(
        SessionKeys.honorsSessionLimits,
      ),
      name: reader.nonNullStringOf(SessionKeys.groupName),
      speedLimitDownEnabled: reader.nonNullBoolOf(
        SessionKeys.groupSpeedLimitDownEnabled,
      ),
      speedLimitUpEnabled: reader.nonNullBoolOf(
        SessionKeys.groupSpeedLimitUpEnabled,
      ),
      speedLimitDown: reader.nonNullIntOf(SessionKeys.groupSpeedLimitDown),
      speedLimitUp: reader.nonNullIntOf(SessionKeys.groupSpeedLimitUp),
    );
  }
}
