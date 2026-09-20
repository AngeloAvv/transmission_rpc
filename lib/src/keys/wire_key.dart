/// The name of a single RPC field, in both protocol dialects.
///
/// Transmission 4.1 (RPC version 18) renamed every field: `percentDone`
/// became `percent_done`, `alt-speed-down` became `alt_speed_down`, and a few
/// fields changed meaning rather than just spelling. Every field the library
/// touches is declared once, here, with both spellings.
///
/// [legacy] is the name used by RPC version < 18 (Transmission < 4.1).
/// [modern] is the name used by RPC version >= 18.
class WireKey {
  /// Field name on servers speaking RPC version < 18.
  final String legacy;

  /// Field name on servers speaking RPC version >= 18.
  final String modern;

  const WireKey(this.legacy, this.modern);

  /// A field spelled the same way in both dialects (`id`, `name`, `eta`, ...).
  const WireKey.same(String name) : legacy = name, modern = name;

  /// The name to put on the wire when talking to a server speaking
  /// [rpcVersion].
  String forVersion(int rpcVersion) => rpcVersion >= 18 ? modern : legacy;

  @override
  String toString() => legacy == modern ? legacy : '$legacy|$modern';
}
