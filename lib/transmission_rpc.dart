/// An RPC client for the Transmission BitTorrent daemon.
///
/// Create a [Transmission] and call its methods; the client detects which RPC
/// dialect the daemon speaks (legacy, or the JSON-RPC 2.0 one introduced in
/// Transmission 4.1) and adapts both the requests it sends and the responses it
/// parses.
library;

export 'package:talker/talker.dart' show LogLevel;

export 'src/errors.dart';
export 'src/fields.dart';
export 'src/keys/wire_key.dart' show WireKey;
export 'src/models/free_space.dart';
export 'src/models/group.dart';
export 'src/models/ip_protocol.dart';
export 'src/models/session.dart';
export 'src/models/session_stats.dart';
export 'src/models/test_port.dart';
export 'src/models/torrent.dart';
export 'src/transmission.dart';
