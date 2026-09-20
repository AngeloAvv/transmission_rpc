import 'package:transmission_rpc/src/json.dart';
import 'package:transmission_rpc/src/keys/torrent_keys.dart';

/// Reads the `wanted` array, whose elements are `1`/`0` on older daemons and
/// `true`/`false` on newer ones.
List<bool>? _wantedOf(Json json) {
  final value = json.raw(TorrentKeys.wanted);
  if (value is! List) return null;
  return value
      .map((element) => element == true || element == 1)
      .toList(growable: false);
}

/// A single torrent as reported by `torrent-get`.
///
/// Every field is nullable: a torrent only carries the fields that were
/// requested, and older daemons omit fields they do not know about.
class Torrent {
  final int? activityDate;
  final int? addedDate;
  final List<int>? availability;
  final int? bandwidthPriority;
  final String? comment;
  final int? corruptEver;
  final String? creator;
  final int? dateCreated;
  final int? desiredAvailable;
  final int? doneDate;
  final String? downloadDir;
  final int? downloadedEver;
  final int? downloadLimit;
  final bool? downloadLimited;
  final int? editDate;
  final int? error;
  final String? errorString;
  final int? eta;
  final int? etaIdle;
  final int? fileCount;
  final List<TorrentFile>? files;
  final List<FileStats>? fileStats;
  final String? group;
  final String? hashString;
  final int? haveUnchecked;
  final int? haveValid;
  final bool? honorsSessionLimits;
  final int? id;
  final bool? isFinished;
  final bool? isPrivate;
  final bool? isStalled;
  final List<String>? labels;
  final int? leftUntilDone;
  final String? magnetLink;
  final int? manualAnnounceTime;
  final int? maxConnectedPeers;
  final double? metadataPercentComplete;
  final String? name;
  final int? peerLimit;
  final List<Peer>? peers;
  final int? peersConnected;
  final PeersFrom? peersFrom;
  final int? peersGettingFromUs;
  final int? peersSendingToUs;
  final double? percentComplete;
  final double? percentDone;
  final String? pieces;
  final int? pieceCount;
  final int? pieceSize;
  final List<int>? priorities;
  final String? primaryMimeType;
  final int? queuePosition;
  final int? rateDownload;
  final int? rateUpload;
  final double? recheckProgress;
  final int? secondsDownloading;
  final int? secondsSeeding;
  final int? seedIdleLimit;
  final int? seedIdleMode;
  final double? seedRatioLimit;
  final int? seedRatioMode;
  final bool? sequentialDownload;
  final int? sequentialDownloadFromPiece;
  final int? sizeWhenDone;
  final int? startDate;
  final TorrentStatus? status;
  final List<Tracker>? trackers;
  final String? trackerList;
  final List<TrackerStats>? trackerStats;
  final int? totalSize;
  final String? torrentFile;
  final int? uploadedEver;
  final int? uploadLimit;
  final bool? uploadLimited;
  final double? uploadRatio;
  final List<bool>? wanted;

  /// Deprecated since Transmission 4.2 in favour of [webseedsEx]; still the
  /// only webseed list older daemons report.
  final List<String>? webseeds;
  final List<Webseed>? webseedsEx;
  final int? webseedsSendingToUs;

