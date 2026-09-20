# transmission_rpc

A dependency-light Dart RPC client for the [Transmission](https://transmissionbt.com)
BitTorrent daemon, working with both the legacy protocol and the JSON-RPC 2.0 one of
Transmission 4.1+.

📖 **[Full documentation](https://docs.page/AngeloAvv/transmission_rpc)**

## Install

```sh
dart pub add transmission_rpc
```

or, by hand:

```yaml
dependencies:
  transmission_rpc: ^1.0.0
```

## Quickstart

```dart
import 'package:transmission_rpc/transmission_rpc.dart';

Future<void> main() async {
  final transmission = Transmission(
    baseUrl: 'http://localhost:9091/transmission/rpc',
    // username: 'transmission',
    // password: 'hunter2',
  );

  final session = await transmission.session();
  print('Transmission ${session.version} (RPC ${transmission.rpcVersion})');

  for (final torrent in await transmission.torrents()) {
    final percent = ((torrent.percentDone ?? 0) * 100).toStringAsFixed(1);
    print('[${torrent.id}] ${torrent.name} — $percent% — ${torrent.status}');
  }

  final added = await transmission.addTorrent(
    filename: 'magnet:?xt=urn:btih:dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c',
  );
  print(added.isDuplicate
      ? 'Already there as #${added.torrent.id}'
      : 'Added as #${added.torrent.id}');

  await transmission.stopTorrents([12]);
}
```

A fuller command-line tour lives in
[`example/transmission_rpc_example.dart`](example/transmission_rpc_example.dart).

## Features

- **One API for every daemon** — Transmission 2.x, 3.x, 4.0 and 4.1+ behind the same
  methods, with the protocol differences handled for you.
- **No code generation** — plain Dart classes, nothing to run `build_runner` for.
- **Dependency-light** — only `dio`, `talker` and `talker_dio_logger`.
- **Typed models** — `Torrent` (with `TorrentFile`, `FileStats`, `Peer`, `PeersFrom`,
  `Webseed`, `Tracker`, `TrackerStats`), `Session`, `SessionStats`, `FreeSpace`,
  `TestPort`, `Group`, plus enums for torrent status, encryption policy and IP protocol.
- **Up to date with 4.1 and 4.2** — sequential download from a given piece, the
  `webseeds_ex` webseed list, peer ids, holepunch support and tracker downloader counts.
- **Typed errors** — a sealed `TransmissionException` hierarchy (`AuthenticationError`,
  `RpcError`, `NetworkError`) you can `switch` over exhaustively.
- **Selective fields** — ask for exactly the `TorrentField`s your screen needs.
- **Transparent CSRF** — the `X-Transmission-Session-Id` handshake is handled and
  replayed automatically.
- **Quiet by default** — logging is off until you pass a `logLevel`.
- **Bring your own Dio** — pass `httpClient` for proxies, custom certificates or test
  adapters.

Covered RPC methods: `torrent-get` (all fields), `torrent-add`, `torrent-remove`,
`torrent-set`, `torrent-set-location`, `torrent-rename-path`, `torrent-start`,
`torrent-start-now`, `torrent-stop`, `torrent-verify`, `torrent-reannounce`, the four
`queue-move-*` calls, `session-get`, `session-set`, `session-stats`, `session-close`,
`blocklist-update`, `port-test`, `free-space`, `group-get` and `group-set`.

## Compatibility

Transmission 4.1 raised its RPC version to 18, moved the protocol to JSON-RPC 2.0 and
renamed every field to `snake_case` (`percentDone` → `percent_done`, `alt-speed-down` →
`alt_speed_down`, and so on). This library hides that split entirely. It assumes the
legacy protocol — safe, since every Transmission build still understands it — and upgrades
itself as soon as the daemon reveals a newer version, either through the
`X-Transmission-Rpc-Version` header on the 409 CSRF handshake or through the `rpc_version`
fields of a `session-get` response. Requests then go out in the right envelope with the
right field spellings, while responses are parsed in either dialect, because every read
tries both names. `transmission.rpcVersion` and `transmission.rpcVersionSemver` report
what was detected. See the
[compatibility guide](https://docs.page/AngeloAvv/transmission_rpc/compatibility)
and the
[Transmission RPC spec](https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md).

## Documentation

- [Introduction](https://docs.page/AngeloAvv/transmission_rpc)
- [Getting started](https://docs.page/AngeloAvv/transmission_rpc/getting-started)
- [Torrents](https://docs.page/AngeloAvv/transmission_rpc/torrents)
- [Session](https://docs.page/AngeloAvv/transmission_rpc/session)
- [Errors](https://docs.page/AngeloAvv/transmission_rpc/errors)
- [Compatibility](https://docs.page/AngeloAvv/transmission_rpc/compatibility)

## Contributing

Issues and pull requests are welcome at
[github.com/AngeloAvv/transmission_rpc](https://github.com/AngeloAvv/transmission_rpc).

## License

MIT — see [LICENSE](LICENSE).
