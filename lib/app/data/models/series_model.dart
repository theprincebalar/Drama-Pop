import 'package:get/get.dart';
import 'episode_model.dart';
import '../services/unlock_service.dart';

class SeriesModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<String> genres;
  final int episodesCount;
  final int views;
  final double rating;
  final List<EpisodeModel> episodes;
  final String? year;
  final String? status;

  SeriesModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.genres,
    required this.episodesCount,
    this.views = 0,
    this.rating = 4.8,
    this.episodes = const [],
    this.year = '2026',
    this.status = 'Completed',
  });

  static int calculateFreeEpisodesCount(int totalEpisodes) {
    if (totalEpisodes < 20) return 6;
    if (totalEpisodes < 30) return 8;
    if (totalEpisodes < 50) return 10;
    return 11;
  }

  int get freeEpisodesCount {
    final count = episodesCount > 0 ? episodesCount : (episodes.isNotEmpty ? episodes.length : 45);
    return calculateFreeEpisodesCount(count);
  }

  bool isEpisodeLocked(int epNum) {
    if (Get.isRegistered<UnlockService>() && UnlockService.to.isEpisodeUnlocked(id, epNum)) {
      return false;
    }
    return epNum > freeEpisodesCount;
  }

  List<EpisodeModel> get effectiveEpisodes {
    final count = episodesCount > 0 ? episodesCount : (episodes.isNotEmpty ? episodes.length : 45);

    if (episodes.isNotEmpty) {
      return episodes.map((ep) {
        final locked = isEpisodeLocked(ep.episodeNumber);
        return ep.copyWith(
          isLocked: locked,
          coinPrice: locked ? (ep.coinPrice > 0 ? ep.coinPrice : 10) : 0,
        );
      }).toList();
    }

    return List.generate(count, (idx) {
      final epNum = idx + 1;
      final locked = isEpisodeLocked(epNum);
      return EpisodeModel(
        episodeNumber: epNum,
        title: 'Episode $epNum',
        seriesId: id,
        thumbnail: coverUrl,
        isLocked: locked,
        coinPrice: locked ? 10 : 0,
        stream540p: 'https://dirjqbe1kaah2.cloudfront.net/$id/$epNum/videon540x960.m3u8',
        stream720p: 'https://dirjqbe1kaah2.cloudfront.net/$id/$epNum/videon720x1280.m3u8',
        stream1080p: 'https://dirjqbe1kaah2.cloudfront.net/$id/$epNum/videon1080x1920.m3u8',
        masterStream: 'https://dirjqbe1kaah2.cloudfront.net/$id/$epNum/video.m3u8',
      );
    });
  }

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    final sid = (json['id'] ?? '').toString();
    var rawEpisodes = json['episodes'] as List? ?? [];
    final epCountRaw = json['episodesCount'] ?? json['episodes_count'] ?? json['totalEpisodes'] ?? (rawEpisodes.isNotEmpty ? rawEpisodes.length : 45);
    final epCount = epCountRaw is int ? epCountRaw : (int.tryParse(epCountRaw.toString()) ?? 45);
    final freeCount = calculateFreeEpisodesCount(epCount);

    List<EpisodeModel> parsedEpisodes = rawEpisodes.map((e) {
      final epMap = Map<String, dynamic>.from(e);
      final epNum = epMap['episode_number'] ?? epMap['episodeNumber'] ?? 1;
      final locked = epNum > freeCount;
      epMap['is_locked'] = locked;
      epMap['isLocked'] = locked;
      epMap['coin_price'] = locked ? (epMap['coin_price'] ?? epMap['coinPrice'] ?? 10) : 0;
      return EpisodeModel.fromJson(epMap, seriesId: sid);
    }).toList();

    List<String> parsedGenres = [];
    if (json['genres'] is List) {
      parsedGenres = (json['genres'] as List).map((e) => e.toString()).toList();
    } else if (json['genre'] is String) {
      parsedGenres = [json['genre']];
    } else {
      parsedGenres = ['Billionaire', 'Romance'];
    }

    final cover = json['coverUrl'] ?? json['coverImage'] ?? json['cover_url'] ?? (sid.isNotEmpty ? 'https://dramapop-admin.genxappstudio.cloud/covers/$sid.webp?v=2' : 'https://placehold.co/400x600/1e293b/cbd5e1?text=DramaPop');

    return SeriesModel(
      id: sid,
      title: json['title'] ?? 'Drama Series',
      description: json['description'] ?? json['synopsis'] ?? 'An exciting vertical short drama full of twists and romance.',
      coverUrl: cover,
      genres: parsedGenres,
      episodesCount: epCount,
      views: json['views'] ?? 150000,
      rating: (json['rating'] ?? 4.8).toDouble(),
      episodes: parsedEpisodes,
      year: json['year'] ?? '2026',
      status: json['status'] ?? 'Completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'genres': genres,
      'episodesCount': episodesCount,
      'views': views,
      'rating': rating,
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'year': year,
      'status': status,
    };
  }
}