  const Torrent({
    this.activityDate,
    this.addedDate,
    this.availability,
    this.bandwidthPriority,
    this.comment,
    this.corruptEver,
    this.creator,
    this.dateCreated,
    this.desiredAvailable,
    this.doneDate,
    this.downloadDir,
    this.downloadedEver,
    this.downloadLimit,
    this.downloadLimited,
    this.editDate,
    this.error,
    this.errorString,
    this.eta,
    this.etaIdle,
    this.fileCount,
    this.files,
    this.fileStats,
    this.group,
    this.hashString,
    this.haveUnchecked,
    this.haveValid,
    this.honorsSessionLimits,
    this.id,
    this.isFinished,
    this.isPrivate,
    this.isStalled,
    this.labels,
    this.leftUntilDone,
    this.magnetLink,
    this.manualAnnounceTime,
    this.maxConnectedPeers,
    this.metadataPercentComplete,
    this.name,
    this.peerLimit,
    this.peers,
    this.peersConnected,
    this.peersFrom,
    this.peersGettingFromUs,
    this.peersSendingToUs,
    this.percentComplete,
    this.percentDone,
    this.pieces,
    this.pieceCount,
    this.pieceSize,
    this.priorities,
    this.primaryMimeType,
    this.queuePosition,
    this.rateDownload,
    this.rateUpload,
    this.recheckProgress,
    this.secondsDownloading,
    this.secondsSeeding,
    this.seedIdleLimit,
    this.seedIdleMode,
    this.seedRatioLimit,
    this.seedRatioMode,
    this.sequentialDownload,
    this.sequentialDownloadFromPiece,
    this.sizeWhenDone,
    this.startDate,
    this.status,
    this.trackers,
    this.trackerList,
    this.trackerStats,
    this.totalSize,
    this.torrentFile,
    this.uploadedEver,
    this.uploadLimit,
    this.uploadLimited,
    this.uploadRatio,
    this.wanted,
    this.webseeds,
    this.webseedsEx,
    this.webseedsSendingToUs,
  });

