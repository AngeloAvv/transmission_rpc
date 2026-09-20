import 'package:transmission_rpc/src/keys/wire_key.dart';

/// Every torrent-related RPC field name, in both protocol dialects.
///
/// Covers the `torrent-get` response fields, the `torrent-set` /
/// `torrent-add` / `torrent-remove` / `torrent-set-location` /
/// `torrent-rename-path` arguments, and the fields of the nested objects a
/// torrent carries (file, peer, tracker, ...).
///
/// The legacy spelling is what Transmission < 4.1 (RPC < 18) puts on the wire:
/// camelCase for torrent fields, kebab-case for most arguments. The modern
/// spelling is the snake_case introduced by RPC version 18.
abstract final class TorrentKeys {
  // ---------------------------------------------------------------------------
  // torrent-get fields
  // ---------------------------------------------------------------------------

  static const activityDate = WireKey('activityDate', 'activity_date');
  static const addedDate = WireKey('addedDate', 'added_date');
  static const availability = WireKey.same('availability');
  static const bandwidthPriority = WireKey(
    'bandwidthPriority',
    'bandwidth_priority',
  );
  static const comment = WireKey.same('comment');
  static const corruptEver = WireKey('corruptEver', 'corrupt_ever');
  static const creator = WireKey.same('creator');
  static const dateCreated = WireKey('dateCreated', 'date_created');
  static const desiredAvailable = WireKey(
    'desiredAvailable',
    'desired_available',
  );
  static const doneDate = WireKey('doneDate', 'done_date');
  static const downloadDir = WireKey('downloadDir', 'download_dir');
  static const downloadedEver = WireKey('downloadedEver', 'downloaded_ever');
  static const downloadLimit = WireKey('downloadLimit', 'download_limit');
  static const downloadLimited = WireKey('downloadLimited', 'download_limited');
  static const editDate = WireKey('editDate', 'edit_date');
  static const error = WireKey.same('error');
  static const errorString = WireKey('errorString', 'error_string');
  static const eta = WireKey.same('eta');
  static const etaIdle = WireKey('etaIdle', 'eta_idle');
  static const fileCount = WireKey('file-count', 'file_count');
  static const files = WireKey.same('files');
  static const fileStats = WireKey('fileStats', 'file_stats');
  static const group = WireKey.same('group');
  static const hashString = WireKey('hashString', 'hash_string');
  static const haveUnchecked = WireKey('haveUnchecked', 'have_unchecked');
  static const haveValid = WireKey('haveValid', 'have_valid');
  static const honorsSessionLimits = WireKey(
    'honorsSessionLimits',
    'honors_session_limits',
  );
  static const id = WireKey.same('id');
  static const isFinished = WireKey('isFinished', 'is_finished');
  static const isPrivate = WireKey('isPrivate', 'is_private');
  static const isStalled = WireKey('isStalled', 'is_stalled');
  static const labels = WireKey.same('labels');
  static const leftUntilDone = WireKey('leftUntilDone', 'left_until_done');
  static const magnetLink = WireKey('magnetLink', 'magnet_link');
  static const manualAnnounceTime = WireKey(
    'manualAnnounceTime',
    'manual_announce_time',
  );
  static const maxConnectedPeers = WireKey(
    'maxConnectedPeers',
    'max_connected_peers',
  );
  static const metadataPercentComplete = WireKey(
    'metadataPercentComplete',
    'metadata_percent_complete',
  );
  static const name = WireKey.same('name');

