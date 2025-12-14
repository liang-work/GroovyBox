import 'package:groovybox/data/db.dart' as db;
import 'package:drift/drift.dart' as drift;
import 'package:groovybox/logic/lrc_providers.dart';
import 'package:groovybox/logic/lyrics_parser.dart';
import 'package:groovybox/providers/db_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lrc_fetcher_provider.g.dart';

@riverpod
class LyricsFetcher extends _$LyricsFetcher {
  @override
  LyricsFetcherState build() {
    return LyricsFetcherState();
  }

  Future<void> fetchLyricsForTrack({
    required int trackId,
    required String searchTerm,
    required LRCProvider provider,
    required String trackPath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lyrics = await provider.getLrc(searchTerm);
      if (lyrics == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No lyrics found from ${provider.name}',
        );
        return;
      }

      // Parse the lyrics into LyricsData format
      String? lyricsJson;
      if (lyrics.synced != null) {
        // It's LRC format
        final lyricsData = LyricsParser.parseLrc(lyrics.synced!);
        lyricsJson = lyricsData.toJsonString();
      } else if (lyrics.plain != null) {
        // Plain text
        final lyricsData = LyricsParser.parsePlaintext(lyrics.plain!);
        lyricsJson = lyricsData.toJsonString();
      }

      if (lyricsJson != null) {
        // Update the track in the database
        final database = ref.read(databaseProvider);
        await (database.update(database.tracks)
              ..where((t) => t.id.equals(trackId)))
            .write(db.TracksCompanion(lyrics: drift.Value(lyricsJson)));

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Lyrics fetched from ${provider.name}',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to parse lyrics',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching lyrics: $e',
      );
    }
  }
}

class LyricsFetcherState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  LyricsFetcherState({this.isLoading = false, this.error, this.successMessage});

  LyricsFetcherState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return LyricsFetcherState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// Providers for each LRC provider
final musixmatchProvider = Provider((ref) => MusixmatchProvider());
final neteaseProvider = Provider((ref) => NetEaseProvider());
