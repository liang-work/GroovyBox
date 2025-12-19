import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:groovybox/providers/remote_provider.dart';
import 'package:groovybox/providers/db_provider.dart';

class TrackMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? artBytes;

  TrackMetadata({this.title, this.artist, this.album, this.artBytes});
}

class MetadataService {
  Future<TrackMetadata> getMetadata(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return TrackMetadata();
    }
    try {
      final metadata = await MetadataRetriever.fromFile(file);
      return TrackMetadata(
        title: metadata.trackName,
        artist: metadata.trackArtistNames?.join(
          ', ',
        ), // metadata often returns lists
        album: metadata.albumName,
        artBytes: metadata.albumArt,
      );
    } catch (e) {
      // Fallback or ignore
      return TrackMetadata();
    }
  }
}

@Riverpod(keepAlive: true)
MetadataService metadataService(Ref ref) {
  return MetadataService();
}

@riverpod
Future<TrackMetadata> trackMetadata(Ref ref, String path) async {
  // Check if this is a remote track (protocol URL)
  final urlResolver = ref.watch(remoteUrlResolverProvider);
  if (urlResolver.isProtocolUrl(path)) {
    // For remote tracks, get metadata from database
    final database = ref.watch(databaseProvider);
    final track = await (database.select(
      database.tracks,
    )..where((t) => t.path.equals(path))).getSingleOrNull();

    if (track != null) {
      // For remote tracks, try to fetch album art from the stored URL
      Uint8List? artBytes;
      if (track.artUri != null) {
        try {
          final response = await http.get(Uri.parse(track.artUri!));
          if (response.statusCode == 200) {
            artBytes = response.bodyBytes;
          }
        } catch (e) {
          // Ignore art fetching errors - album art is not critical
          debugPrint('Failed to fetch album art from ${track.artUri}: $e');
        }
      }

      return TrackMetadata(
        title: track.title,
        artist: track.artist,
        album: track.album,
        artBytes: artBytes,
      );
    }
    return TrackMetadata();
  } else {
    // For local tracks, use file metadata
    final service = MetadataService();
    return service.getMetadata(path);
  }
}
