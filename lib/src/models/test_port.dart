import 'package:transmission_rpc/src/json.dart';
import 'package:transmission_rpc/src/keys/session_keys.dart';
import 'package:transmission_rpc/src/models/ip_protocol.dart';

/// The result of a `port-test` call: whether the daemon's peer port is
/// reachable from the outside.
class TestPort {
  /// Whether the peer port accepted an incoming connection.
  final bool portIsOpen;

  /// The protocol the test ran over. Null on daemons older than
  /// Transmission 4.0, which do not echo it back.
  final IpProtocol? ipProtocol;

  const TestPort({required this.portIsOpen, this.ipProtocol});

  /// Parses the `arguments` object of a `port-test` response.
  factory TestPort.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return TestPort(
      portIsOpen: reader.nonNullBoolOf(SessionKeys.portIsOpen),
      ipProtocol: IpProtocol.fromWire(reader.stringOf(SessionKeys.ipProtocol)),
    );
  }
}