  factory Torrent.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Torrent(
      activityDate: reader.intOf(TorrentKeys.activityDate),
      addedDate: reader.intOf(TorrentKeys.addedDate),
      availability: reader.numListOf(
        TorrentKeys.availability,
        (n) => n.toInt(),
      ),
      bandwidthPriority: reader.intOf(TorrentKeys.bandwidthPriority),
      comment: reader.stringOf(TorrentKeys.comment),
      corruptEver: reader.intOf(TorrentKeys.corruptEver),
      creator: reader.stringOf(TorrentKeys.creator),
      dateCreated: reader.intOf(TorrentKeys.dateCreated),
      desiredAvailable: reader.intOf(TorrentKeys.desiredAvailable),
      doneDate: reader.intOf(TorrentKeys.doneDate),
      downloadDir: reader.stringOf(TorrentKeys.downloadDir),
      downloadedEver: reader.intOf(TorrentKeys.downloadedEver),
      downloadLimit: reader.intOf(TorrentKeys.downloadLimit),
      downloadLimited: reader.boolOf(TorrentKeys.downloadLimited),
      editDate: reader.intOf(TorrentKeys.editDate),
      error: reader.intOf(TorrentKeys.error),
      errorString: reader.stringOf(TorrentKeys.errorString),
      eta: reader.intOf(TorrentKeys.eta),
      etaIdle: reader.intOf(TorrentKeys.etaIdle),
      fileCount: reader.intOf(TorrentKeys.fileCount),
      files: reader.objectListOf(TorrentKeys.files, TorrentFile.fromJson),
      fileStats: reader.objectListOf(
        TorrentKeys.fileStats,
        FileStats.fromJson,
      ),
      group: reader.stringOf(TorrentKeys.group),
      hashString: reader.stringOf(TorrentKeys.hashString),
      haveUnchecked: reader.intOf(TorrentKeys.haveUnchecked),
      haveValid: reader.intOf(TorrentKeys.haveValid),
      honorsSessionLimits: reader.boolOf(TorrentKeys.honorsSessionLimits),
      id: reader.intOf(TorrentKeys.id),
      isFinished: reader.boolOf(TorrentKeys.isFinished),
      isPrivate: reader.boolOf(TorrentKeys.isPrivate),
      isStalled: reader.boolOf(TorrentKeys.isStalled),
      labels: reader.listOf<String>(TorrentKeys.labels),
      leftUntilDone: reader.intOf(TorrentKeys.leftUntilDone),
      magnetLink: reader.stringOf(TorrentKeys.magnetLink),
      manualAnnounceTime: reader.intOf(TorrentKeys.manualAnnounceTime),
      maxConnectedPeers: reader.intOf(TorrentKeys.maxConnectedPeers),
      metadataPercentComplete: reader.doubleOf(
        TorrentKeys.metadataPercentComplete,
      ),
      name: reader.stringOf(TorrentKeys.name),
      peerLimit: reader.intOf(TorrentKeys.peerLimit),
      peers: reader.objectListOf(TorrentKeys.peers, Peer.fromJson),
      peersConnected: reader.intOf(TorrentKeys.peersConnected),
      peersFrom: reader.objectOf(TorrentKeys.peersFrom, PeersFrom.fromJson),
      peersGettingFromUs: reader.intOf(TorrentKeys.peersGettingFromUs),
      peersSendingToUs: reader.intOf(TorrentKeys.peersSendingToUs),
      percentComplete: reader.doubleOf(TorrentKeys.percentComplete),
      percentDone: reader.doubleOf(TorrentKeys.percentDone),
      pieces: reader.stringOf(TorrentKeys.pieces),
      pieceCount: reader.intOf(TorrentKeys.pieceCount),
      pieceSize: reader.intOf(TorrentKeys.pieceSize),
      priorities: reader.numListOf(TorrentKeys.priorities, (n) => n.toInt()),
      primaryMimeType: reader.stringOf(TorrentKeys.primaryMimeType),
      queuePosition: reader.intOf(TorrentKeys.queuePosition),
      rateDownload: reader.intOf(TorrentKeys.rateDownload),
      rateUpload: reader.intOf(TorrentKeys.rateUpload),
      recheckProgress: reader.doubleOf(TorrentKeys.recheckProgress),
      secondsDownloading: reader.intOf(TorrentKeys.secondsDownloading),
      secondsSeeding: reader.intOf(TorrentKeys.secondsSeeding),
      seedIdleLimit: reader.intOf(TorrentKeys.seedIdleLimit),
      seedIdleMode: reader.intOf(TorrentKeys.seedIdleMode),
      seedRatioLimit: reader.doubleOf(TorrentKeys.seedRatioLimit),
      seedRatioMode: reader.intOf(TorrentKeys.seedRatioMode),
      sequentialDownload: reader.boolOf(TorrentKeys.sequentialDownload),
      sequentialDownloadFromPiece: reader.intOf(
        TorrentKeys.sequentialDownloadFromPiece,
      ),
      sizeWhenDone: reader.intOf(TorrentKeys.sizeWhenDone),
      startDate: reader.intOf(TorrentKeys.startDate),
      status: TorrentStatus.fromCode(reader.intOf(TorrentKeys.status)),
      trackers: reader.objectListOf(TorrentKeys.trackers, Tracker.fromJson),
      trackerList: reader.stringOf(TorrentKeys.trackerList),
      trackerStats: reader.objectListOf(
        TorrentKeys.trackerStats,
        TrackerStats.fromJson,
      ),
      totalSize: reader.intOf(TorrentKeys.totalSize),
      torrentFile: reader.stringOf(TorrentKeys.torrentFile),
      uploadedEver: reader.intOf(TorrentKeys.uploadedEver),
      uploadLimit: reader.intOf(TorrentKeys.uploadLimit),
      uploadLimited: reader.boolOf(TorrentKeys.uploadLimited),
      uploadRatio: reader.doubleOf(TorrentKeys.uploadRatio),
      wanted: _wantedOf(reader),
      webseeds: reader.listOf<String>(TorrentKeys.webseeds),
      webseedsEx: reader.objectListOf(
        TorrentKeys.webseedsEx,
        Webseed.fromJson,
      ),
      webseedsSendingToUs: reader.intOf(TorrentKeys.webseedsSendingToUs),
    );
  }
}

/// One file inside a torrent, as returned in the `files` array.
class TorrentFile {
  final int? bytesCompleted;
  final int? length;
  final String? name;
  final int? beginPiece;
  final int? endPiece;

