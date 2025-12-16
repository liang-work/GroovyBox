import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_service.g.dart';

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
Future<TrackMetadata> trackMetadata(Ref ref, String path) {
  return ref.watch(metadataServiceProvider).getMetadata(path);
}