  /// Maximum peers for one torrent. Kebab-case on legacy daemons in every
  /// context: `torrent-get`, `torrent-set` and `torrent-add` alike.
  static const peerLimit = WireKey('peer-limit', 'peer_limit');
  static const peers = WireKey.same('peers');
  static const peersConnected = WireKey('peersConnected', 'peers_connected');
  static const peersFrom = WireKey('peersFrom', 'peers_from');
  static const peersGettingFromUs = WireKey(
    'peersGettingFromUs',
    'peers_getting_from_us',
  );
  static const peersSendingToUs = WireKey(
    'peersSendingToUs',
    'peers_sending_to_us',
  );
  static const percentComplete = WireKey('percentComplete', 'percent_complete');
  static const percentDone = WireKey('percentDone', 'percent_done');
  static const pieces = WireKey.same('pieces');
  static const pieceCount = WireKey('pieceCount', 'piece_count');
  static const pieceSize = WireKey('pieceSize', 'piece_size');
  static const priorities = WireKey.same('priorities');
  static const primaryMimeType = WireKey(
    'primary-mime-type',
    'primary_mime_type',
  );
  static const queuePosition = WireKey('queuePosition', 'queue_position');
  static const rateDownload = WireKey('rateDownload', 'rate_download');
  static const rateUpload = WireKey('rateUpload', 'rate_upload');
  static const recheckProgress = WireKey('recheckProgress', 'recheck_progress');
  static const secondsDownloading = WireKey(
    'secondsDownloading',
    'seconds_downloading',
  );
  static const secondsSeeding = WireKey('secondsSeeding', 'seconds_seeding');
  static const seedIdleLimit = WireKey('seedIdleLimit', 'seed_idle_limit');
  static const seedIdleMode = WireKey('seedIdleMode', 'seed_idle_mode');
  static const seedRatioLimit = WireKey('seedRatioLimit', 'seed_ratio_limit');
  static const seedRatioMode = WireKey('seedRatioMode', 'seed_ratio_mode');

  /// Only exists from RPC 18 (Transmission 4.1) on, so there is no legacy
  /// spelling to fall back to.
  static const sequentialDownload = WireKey.same('sequential_download');

  /// Piece to start sequential downloading from. Introduced by RPC version 18
  /// (Transmission 4.1), so it has no legacy spelling.
  static const sequentialDownloadFromPiece = WireKey.same(
    'sequential_download_from_piece',
  );
  static const sizeWhenDone = WireKey('sizeWhenDone', 'size_when_done');
  static const startDate = WireKey('startDate', 'start_date');
  static const status = WireKey.same('status');
  static const totalSize = WireKey('totalSize', 'total_size');
  static const torrentFile = WireKey('torrentFile', 'torrent_file');

  /// Newline separated announce URLs. Since Transmission 4.0 this replaces the
  /// `trackerAdd`/`trackerRemove`/`trackerReplace` arguments.
  static const trackerList = WireKey('trackerList', 'tracker_list');
  static const trackers = WireKey.same('trackers');
  static const trackerStats = WireKey('trackerStats', 'tracker_stats');
  static const uploadedEver = WireKey('uploadedEver', 'uploaded_ever');
  static const uploadLimit = WireKey('uploadLimit', 'upload_limit');
  static const uploadLimited = WireKey('uploadLimited', 'upload_limited');
  static const uploadRatio = WireKey('uploadRatio', 'upload_ratio');
  static const wanted = WireKey.same('wanted');

  /// Deprecated since Transmission 4.2 in favour of [webseedsEx]; still the
  /// only webseed field older daemons report.
  static const webseeds = WireKey.same('webseeds');

  /// Per-webseed state. Introduced by Transmission 4.2 (RPC 18+), so it has no
  /// legacy spelling.
  static const webseedsEx = WireKey.same('webseeds_ex');
  static const webseedsSendingToUs = WireKey(
    'webseedsSendingToUs',
    'webseeds_sending_to_us',
  );

  // ---------------------------------------------------------------------------
  // torrent-get / torrent-set request arguments
  // ---------------------------------------------------------------------------

  /// The list of field names a `torrent-get` call asks for.
  static const fields = WireKey.same('fields');

  /// Torrent selector: a list of ids, a hash string, or `recently-active`.
  static const ids = WireKey.same('ids');

  static const filesWanted = WireKey('files-wanted', 'files_wanted');
  static const filesUnwanted = WireKey('files-unwanted', 'files_unwanted');
  static const priorityHigh = WireKey('priority-high', 'priority_high');
  static const priorityLow = WireKey('priority-low', 'priority_low');
  static const priorityNormal = WireKey('priority-normal', 'priority_normal');

  /// Deprecated since Transmission 4.0 in favour of [trackerList].
  static const trackerAdd = WireKey('trackerAdd', 'tracker_add');

  /// Deprecated since Transmission 4.0 in favour of [trackerList].
  static const trackerRemove = WireKey('trackerRemove', 'tracker_remove');

  /// Deprecated since Transmission 4.0 in favour of [trackerList].
  static const trackerReplace = WireKey('trackerReplace', 'tracker_replace');