  const TorrentFile({
    this.bytesCompleted,
    this.length,
    this.name,
    this.beginPiece,
    this.endPiece,
  });

  factory TorrentFile.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return TorrentFile(
      bytesCompleted: reader.intOf(TorrentKeys.bytesCompleted),
      length: reader.intOf(TorrentKeys.length),
      name: reader.stringOf(TorrentKeys.name),
      beginPiece: reader.intOf(TorrentKeys.beginPiece),
      endPiece: reader.intOf(TorrentKeys.endPiece),
    );
  }
}

/// Per-file transfer state, as returned in the `fileStats` array. Entries line
/// up positionally with the `files` array.
class FileStats {
  final int? bytesCompleted;
  final bool? wanted;
  final int? priority;

  const FileStats({this.bytesCompleted, this.wanted, this.priority});

  factory FileStats.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return FileStats(
      bytesCompleted: reader.intOf(TorrentKeys.bytesCompleted),
      wanted: reader.boolOf(TorrentKeys.wanted),
      priority: reader.intOf(TorrentKeys.priority),
    );
  }
}

/// A peer currently connected for a torrent.
class Peer {
  final String? address;
  final int? bytesToClient;
  final int? bytesToPeer;
  final String? clientName;
  final bool? clientIsChoked;
  final bool? clientIsInterested;
  final String? flagStr;
  final bool? isDownloadingFrom;
  final bool? isEncrypted;
  final bool? isIncoming;
  final bool? isUploadingTo;
  final bool? isUTP;
  final String? peerId;
  final bool? peerIsChoked;
  final bool? peerIsInterested;
  final int? port;
  final double? progress;
  final int? rateToClient;
  final int? rateToPeer;
  final bool? supportsHolepunch;

  const Peer({
    this.address,
    this.bytesToClient,
    this.bytesToPeer,
    this.clientName,
    this.clientIsChoked,
    this.clientIsInterested,
    this.flagStr,
    this.isDownloadingFrom,
    this.isEncrypted,
    this.isIncoming,
    this.isUploadingTo,
    this.isUTP,
    this.peerId,
    this.peerIsChoked,
    this.peerIsInterested,
    this.port,
    this.progress,
    this.rateToClient,
    this.rateToPeer,
    this.supportsHolepunch,
  });

  factory Peer.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Peer(
      address: reader.stringOf(TorrentKeys.address),
      bytesToClient: reader.intOf(TorrentKeys.bytesToClient),
      bytesToPeer: reader.intOf(TorrentKeys.bytesToPeer),
      clientName: reader.stringOf(TorrentKeys.clientName),
      clientIsChoked: reader.boolOf(TorrentKeys.clientIsChoked),
      clientIsInterested: reader.boolOf(TorrentKeys.clientIsInterested),
      flagStr: reader.stringOf(TorrentKeys.flagStr),
      isDownloadingFrom: reader.boolOf(TorrentKeys.isDownloadingFrom),
      isEncrypted: reader.boolOf(TorrentKeys.isEncrypted),
      isIncoming: reader.boolOf(TorrentKeys.isIncoming),
      isUploadingTo: reader.boolOf(TorrentKeys.isUploadingTo),
      isUTP: reader.boolOf(TorrentKeys.isUtp),
      peerId: reader.stringOf(TorrentKeys.peerId),
      peerIsChoked: reader.boolOf(TorrentKeys.peerIsChoked),
      peerIsInterested: reader.boolOf(TorrentKeys.peerIsInterested),
      port: reader.intOf(TorrentKeys.port),
      progress: reader.doubleOf(TorrentKeys.progress),
      rateToClient: reader.intOf(TorrentKeys.rateToClient),
      rateToPeer: reader.intOf(TorrentKeys.rateToPeer),
      supportsHolepunch: reader.boolOf(TorrentKeys.supportsHolepunch),
    );
  }
}

/// How many peers were discovered through each source.
class PeersFrom {
  final int? fromCache;
  final int? fromDht;
  final int? fromHolepunch;
  final int? fromIncoming;
  final int? fromLpd;
  final int? fromLtep;
  final int? fromPex;
  final int? fromTracker;

