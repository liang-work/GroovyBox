import 'dart:io';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:groovybox/providers/db_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import 'db.dart';

part 'track_repository.g.dart';

@riverpod
class TrackRepository extends _$TrackRepository {
  @override
  FutureOr<void> build() {}

  Stream<List<Track>> watchAllTracks() {
    final db = ref.watch(databaseProvider);
    return (db.select(
      db.tracks,
    )..orderBy([(t) => OrderingTerm(expression: t.title)])).watch();
  }

  Future<void> importFiles(List<String> filePaths) async {
    final db = ref.read(databaseProvider);
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(appDir.path, 'music'));
    final artDir = Directory(p.join(appDir.path, 'art'));

    await musicDir.create(recursive: true);
    await artDir.create(recursive: true);

    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      try {
        // 1. Copy file
        final filename = p.basename(path);
        // Ensure unique name to avoid overwriting or conflicts
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$filename';
        final newPath = p.join(musicDir.path, uniqueName);
        await file.copy(newPath);

        // 2. Extract Metadata
        final metadata = await MetadataRetriever.fromFile(File(newPath));

        String? artPath;
        if (metadata.albumArt != null) {
          final artName = '${uniqueName}_art.jpg';
          final artFile = File(p.join(artDir.path, artName));
          await artFile.writeAsBytes(metadata.albumArt!);
          artPath = artFile.path;
        }

        // 3. Insert into DB
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                title:
                    metadata.trackName ?? p.basenameWithoutExtension(filename),
                path: newPath, // Internal path
                artist: Value(metadata.trackArtistNames?.join(', ')),
                album: Value(metadata.albumName),
                duration: Value(metadata.trackDuration), // Milliseconds
                artUri: Value(artPath),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      } catch (e) {
        print('Error importing file $path: $e');
        // Continue to next file
      }
    }
  }

  Future<void> updateMetadata({
    required int trackId,
    required String title,
    String? artist,
    String? album,
  }) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tracks)..where((t) => t.id.equals(trackId))).write(
      TracksCompanion(
        title: Value(title),
        artist: Value(artist),
        album: Value(album),
      ),
    );
  }

  Future<void> deleteTrack(int trackId) async {
    final db = ref.read(databaseProvider);

    // 1. Get track info to find file path
    final track = await (db.select(
      db.tracks,
    )..where((t) => t.id.equals(trackId))).getSingleOrNull();
    if (track == null) return;

    // 2. Delete from DB (cascade should handle playlist entries if configured, but we didn't set cascade on playlistEntries -> tracks properly maybe? CHECK DB)
    // In db.dart: IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
    // So DB deletion cascades to entries.

    await (db.delete(db.tracks)..where((t) => t.id.equals(trackId))).go();

    // 3. Delete file
    final file = File(track.path);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        print("Error deleting file: $e");
      }
    }

    // 4. Delete art if exists
    if (track.artUri != null) {
      final artFile = File(track.artUri!);
      if (await artFile.exists()) {
        try {
          await artFile.delete();
        } catch (e) {
          print("Error deleting art: $e");
        }
      }
    }
  }

  /// Update lyrics for a track.
  Future<void> updateLyrics(int trackId, String? lyricsJson) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.tracks)..where((t) => t.id.equals(trackId))).write(
      TracksCompanion(lyrics: Value(lyricsJson)),
    );
  }

  /// Get a single track by ID.
  Future<Track?> getTrack(int trackId) async {
    final db = ref.read(databaseProvider);
    return (db.select(
      db.tracks,
    )..where((t) => t.id.equals(trackId))).getSingleOrNull();
  }

  /// Get all tracks for batch matching.
  Future<List<Track>> getAllTracks() async {
    final db = ref.read(databaseProvider);
    return db.select(db.tracks).get();
  }
}
