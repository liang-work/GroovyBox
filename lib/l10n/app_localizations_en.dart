// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get noMediaSelected => 'No media selected';

  @override
  String get noLyricsAvailable => 'No Lyrics Available';

  @override
  String get fetchLyrics => 'Fetch Lyrics';

  @override
  String searchLyricsWith(String searchTerm) {
    return 'Search lyrics with $searchTerm';
  }

  @override
  String get whereToSearchLyrics => 'Where do you want to search lyrics from?';

  @override
  String get musixmatch => 'Musixmatch';

  @override
  String get netease => 'NetEase';

  @override
  String get lrclib => 'Lrclib';

  @override
  String get manualImport => 'Manual Import';

  @override
  String get cancel => 'Cancel';

  @override
  String get lyricsOptions => 'Lyrics Options';

  @override
  String get refetch => 'Re-fetch';

  @override
  String get clear => 'Clear';

  @override
  String get liveSyncLyrics => 'Live Sync Lyrics';

  @override
  String get manualOffset => 'Manual Offset';

  @override
  String get adjustLyricsTiming => 'Adjust Lyrics Timing';

  @override
  String get enterOffsetMs =>
      'Enter offset in milliseconds.\nPositive values delay lyrics, negative values advance them.';

  @override
  String get offsetMs => 'Offset (ms)';

  @override
  String get save => 'Save';

  @override
  String get liveLyricsSync => 'Live Lyrics Sync';

  @override
  String offset(int value) {
    return 'Offset: ${value}ms';
  }

  @override
  String get minus100ms => '-100ms';

  @override
  String get plus10ms => '+10ms';

  @override
  String get reset => 'Reset';

  @override
  String get plus100ms => '+100ms';

  @override
  String get fineAdjustment => 'Fine Adjustment';

  @override
  String get onlyTimedLyricsCanBeSynced => 'Only timed lyrics can be synced';

  @override
  String errorLoadingLyrics(String error) {
    return 'Error loading lyrics: $error';
  }

  @override
  String errorParsingLyrics(String error) {
    return 'Error parsing lyrics: $error';
  }

  @override
  String get noTracksInQueue => 'No tracks in queue';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get showLyrics => 'Show Lyrics';

  @override
  String get showQueue => 'Show Queue';

  @override
  String get showCover => 'Show Cover';

  @override
  String importedLyricsLines(int count, String title) {
    return 'Imported $count lyrics lines for \"$title\"';
  }

  @override
  String selected(int count) {
    return '$count selected';
  }

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get delete => 'Delete';

  @override
  String get groovyBox => 'GroovyBox';

  @override
  String get library => 'Library';

  @override
  String get importFiles => 'Import Files';

  @override
  String get searchTracks => 'Search tracks...';

  @override
  String searchTracksWithCount(int total) {
    return 'Search tracks... ($total tracks)';
  }

  @override
  String searchTracksFiltered(int filtered, int total) {
    return 'Search tracks... ($filtered of $total tracks)';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get noTracksYet => 'No tracks yet. Add some!';

  @override
  String get noTracksMatchSearch => 'No tracks match your search.';

  @override
  String get deleteTrack => 'Delete Track?';

  @override
  String confirmDeleteTrack(String title) {
    return 'Are you sure you want to delete \"$title\"? This cannot be undone.';
  }

  @override
  String deletedTrack(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get viewDetails => 'View Details';

  @override
  String get editMetadata => 'Edit Metadata';

  @override
  String get importLyrics => 'Import Lyrics';

  @override
  String get noPlaylistsAvailable =>
      'No playlists available. Create one first!';

  @override
  String addedToPlaylist(String name) {
    return 'Added to $name';
  }

  @override
  String get trackDetails => 'Track Details';

  @override
  String get close => 'Close';

  @override
  String get title => 'Title';

  @override
  String get artist => 'Artist';

  @override
  String get album => 'Album';

  @override
  String get duration => 'Duration';

  @override
  String get fileSize => 'File Size';

  @override
  String get filePath => 'File Path';

  @override
  String get dateAdded => 'Date Added';

  @override
  String get albumArt => 'Album Art';

  @override
  String get present => 'Present';

  @override
  String get editTrack => 'Edit Track';

  @override
  String addedTracksToPlaylist(int count, String name) {
    return 'Added $count tracks to $name';
  }

  @override
  String get deleteTracks => 'Delete Tracks?';

  @override
  String confirmDeleteTracks(int count) {
    return 'Are you sure you want to delete $count tracks? This will remove them from your device.';
  }

  @override
  String deletedTracks(int count) {
    return 'Deleted $count tracks';
  }

  @override
  String batchImportComplete(int matched, int notMatched) {
    return 'Batch import complete: $matched matched, $notMatched not matched';
  }

  @override
  String get settings => 'Settings';

  @override
  String get autoScan => 'Auto Scan';

  @override
  String get autoScanMusicLibraries => 'Auto-scan music libraries';

  @override
  String get autoScanDescription =>
      'Automatically scan music libraries for new music files';

  @override
  String get watchForChanges => 'Watch for changes';

  @override
  String get watchForChangesDescription =>
      'Monitor music libraries for file changes';

  @override
  String get musicLibraries => 'Music Libraries';

  @override
  String get scanLibraries => 'Scan Libraries';

  @override
  String get addMusicLibrary => 'Add Music Library';

  @override
  String get addMusicLibraryDescription =>
      'Add folder libraries to index music files. Files will be copied to internal storage for playback.';

  @override
  String get noMusicLibrariesAdded => 'No music libraries added yet.';

  @override
  String errorLoadingLibraries(String error) {
    return 'Error loading libraries: $error';
  }

  @override
  String get remoteProviders => 'Remote Providers';

  @override
  String get indexRemoteProviders => 'Index Remote Providers';

  @override
  String get addRemoteProvider => 'Add Remote Provider';

  @override
  String get remoteProvidersDescription =>
      'Connect to remote media servers like Jellyfin to access your music library.';

  @override
  String get noRemoteProvidersAdded => 'No remote providers added yet.';

  @override
  String errorLoadingProviders(String error) {
    return 'Error loading providers: $error';
  }

  @override
  String get playerSettings => 'Player Settings';

  @override
  String get playerSettingsDescription =>
      'Configure player behavior and display options.';

  @override
  String get defaultPlayerScreen => 'Default Player Screen';

  @override
  String get defaultPlayerScreenDescription =>
      'Choose which screen to show when opening the player.';

  @override
  String get lyricsMode => 'Lyrics Mode';

  @override
  String get lyricsModeDescription => 'Choose how lyrics are displayed.';

  @override
  String get continuePlaying => 'Continue Playing';

  @override
  String get continuePlayingDescription =>
      'Continue playing music after the queue is empty';

  @override
  String get databaseManagement => 'Database Management';

  @override
  String get databaseManagementDescription =>
      'Manage your music database and cached files.';

  @override
  String get resetTrackDatabase => 'Reset Track Database';

  @override
  String get resetTrackDatabaseDescription =>
      'Remove all tracks from database and delete cached files. This action cannot be undone.';

  @override
  String errorLoadingSettings(String error) {
    return 'Error loading settings: $error';
  }

  @override
  String addedMusicLibrary(String path) {
    return 'Added music library: $path';
  }

  @override
  String errorAddingLibrary(String error) {
    return 'Error adding library: $error';
  }

  @override
  String get librariesScannedSuccessfully => 'Libraries scanned successfully';

  @override
  String errorScanningLibraries(String error) {
    return 'Error scanning libraries: $error';
  }

  @override
  String get noActiveRemoteProviders => 'No active remote providers to index';

  @override
  String indexedRemoteProviders(int count) {
    return 'Indexed $count remote provider(s)';
  }

  @override
  String errorIndexingRemoteProviders(String error) {
    return 'Error indexing remote providers: $error';
  }

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://your-jellyfin-server.com';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get add => 'Add';

  @override
  String get allFieldsRequired => 'All fields are required';

  @override
  String addedRemoteProvider(String url) {
    return 'Added remote provider: $url';
  }

  @override
  String errorAddingProvider(String error) {
    return 'Error adding provider: $error';
  }

  @override
  String get confirmResetTrackDatabase =>
      'This will permanently delete all tracks from the database and remove all cached music files and album art. This action cannot be undone.\n\nAre you sure you want to continue?';

  @override
  String get trackDatabaseReset => 'Track database has been reset';

  @override
  String errorResettingDatabase(String error) {
    return 'Error resetting database: $error';
  }

  @override
  String get noTracksInAlbum => 'No tracks in this album';

  @override
  String get playAll => 'Play All';

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String get noTracksInPlaylist => 'No tracks in this playlist';

  @override
  String get noAlbumsFound => 'No albums found';

  @override
  String get createOne => 'Create One';

  @override
  String get addNewPlaylist => 'Add a new playlist';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get create => 'Create';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get queue => 'Queue';

  @override
  String get appSettings => 'App Settings';

  @override
  String get appSettingsDescription =>
      'Configure app-wide settings and preferences.';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Choose the app language.';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tracks => 'Tracks';

  @override
  String get albums => 'Albums';

  @override
  String get playlists => 'Playlists';

  @override
  String get addRemoteProviderDialog => 'Add Remote Provider';

  @override
  String get imported => 'Imported';

  @override
  String get lyricsLines => 'lyrics lines for';

  @override
  String get createdAt => 'created at';
}