  const PeersFrom({
    this.fromCache,
    this.fromDht,
    this.fromHolepunch,
    this.fromIncoming,
    this.fromLpd,
    this.fromLtep,
    this.fromPex,
    this.fromTracker,
  });

  factory PeersFrom.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return PeersFrom(
      fromCache: reader.intOf(TorrentKeys.fromCache),
      fromDht: reader.intOf(TorrentKeys.fromDht),
      fromHolepunch: reader.intOf(TorrentKeys.fromHolepunch),
      fromIncoming: reader.intOf(TorrentKeys.fromIncoming),
      fromLpd: reader.intOf(TorrentKeys.fromLpd),
      fromLtep: reader.intOf(TorrentKeys.fromLtep),
      fromPex: reader.intOf(TorrentKeys.fromPex),
      fromTracker: reader.intOf(TorrentKeys.fromTracker),
    );
  }
}

/// One entry of the `webseeds_ex` array: a webseed URL and its live state.
///
/// Reported from Transmission 4.2 (RPC 18+) on; older daemons only send the
/// plain [Torrent.webseeds] URL list.
class Webseed {
  final String? url;
  final bool? isDownloading;
  final int? downloadBytesPerSecond;

  const Webseed({this.url, this.isDownloading, this.downloadBytesPerSecond});

  factory Webseed.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Webseed(
      url: reader.stringOf(TorrentKeys.url),
      isDownloading: reader.boolOf(TorrentKeys.isDownloading),
      downloadBytesPerSecond: reader.intOf(
        TorrentKeys.downloadBytesPerSecond,
      ),
    );
  }
}

/// What `torrent-add` did: the torrent that was created, or the one that was
/// already there.
class AddTorrentResult {
  /// The torrent the daemon now holds — only `id`, `name` and `hashString` are
  /// populated.
  final Torrent torrent;

  /// Whether the daemon already had this torrent and added nothing.
  final bool isDuplicate;

  const AddTorrentResult({required this.torrent, this.isDuplicate = false});
}

/// A tracker announce/scrape URL pair attached to a torrent.
class Tracker {
  final String? announce;
  final int? id;
  final String? scrape;
  final String? sitename;
  final int? tier;

  const Tracker({
    this.announce,
    this.id,
    this.scrape,
    this.sitename,
    this.tier,
  });

  factory Tracker.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return Tracker(
      announce: reader.stringOf(TorrentKeys.announce),
      id: reader.intOf(TorrentKeys.id),
      scrape: reader.stringOf(TorrentKeys.scrape),
      sitename: reader.stringOf(TorrentKeys.sitename),
      tier: reader.intOf(TorrentKeys.tier),
    );
  }
}

/// Live statistics for one tracker: the outcome of the last announce and
/// scrape, and when the next ones are due.
class TrackerStats {
  final int? announceState;
  final String? announce;
  final int? downloadCount;
  final int? downloaderCount;
  final bool? hasAnnounced;
  final bool? hasScraped;
  final String? host;
  final int? id;
  final bool? isBackup;
  final int? lastAnnouncePeerCount;
  final String? lastAnnounceResult;
  final int? lastAnnounceStartTime;
  final bool? lastAnnounceSucceeded;
  final int? lastAnnounceTime;
  final bool? lastAnnounceTimedOut;
  final String? lastScrapeResult;
  final int? lastScrapeStartTime;
  final bool? lastScrapeSucceeded;
  final int? lastScrapeTime;
  final bool? lastScrapeTimedOut;
  final int? leecherCount;
  final int? nextAnnounceTime;
  final int? nextScrapeTime;
  final int? scrapeState;
  final String? scrape;
  final int? seederCount;
  final String? sitename;
  final int? tier;

