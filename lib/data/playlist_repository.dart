import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/db_provider.dart';
import 'db.dart';

part 'playlist_repository.g.dart';

@riverpod
class PlaylistRepository extends _$PlaylistRepository {
  @override
  FutureOr<void> build() {}

  // --- Playlists ---

  Stream<List<Playlist>> watchAllPlaylists() {
    final db = ref.watch(databaseProvider);
    return (db.select(
      db.playlists,
    )..orderBy([(p) => OrderingTerm(expression: p.createdAt)])).watch();
  }

  Stream<List<Track>> watchPlaylistTracks(int playlistId) {
    final db = ref.watch(databaseProvider);
    // Join PlaylistsEntries with Tracks
    final query =
        db.select(db.playlistEntries).join([
            innerJoin(
              db.tracks,
              db.tracks.id.equalsExp(db.playlistEntries.trackId),
            ),
          ])
          ..where(db.playlistEntries.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm(expression: db.playlistEntries.addedAt)]);

    return query.map((row) => row.readTable(db.tracks)).watch();
  }

  Future<int> createPlaylist(String name) async {
    final db = ref.read(databaseProvider);
    return db.into(db.playlists).insert(PlaylistsCompanion.insert(name: name));
  }

  Future<void> addToPlaylist(int playlistId, int trackId) async {
    final db = ref.read(databaseProvider);
    await db
        .into(db.playlistEntries)
        .insert(
          PlaylistEntriesCompanion.insert(
            playlistId: playlistId,
            trackId: trackId,
          ),
          mode: InsertMode.insertOrIgnore, // Prevent dupes if needed, or allow
        );
  }

  Future<void> deletePlaylist(int playlistId) async {
    final db = ref.read(databaseProvider);
    // entries cascade delete
    await (db.delete(db.playlists)..where((p) => p.id.equals(playlistId))).go();
  }

  Future<void> removeFromPlaylist(int playlistId, int trackId) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.playlistEntries)..where(
          (e) => e.playlistId.equals(playlistId) & e.trackId.equals(trackId),
        ))
        .go();
  }

  // --- Albums ---

  Stream<List<AlbumData>> watchAllAlbums() {
    final db = ref.watch(databaseProvider);
    // Distinct albums by grouping
    final query = db.selectOnly(db.tracks)
      ..addColumns([db.tracks.album, db.tracks.artist, db.tracks.artUri])
      ..groupBy([db.tracks.album, db.tracks.artist]);

    return query.map((row) {
      return AlbumData(
        album: row.read(db.tracks.album) ?? 'Unknown Album',
        artist: row.read(db.tracks.artist) ?? 'Unknown Artist',
        artUri: row.read(db.tracks.artUri),
      );
    }).watch();
  }

  Stream<List<Track>> watchAlbumTracks(String albumName) {
    final db = ref.watch(databaseProvider);
    return (db.select(
      db.tracks,
    )..where((t) => t.album.equals(albumName))).watch();
  }
}

class AlbumData {
  final String album;
  final String artist;
  final String? artUri;

  AlbumData({required this.album, required this.artist, this.artUri});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumData && album == other.album && artist == other.artist;

  @override
  int get hashCode => Object.hash(album, artist);
}
