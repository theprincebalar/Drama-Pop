class EpisodeModel {
  final int episodeNumber;
  final String title;
  final String duration;
  final String? thumbnail;
  final String? stream540p;
  final String? stream720p;
  final String? stream1080p;
  final String? masterStream;
  final String? seriesId;
  final bool isLocked;
  final int coinPrice;

  EpisodeModel({
    required this.episodeNumber,
    required this.title,
    this.duration = '1:30',
    this.thumbnail,
    this.stream540p,
    this.stream720p,
    this.stream1080p,
    this.masterStream,
    this.seriesId,
    this.isLocked = false,
    this.coinPrice = 10,
  });

  EpisodeModel copyWith({
    int? episodeNumber,
    String? title,
    String? duration,
    String? thumbnail,
    String? stream540p,
    String? stream720p,
    String? stream1080p,
    String? masterStream,
    String? seriesId,
    bool? isLocked,
    int? coinPrice,
  }) {
    return EpisodeModel(
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      stream540p: stream540p ?? this.stream540p,
      stream720p: stream720p ?? this.stream720p,
      stream1080p: stream1080p ?? this.stream1080p,
      masterStream: masterStream ?? this.masterStream,
      seriesId: seriesId ?? this.seriesId,
      isLocked: isLocked ?? this.isLocked,
      coinPrice: coinPrice ?? this.coinPrice,
    );
  }

  String getStreamForQuality(String quality, {String? defaultSeriesId}) {
    final sid = seriesId ?? defaultSeriesId ?? '6';
    final ep = episodeNumber;
    final q = quality.toLowerCase().trim();

    if (q == '1080p') {
      if (stream1080p != null && stream1080p!.isNotEmpty) return stream1080p!;
      return 'https://dirjqbe1kaah2.cloudfront.net/$sid/$ep/videon1080x1920.m3u8';
    }

    if (q == '540p') {
      if (stream540p != null && stream540p!.isNotEmpty) return stream540p!;
      return 'https://dirjqbe1kaah2.cloudfront.net/$sid/$ep/videon540x960.m3u8';
    }

    if (q == 'auto') {
      if (masterStream != null && masterStream!.isNotEmpty) return masterStream!;
      return 'https://dirjqbe1kaah2.cloudfront.net/$sid/$ep/video.m3u8';
    }

    // Default: 720p HD (Direct VOD stream for instant start & maximum compatibility)
    if (stream720p != null && stream720p!.isNotEmpty) return stream720p!;
    return 'https://dirjqbe1kaah2.cloudfront.net/$sid/$ep/videon720x1280.m3u8';
  }

  factory EpisodeModel.fromJson(Map<String, dynamic> json, {String? seriesId}) {
    final streams = json['streams'] as Map<String, dynamic>? ?? {};
    final epNum = json['episode_number'] ?? json['episodeNumber'] ?? 1;
    final sid = seriesId ?? json['series_id']?.toString() ?? json['seriesId']?.toString();
    final locked = json['is_locked'] == true || json['isLocked'] == true;
    final price = json['coin_price'] ?? json['coinPrice'] ?? (locked ? 10 : 0);

    return EpisodeModel(
      episodeNumber: epNum,
      title: json['title'] ?? 'Episode $epNum',
      duration: json['duration'] ?? '1:30',
      thumbnail: json['thumbnail'] ?? json['cover_url'] ?? (sid != null ? 'https://dramapop-admin.genxappstudio.cloud/covers/$sid.webp?v=2' : null),
      stream540p: json['stream_540p'] ?? streams['540p'] ?? (sid != null ? 'https://dirjqbe1kaah2.cloudfront.net/$sid/$epNum/videon540x960.m3u8' : null),
      stream720p: json['stream_720p'] ?? json['streamUrl720p'] ?? streams['720p'] ?? (sid != null ? 'https://dirjqbe1kaah2.cloudfront.net/$sid/$epNum/videon720x1280.m3u8' : null),
      stream1080p: json['stream_1080p'] ?? json['streamUrl1080p'] ?? streams['1080p'] ?? (sid != null ? 'https://dirjqbe1kaah2.cloudfront.net/$sid/$epNum/videon1080x1920.m3u8' : null),
      masterStream: json['video_url'] ?? json['master_stream'] ?? streams['master'] ?? (sid != null ? 'https://dirjqbe1kaah2.cloudfront.net/$sid/$epNum/video.m3u8' : null),
      seriesId: sid,
      isLocked: locked,
      coinPrice: price is int ? price : (int.tryParse(price.toString()) ?? 10),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episode_number': episodeNumber,
      'title': title,
      'duration': duration,
      'thumbnail': thumbnail,
      'series_id': seriesId,
      'stream_540p': stream540p,
      'stream_720p': stream720p,
      'stream_1080p': stream1080p,
      'master_stream': masterStream,
      'is_locked': isLocked,
      'coin_price': coinPrice,
    };
  }
}