  const TrackerStats({
    this.announceState,
    this.announce,
    this.downloadCount,
    this.downloaderCount,
    this.hasAnnounced,
    this.hasScraped,
    this.host,
    this.id,
    this.isBackup,
    this.lastAnnouncePeerCount,
    this.lastAnnounceResult,
    this.lastAnnounceStartTime,
    this.lastAnnounceSucceeded,
    this.lastAnnounceTime,
    this.lastAnnounceTimedOut,
    this.lastScrapeResult,
    this.lastScrapeStartTime,
    this.lastScrapeSucceeded,
    this.lastScrapeTime,
    this.lastScrapeTimedOut,
    this.leecherCount,
    this.nextAnnounceTime,
    this.nextScrapeTime,
    this.scrapeState,
    this.scrape,
    this.seederCount,
    this.sitename,
    this.tier,
  });

  factory TrackerStats.fromJson(Map<String, dynamic> json) {
    final reader = Json(json);
    return TrackerStats(
      announceState: reader.intOf(TorrentKeys.announceState),
      announce: reader.stringOf(TorrentKeys.announce),
      downloadCount: reader.intOf(TorrentKeys.downloadCount),
      downloaderCount: reader.intOf(TorrentKeys.downloaderCount),
      hasAnnounced: reader.boolOf(TorrentKeys.hasAnnounced),
      hasScraped: reader.boolOf(TorrentKeys.hasScraped),
      host: reader.stringOf(TorrentKeys.host),
      id: reader.intOf(TorrentKeys.id),
      isBackup: reader.boolOf(TorrentKeys.isBackup),
      lastAnnouncePeerCount: reader.intOf(TorrentKeys.lastAnnouncePeerCount),
      lastAnnounceResult: reader.stringOf(TorrentKeys.lastAnnounceResult),
      lastAnnounceStartTime: reader.intOf(TorrentKeys.lastAnnounceStartTime),
      lastAnnounceSucceeded: reader.boolOf(TorrentKeys.lastAnnounceSucceeded),
      lastAnnounceTime: reader.intOf(TorrentKeys.lastAnnounceTime),
      lastAnnounceTimedOut: reader.boolOf(TorrentKeys.lastAnnounceTimedOut),
      lastScrapeResult: reader.stringOf(TorrentKeys.lastScrapeResult),
      lastScrapeStartTime: reader.intOf(TorrentKeys.lastScrapeStartTime),
      lastScrapeSucceeded: reader.boolOf(TorrentKeys.lastScrapeSucceeded),
      lastScrapeTime: reader.intOf(TorrentKeys.lastScrapeTime),
      lastScrapeTimedOut: reader.boolOf(TorrentKeys.lastScrapeTimedOut),
      leecherCount: reader.intOf(TorrentKeys.leecherCount),
      nextAnnounceTime: reader.intOf(TorrentKeys.nextAnnounceTime),
      nextScrapeTime: reader.intOf(TorrentKeys.nextScrapeTime),
      scrapeState: reader.intOf(TorrentKeys.scrapeState),
      scrape: reader.stringOf(TorrentKeys.scrape),
      seederCount: reader.intOf(TorrentKeys.seederCount),
      sitename: reader.stringOf(TorrentKeys.sitename),
      tier: reader.intOf(TorrentKeys.tier),
    );
  }
}

/// What a torrent is currently doing, as reported by the `status` field.
enum TorrentStatus {
  /// Not running.
  stopped,

  /// Queued to be verified against its piece hashes.
  checkWait,

  /// Verifying local data against its piece hashes.
  check,

  /// Queued to start downloading.
  downloadWait,

  /// Downloading.
  download,

  /// Queued to start seeding.
  seedWait,

  /// Seeding.
  seed;

  /// The integer the RPC protocol uses for this status.
  int get code => index;

  /// The status for the wire value [code], or null when [code] is null or
  /// outside the known 0..6 range — a status a future Transmission adds must
  /// not break parsing.
  static TorrentStatus? fromCode(int? code) =>
      code != null && code >= 0 && code < values.length ? values[code] : null;
}
