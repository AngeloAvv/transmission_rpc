/// The IP protocol version a `port-test` call targets.
enum IpProtocol {
  /// IPv4.
  ipv4,

  /// IPv6.
  ipv6;

  /// The spelling to send on the wire.
  String get wireValue => switch (this) {
    IpProtocol.ipv4 => 'ipv4',
    IpProtocol.ipv6 => 'ipv6',
  };

  /// Parses the wire spelling, returning null for anything unrecognised.
  static IpProtocol? fromWire(String? value) => switch (value) {
    'ipv4' => IpProtocol.ipv4,
    'ipv6' => IpProtocol.ipv6,
    _ => null,
  };
}
