## 1.0.0

First release.

A dependency-light RPC client for the Transmission BitTorrent daemon, built around a
single `Transmission` class.

- **Dual-dialect protocol support.** Works against Transmission 2.x, 3.x, 4.0 and 4.1+
  through the same API. The client assumes the legacy protocol and upgrades itself when a
  daemon reveals RPC version 18 or above — via the `X-Transmission-Rpc-Version` header on
  the 409 CSRF handshake, or via the `rpc_version` / `rpc_version_semver` fields of a
  `session-get` response. Requests are then sent as JSON-RPC 2.0 with `snake_case` field
  names; responses are parsed in either dialect, since every read tries both spellings.
  `rpcVersion` and `rpcVersionSemver` expose what was detected.
- **No code generation.** Plain Dart models with hand-written parsing — no
  `build_runner`, no `freezed`, no `json_serializable`, no generated sources.
- **Dependency-light.** `dio`, `talker` and `talker_dio_logger` only.
- **Torrent methods.** `torrents`, `activeTorrents`, `addTorrent` (answering with an
  `AddTorrentResult` that carries the new — or already present — torrent and an
  `isDuplicate` flag), `removeTorrents`,
  `moveTorrents`, `renameTorrent`, `startTorrents`, `startTorrentsNow`, `stopTorrents`,
  `verifyTorrents`, `reannounceTorrents`, `moveQueueOnTop`, `moveQueueUp`,
  `moveQueueDown`, `moveQueueOnBottom` and `setTorrents`.
- **Session methods.** `session`, `setSession`, `sessionStats`, `freeSpace`, `blocklist`,
  `testPort`, `closeSession`, and the Transmission 4.0+ bandwidth groups via `groups` and
  `setGroup`.
- **Typed models.** `Torrent` (with `TorrentFile`, `FileStats`, `Peer`, `PeersFrom`,
  `Webseed`, `Tracker`, `TrackerStats`), `AddTorrentResult`, `Session` (with `Units`),
  `SessionStats` (with `Stats`), `FreeSpace`, `TestPort` and `Group`, plus the
  `TorrentStatus`, `SessionEncryption` and `IpProtocol` enums. The per-file class is
  called `TorrentFile` so it does not collide with `dart:io`'s `File`.
- **Selective field fetching.** `TorrentField` covers the whole `torrent-get` field set;
  `TorrentField.defaults` is the 20-field list used when none is given.
- **Transmission 4.1 and 4.2 fields.** `sequentialDownload` and
  `sequentialDownloadFromPiece` (on `torrent-get`, `torrent-add` and `torrent-set`),
  the `webseedsEx` webseed list with its per-webseed live state (`url`, `isDownloading`,
  `downloadBytesPerSecond`), `Peer.peerId`, `Peer.supportsHolepunch`,
  `Peer.bytesToClient`/`bytesToPeer`, `PeersFrom.fromHolepunch`,
  `TrackerStats.downloaderCount`, and session `preferredTransports` alongside the
  deprecated `tcpEnabled`/`utpEnabled` flags. Fields introduced with RPC 18 have no
  legacy spelling and are sent under the same name to every daemon; older daemons that do
  not know them simply leave them null.
- **Typed errors.** A sealed `TransmissionException` with `AuthenticationError`,
  `RpcError` (carrying the JSON-RPC `code` when there is one) and `NetworkError`.
- **Transparent CSRF handling.** The `X-Transmission-Session-Id` handshake is performed
  and the request replayed automatically, queued so concurrent calls do not stampede.
- **Optional logging.** Off unless a `logLevel` is passed; an existing `Talker` can be
  supplied.
- **Injectable HTTP client.** Pass your own `Dio` for proxies, custom certificates or test
  adapters.
