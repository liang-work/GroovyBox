import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:groovybox/data/db.dart';
import 'package:groovybox/providers/db_provider.dart';
import 'package:groovybox/providers/settings_provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';

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
    final settings = ref.read(settingsProvider).value;
    final importMode = settings?.importMode ?? ImportMode.copy;

    // Filter out files that are already indexed
    final existingPaths = await (db.select(
      db.tracks,
    )..where((t) => t.path.isIn(filePaths))).map((t) => t.path).get();

    final existingPathsSet = existingPaths.toSet();
    final newFilePaths = filePaths
        .where((path) => !existingPathsSet.contains(path))
        .toList();

    if (newFilePaths.isEmpty) {
      return; // All files already indexed
    }

    if (importMode == ImportMode.copy) {
      await _importFilesWithCopy(newFilePaths);
    } else {
      await _importFilesInPlace(newFilePaths);
    }
  }

  Future<void> _importFilesWithCopy(List<String> filePaths) async {
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
        debugPrint('Error importing file $path: $e');
        // Continue to next file
      }
    }
  }

  Future<void> _importFilesInPlace(List<String> filePaths) async {
    final db = ref.read(databaseProvider);
    final appDir = await getApplicationDocumentsDirectory();
    final artDir = Directory(p.join(appDir.path, 'art'));

    await artDir.create(recursive: true);

    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) continue;

      try {
        // 1. Extract Metadata from original file
        final metadata = await MetadataRetriever.fromFile(file);
        final filename = p.basename(path);

        String? artPath;
        if (metadata.albumArt != null) {
          // Store album art in internal directory
          final artName =
              '${p.basenameWithoutExtension(filename)}_${DateTime.now().millisecondsSinceEpoch}_art.jpg';
          final artFile = File(p.join(artDir.path, artName));
          await artFile.writeAsBytes(metadata.albumArt!);
          artPath = artFile.path;
        }

        // 2. Insert into DB with original path
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                title:
                    metadata.trackName ?? p.basenameWithoutExtension(filename),
                path: path, // Original path for in-place indexing
                artist: Value(metadata.trackArtistNames?.join(', ')),
                album: Value(metadata.albumName),
                duration: Value(metadata.trackDuration), // Milliseconds
                artUri: Value(artPath),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      } catch (e) {
        debugPrint('Error importing file $path: $e');
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

    // 3. Delete file only if it's a copied file (in internal music directory)
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = p.join(appDir.path, 'music');

    final file = File(track.path);
    if (await file.exists()) {
      // Only delete if it's in our internal music directory (copied files)
      // For in-place indexed files, we don't delete the original
      if (track.path.startsWith(musicDir)) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint("Error deleting file: $e");
        }
      }
    }

    // 4. Delete art if exists (album art is always stored internally)
    if (track.artUri != null) {
      final artFile = File(track.artUri!);
      if (await artFile.exists()) {
        try {
          await artFile.delete();
        } catch (e) {
          debugPrint("Error deleting art: $e");
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

  /// Scan a directory for music files and import them.
  Future<void> scanDirectory(
    String directoryPath, {
    bool recursive = true,
  }) async {
    final settings = ref.read(settingsProvider).value;
    final supportedFormats =
        settings?.supportedFormats ??
        {'.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg', '.wma', '.opus'};

    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist: $directoryPath');
    }

    final List<String> musicFiles = [];

    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is File) {
        final extension = p.extension(entity.path).toLowerCase();
        if (supportedFormats.contains(extension)) {
          musicFiles.add(entity.path);
        }
      }
    }

    if (musicFiles.isNotEmpty) {
      await importFiles(musicFiles);
    }
  }

  /// Scan all watch folders for new/updated files.
  Future<void> scanWatchFolders() async {
    final db = ref.read(databaseProvider);
    final watchFolders = await (db.select(
      db.watchFolders,
    )..where((t) => t.isActive.equals(true))).get();

    for (final folder in watchFolders) {
      try {
        await scanDirectory(folder.path, recursive: folder.recursive);

        // Update last scanned time
        await (db.update(db.watchFolders)..where((t) => t.id.equals(folder.id)))
            .write(WatchFoldersCompanion(lastScanned: Value(DateTime.now())));
      } catch (e) {
        debugPrint('Error scanning watch folder ${folder.path}: $e');
      }
    }
  }

  /// Add a file from watch folder event.
  Future<void> addFileFromWatch(String filePath) async {
    final settings = ref.read(settingsProvider).value;
    final supportedFormats =
        settings?.supportedFormats ??
        {'.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg', '.wma', '.opus'};

    final extension = p.extension(filePath).toLowerCase();
    if (!supportedFormats.contains(extension)) {
      return; // Not a supported audio file
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    await importFiles([filePath]);
  }

  /// Remove a file from watch folder event.
  Future<void> removeFileFromWatch(String filePath) async {
    final db = ref.read(databaseProvider);

    // Find track by path
    final track = await (db.select(
      db.tracks,
    )..where((t) => t.path.equals(filePath))).getSingleOrNull();

    if (track != null) {
      await deleteTrack(track.id);
    }
  }

  /// Update a file from watch folder event.
  Future<void> updateFileFromWatch(String filePath) async {
    // For now, we remove and re-add the file
    // In a more sophisticated implementation, we could update metadata only
    await removeFileFromWatch(filePath);
    await addFileFromWatch(filePath);
  }

  /// Check if a track exists and is accessible.
  Future<bool> isTrackAccessible(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking track accessibility $filePath: $e');
      return false;
    }
  }

  /// Clean up tracks that no longer exist (for in-place indexed tracks).
  Future<void> cleanupMissingTracks() async {
    final db = ref.read(databaseProvider);
    final settings = ref.read(settingsProvider).value;

    if (settings?.importMode == ImportMode.copy) {
      return; // Only cleanup for in-place indexed tracks
    }

    final allTracks = await db.select(db.tracks).get();

    for (final track in allTracks) {
      if (!await isTrackAccessible(track.path)) {
        debugPrint('Removing missing track: ${track.path}');
        // Remove from database but don't delete file (since it doesn't exist)
        await (db.delete(db.tracks)..where((t) => t.id.equals(track.id))).go();

        // Clean up album art
        if (track.artUri != null) {
          final artFile = File(track.artUri!);
          if (await artFile.exists()) {
            try {
              await artFile.delete();
            } catch (e) {
              debugPrint("Error deleting missing track's art: $e");
            }
          }
        }
      }
    }
  }
}
