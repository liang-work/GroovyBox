import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:groovybox/providers/db_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

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

final trackMetadataProvider = FutureProvider.family<TrackMetadata, String>((
  ref,
  path,
) async {
  try {
    // Import the database provider directly
    final db = ref.watch(databaseProvider);

    final track = await (db.select(
      db.tracks,
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
    } else {
      return TrackMetadata(
        title: 'Unknown Title',
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        artBytes: null,
      );
    }
  } catch (e) {
    debugPrint('Error fetching metadata for $path: $e');
    return TrackMetadata(
      title: 'Unknown Title',
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      artBytes: null,
    );
  }
});