  // ---------------------------------------------------------------------------
  // torrent-add arguments
  // ---------------------------------------------------------------------------

  /// Filename, URL, or magnet link of the torrent to add.
  static const filename = WireKey.same('filename');

  /// Destination directory, as spelled in a `torrent-add` request.
  ///
  /// Not the same spelling as the `torrent-get` field [downloadDir]: legacy
  /// daemons take `download-dir` as an argument but report `downloadDir` back.
  static const addDownloadDir = WireKey('download-dir', 'download_dir');

  /// Base64 encoded contents of a `.torrent` file.
  static const metainfo = WireKey.same('metainfo');
  static const cookies = WireKey.same('cookies');

  /// Add the torrent without starting it.
  static const paused = WireKey.same('paused');

  // ---------------------------------------------------------------------------
  // torrent-add response
  // ---------------------------------------------------------------------------

  /// The torrent `torrent-add` created, carrying only `id`, `name` and
  /// `hashString`.
  static const torrentAdded = WireKey('torrent-added', 'torrent_added');

  /// Returned instead of [torrentAdded] when the daemon already held the
  /// torrent.
  static const torrentDuplicate = WireKey(
    'torrent-duplicate',
    'torrent_duplicate',
  );

  // ---------------------------------------------------------------------------
  // torrent-remove / torrent-set-location / torrent-rename-path arguments
  // ---------------------------------------------------------------------------

  static const deleteLocalData = WireKey(
    'delete-local-data',
    'delete_local_data',
  );

  /// Destination directory for `torrent-set-location`.
  static const location = WireKey.same('location');

  /// Whether `torrent-set-location` moves existing data to the new location.
  static const move = WireKey.same('move');

  /// Current path of the file or directory being renamed.
  static const path = WireKey.same('path');

  // ---------------------------------------------------------------------------
  // nested: file
  // ---------------------------------------------------------------------------

  static const bytesCompleted = WireKey('bytesCompleted', 'bytes_completed');
  static const length = WireKey.same('length');
  static const beginPiece = WireKey('beginPiece', 'begin_piece');
  static const endPiece = WireKey('endPiece', 'end_piece');

  // ---------------------------------------------------------------------------
  // nested: file stats
  // ---------------------------------------------------------------------------

  static const priority = WireKey.same('priority');

  // ---------------------------------------------------------------------------
  // nested: peer
  // ---------------------------------------------------------------------------

  static const address = WireKey.same('address');

  /// Bytes received from this peer. Introduced by RPC version 18
  /// (Transmission 4.1), so it has no legacy spelling.
  static const bytesToClient = WireKey.same('bytes_to_client');

  /// Bytes sent to this peer. Introduced by RPC version 18 (Transmission 4.1),
  /// so it has no legacy spelling.
  static const bytesToPeer = WireKey.same('bytes_to_peer');
  static const clientName = WireKey('clientName', 'client_name');
  static const clientIsChoked = WireKey('clientIsChoked', 'client_is_choked');
  static const clientIsInterested = WireKey(
    'clientIsInterested',
    'client_is_interested',
  );
  static const flagStr = WireKey('flagStr', 'flag_str');
  static const isDownloadingFrom = WireKey(
    'isDownloadingFrom',
    'is_downloading_from',
  );
  static const isEncrypted = WireKey('isEncrypted', 'is_encrypted');
  static const isIncoming = WireKey('isIncoming', 'is_incoming');
  static const isUploadingTo = WireKey('isUploadingTo', 'is_uploading_to');
  static const isUtp = WireKey('isUTP', 'is_utp');

  /// The peer's BitTorrent peer id. Introduced by RPC version 18
  /// (Transmission 4.1), so it has no legacy spelling.
  static const peerId = WireKey.same('peer_id');
  static const peerIsChoked = WireKey('peerIsChoked', 'peer_is_choked');
  static const peerIsInterested = WireKey(
    'peerIsInterested',
    'peer_is_interested',
  );
  static const port = WireKey.same('port');
  static const progress = WireKey.same('progress');
  static const rateToClient = WireKey('rateToClient', 'rate_to_client');
  static const rateToPeer = WireKey('rateToPeer', 'rate_to_peer');

  /// Whether the peer supports uTP holepunching. Introduced by Transmission
  /// 4.2 (RPC 18+), so it has no legacy spelling.
  static const supportsHolepunch = WireKey.same('supports_holepunch');

  // ---------------------------------------------------------------------------
  // nested: peers from
  // ---------------------------------------------------------------------------

  static const fromCache = WireKey('fromCache', 'from_cache');
  static const fromDht = WireKey('fromDht', 'from_dht');

  /// Peers found through uTP holepunching. Introduced by Transmission 4.2
  /// (RPC 18+), so it has no legacy spelling.
  static const fromHolepunch = WireKey.same('from_holepunch');
  static const fromIncoming = WireKey('fromIncoming', 'from_incoming');
  static const fromLpd = WireKey('fromLpd', 'from_lpd');
  static const fromLtep = WireKey('fromLtep', 'from_ltep');
  static const fromPex = WireKey('fromPex', 'from_pex');
  static const fromTracker = WireKey('fromTracker', 'from_tracker');

  // ---------------------------------------------------------------------------
  // nested: webseed (webseeds_ex)
  // ---------------------------------------------------------------------------

  /// Current download rate from a webseed, in bytes per second. Introduced by
  /// Transmission 4.2 (RPC 18+), so it has no legacy spelling.
  static const downloadBytesPerSecond = WireKey.same(
    'download_bytes_per_second',
  );

  /// Whether a webseed is currently being downloaded from. Introduced by
  /// Transmission 4.2 (RPC 18+), so it has no legacy spelling.
  static const isDownloading = WireKey.same('is_downloading');

  /// A webseed's URL. Introduced by Transmission 4.2 (RPC 18+), so it has no
  /// legacy spelling.
  static const url = WireKey.same('url');

  // ---------------------------------------------------------------------------
  // nested: tracker
  // ---------------------------------------------------------------------------

  static const announce = WireKey.same('announce');
  static const scrape = WireKey.same('scrape');
  static const sitename = WireKey.same('sitename');
  static const tier = WireKey.same('tier');

  // ---------------------------------------------------------------------------
  // nested: tracker stats
  // ---------------------------------------------------------------------------

  static const announceState = WireKey('announceState', 'announce_state');
  static const downloadCount = WireKey('downloadCount', 'download_count');

  /// Number of peers downloading from this tracker. Introduced by RPC version
  /// 18 (Transmission 4.1), so it has no legacy spelling.
  static const downloaderCount = WireKey.same('downloader_count');
  static const hasAnnounced = WireKey('hasAnnounced', 'has_announced');
  static const hasScraped = WireKey('hasScraped', 'has_scraped');
  static const host = WireKey.same('host');
  static const isBackup = WireKey('isBackup', 'is_backup');
  static const lastAnnouncePeerCount = WireKey(
    'lastAnnouncePeerCount',
    'last_announce_peer_count',
  );
  static const lastAnnounceResult = WireKey(
    'lastAnnounceResult',
    'last_announce_result',
  );
  static const lastAnnounceStartTime = WireKey(
    'lastAnnounceStartTime',
    'last_announce_start_time',
  );
  static const lastAnnounceSucceeded = WireKey(
    'lastAnnounceSucceeded',
    'last_announce_succeeded',
  );
  static const lastAnnounceTime = WireKey(
    'lastAnnounceTime',
    'last_announce_time',
  );
  static const lastAnnounceTimedOut = WireKey(
    'lastAnnounceTimedOut',
    'last_announce_timed_out',
  );
  static const lastScrapeResult = WireKey(
    'lastScrapeResult',
    'last_scrape_result',
  );
  static const lastScrapeStartTime = WireKey(
    'lastScrapeStartTime',
    'last_scrape_start_time',
  );
  static const lastScrapeSucceeded = WireKey(
    'lastScrapeSucceeded',
    'last_scrape_succeeded',
  );
  static const lastScrapeTime = WireKey('lastScrapeTime', 'last_scrape_time');
  static const lastScrapeTimedOut = WireKey(
    'lastScrapeTimedOut',
    'last_scrape_timed_out',
  );
  static const leecherCount = WireKey('leecherCount', 'leecher_count');
  static const nextAnnounceTime = WireKey(
    'nextAnnounceTime',
    'next_announce_time',
  );
  static const nextScrapeTime = WireKey('nextScrapeTime', 'next_scrape_time');
  static const scrapeState = WireKey('scrapeState', 'scrape_state');
  static const seederCount = WireKey('seederCount', 'seeder_count');
}
