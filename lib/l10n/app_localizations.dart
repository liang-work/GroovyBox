import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @noMediaSelected.
  ///
  /// In en, this message translates to:
  /// **'No media selected'**
  String get noMediaSelected;

  /// No description provided for @noLyricsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Lyrics Available'**
  String get noLyricsAvailable;

  /// No description provided for @fetchLyrics.
  ///
  /// In en, this message translates to:
  /// **'Fetch Lyrics'**
  String get fetchLyrics;

  /// No description provided for @searchLyricsWith.
  ///
  /// In en, this message translates to:
  /// **'Search lyrics with {searchTerm}'**
  String searchLyricsWith(String searchTerm);

  /// No description provided for @whereToSearchLyrics.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to search lyrics from?'**
  String get whereToSearchLyrics;

  /// No description provided for @musixmatch.
  ///
  /// In en, this message translates to:
  /// **'Musixmatch'**
  String get musixmatch;

  /// No description provided for @netease.
  ///
  /// In en, this message translates to:
  /// **'NetEase'**
  String get netease;

  /// No description provided for @lrclib.
  ///
  /// In en, this message translates to:
  /// **'Lrclib'**
  String get lrclib;

  /// No description provided for @manualImport.
  ///
  /// In en, this message translates to:
  /// **'Manual Import'**
  String get manualImport;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @lyricsOptions.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Options'**
  String get lyricsOptions;

  /// No description provided for @refetch.
  ///
  /// In en, this message translates to:
  /// **'Re-fetch'**
  String get refetch;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @liveSyncLyrics.
  ///
  /// In en, this message translates to:
  /// **'Live Sync Lyrics'**
  String get liveSyncLyrics;

  /// No description provided for @manualOffset.
  ///
  /// In en, this message translates to:
  /// **'Manual Offset'**
  String get manualOffset;

  /// No description provided for @adjustLyricsTiming.
  ///
  /// In en, this message translates to:
  /// **'Adjust Lyrics Timing'**
  String get adjustLyricsTiming;

  /// No description provided for @enterOffsetMs.
  ///
  /// In en, this message translates to:
  /// **'Enter offset in milliseconds.\nPositive values delay lyrics, negative values advance them.'**
  String get enterOffsetMs;

  /// No description provided for @offsetMs.
  ///
  /// In en, this message translates to:
  /// **'Offset (ms)'**
  String get offsetMs;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @liveLyricsSync.
  ///
  /// In en, this message translates to:
  /// **'Live Lyrics Sync'**
  String get liveLyricsSync;

  /// No description provided for @offset.
  ///
  /// In en, this message translates to:
  /// **'Offset: {value}ms'**
  String offset(int value);

  /// No description provided for @minus100ms.
  ///
  /// In en, this message translates to:
  /// **'-100ms'**
  String get minus100ms;

  /// No description provided for @plus10ms.
  ///
  /// In en, this message translates to:
  /// **'+10ms'**
  String get plus10ms;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @plus100ms.
  ///
  /// In en, this message translates to:
  /// **'+100ms'**
  String get plus100ms;

  /// No description provided for @fineAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Fine Adjustment'**
  String get fineAdjustment;

  /// No description provided for @onlyTimedLyricsCanBeSynced.
  ///
  /// In en, this message translates to:
  /// **'Only timed lyrics can be synced'**
  String get onlyTimedLyricsCanBeSynced;

  /// No description provided for @errorLoadingLyrics.
  ///
  /// In en, this message translates to:
  /// **'Error loading lyrics: {error}'**
  String errorLoadingLyrics(String error);

  /// No description provided for @errorParsingLyrics.
  ///
  /// In en, this message translates to:
  /// **'Error parsing lyrics: {error}'**
  String errorParsingLyrics(String error);

  /// No description provided for @noTracksInQueue.
  ///
  /// In en, this message translates to:
  /// **'No tracks in queue'**
  String get noTracksInQueue;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// No description provided for @showLyrics.
  ///
  /// In en, this message translates to:
  /// **'Show Lyrics'**
  String get showLyrics;

  /// No description provided for @showQueue.
  ///
  /// In en, this message translates to:
  /// **'Show Queue'**
  String get showQueue;

  /// No description provided for @showCover.
  ///
  /// In en, this message translates to:
  /// **'Show Cover'**
  String get showCover;

  /// No description provided for @importedLyricsLines.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} lyrics lines for \"{title}\"'**
  String importedLyricsLines(int count, String title);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(int count);

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @groovyBox.
  ///
  /// In en, this message translates to:
  /// **'GroovyBox'**
  String get groovyBox;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @importFiles.
  ///
  /// In en, this message translates to:
  /// **'Import Files'**
  String get importFiles;

  /// No description provided for @searchTracks.
  ///
  /// In en, this message translates to:
  /// **'Search tracks...'**
  String get searchTracks;

  /// No description provided for @searchTracksWithCount.
  ///
  /// In en, this message translates to:
  /// **'Search tracks... ({total} tracks)'**
  String searchTracksWithCount(int total);

  /// No description provided for @searchTracksFiltered.
  ///
  /// In en, this message translates to:
  /// **'Search tracks... ({filtered} of {total} tracks)'**
  String searchTracksFiltered(int filtered, int total);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @noTracksYet.
  ///
  /// In en, this message translates to:
  /// **'No tracks yet. Add some!'**
  String get noTracksYet;

  /// No description provided for @noTracksMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No tracks match your search.'**
  String get noTracksMatchSearch;

  /// No description provided for @deleteTrack.
  ///
  /// In en, this message translates to:
  /// **'Delete Track?'**
  String get deleteTrack;

  /// No description provided for @confirmDeleteTrack.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This cannot be undone.'**
  String confirmDeleteTrack(String title);

  /// No description provided for @deletedTrack.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String deletedTrack(String title);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @editMetadata.
  ///
  /// In en, this message translates to:
  /// **'Edit Metadata'**
  String get editMetadata;

  /// No description provided for @importLyrics.
  ///
  /// In en, this message translates to:
  /// **'Import Lyrics'**
  String get importLyrics;

  /// No description provided for @noPlaylistsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No playlists available. Create one first!'**
  String get noPlaylistsAvailable;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedToPlaylist(String name);

  /// No description provided for @trackDetails.
  ///
  /// In en, this message translates to:
  /// **'Track Details'**
  String get trackDetails;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @filePath.
  ///
  /// In en, this message translates to:
  /// **'File Path'**
  String get filePath;

  /// No description provided for @dateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// No description provided for @albumArt.
  ///
  /// In en, this message translates to:
  /// **'Album Art'**
  String get albumArt;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @editTrack.
  ///
  /// In en, this message translates to:
  /// **'Edit Track'**
  String get editTrack;

  /// No description provided for @addedTracksToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to {name}'**
  String addedTracksToPlaylist(int count, String name);

  /// No description provided for @deleteTracks.
  ///
  /// In en, this message translates to:
  /// **'Delete Tracks?'**
  String get deleteTracks;

  /// No description provided for @confirmDeleteTracks.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} tracks? This will remove them from your device.'**
  String confirmDeleteTracks(int count);

  /// No description provided for @deletedTracks.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} tracks'**
  String deletedTracks(int count);

  /// No description provided for @batchImportComplete.
  ///
  /// In en, this message translates to:
  /// **'Batch import complete: {matched} matched, {notMatched} not matched'**
  String batchImportComplete(int matched, int notMatched);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @autoScan.
  ///
  /// In en, this message translates to:
  /// **'Auto Scan'**
  String get autoScan;

  /// No description provided for @autoScanMusicLibraries.
  ///
  /// In en, this message translates to:
  /// **'Auto-scan music libraries'**
  String get autoScanMusicLibraries;

  /// No description provided for @autoScanDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically scan music libraries for new music files'**
  String get autoScanDescription;

  /// No description provided for @watchForChanges.
  ///
  /// In en, this message translates to:
  /// **'Watch for changes'**
  String get watchForChanges;

  /// No description provided for @watchForChangesDescription.
  ///
  /// In en, this message translates to:
  /// **'Monitor music libraries for file changes'**
  String get watchForChangesDescription;

  /// No description provided for @musicLibraries.
  ///
  /// In en, this message translates to:
  /// **'Music Libraries'**
  String get musicLibraries;

  /// No description provided for @scanLibraries.
  ///
  /// In en, this message translates to:
  /// **'Scan Libraries'**
  String get scanLibraries;

  /// No description provided for @addMusicLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add Music Library'**
  String get addMusicLibrary;

  /// No description provided for @addMusicLibraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Add folder libraries to index music files. Files will be copied to internal storage for playback.'**
  String get addMusicLibraryDescription;

  /// No description provided for @noMusicLibrariesAdded.
  ///
  /// In en, this message translates to:
  /// **'No music libraries added yet.'**
  String get noMusicLibrariesAdded;

  /// No description provided for @errorLoadingLibraries.
  ///
  /// In en, this message translates to:
  /// **'Error loading libraries: {error}'**
  String errorLoadingLibraries(String error);

  /// No description provided for @remoteProviders.
  ///
  /// In en, this message translates to:
  /// **'Remote Providers'**
  String get remoteProviders;

  /// No description provided for @indexRemoteProviders.
  ///
  /// In en, this message translates to:
  /// **'Index Remote Providers'**
  String get indexRemoteProviders;

  /// No description provided for @addRemoteProvider.
  ///
  /// In en, this message translates to:
  /// **'Add Remote Provider'**
  String get addRemoteProvider;

  /// No description provided for @remoteProvidersDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to remote media servers like Jellyfin to access your music library.'**
  String get remoteProvidersDescription;

  /// No description provided for @noRemoteProvidersAdded.
  ///
  /// In en, this message translates to:
  /// **'No remote providers added yet.'**
  String get noRemoteProvidersAdded;

  /// No description provided for @errorLoadingProviders.
  ///
  /// In en, this message translates to:
  /// **'Error loading providers: {error}'**
  String errorLoadingProviders(String error);

  /// No description provided for @playerSettings.
  ///
  /// In en, this message translates to:
  /// **'Player Settings'**
  String get playerSettings;

  /// No description provided for @playerSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure player behavior and display options.'**
  String get playerSettingsDescription;

  /// No description provided for @defaultPlayerScreen.
  ///
  /// In en, this message translates to:
  /// **'Default Player Screen'**
  String get defaultPlayerScreen;

  /// No description provided for @defaultPlayerScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which screen to show when opening the player.'**
  String get defaultPlayerScreenDescription;

  /// No description provided for @lyricsMode.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Mode'**
  String get lyricsMode;

  /// No description provided for @lyricsModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how lyrics are displayed.'**
  String get lyricsModeDescription;

  /// No description provided for @continuePlaying.
  ///
  /// In en, this message translates to:
  /// **'Continue Playing'**
  String get continuePlaying;

  /// No description provided for @continuePlayingDescription.
  ///
  /// In en, this message translates to:
  /// **'Continue playing music after the queue is empty'**
  String get continuePlayingDescription;

  /// No description provided for @databaseManagement.
  ///
  /// In en, this message translates to:
  /// **'Database Management'**
  String get databaseManagement;

  /// No description provided for @databaseManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your music database and cached files.'**
  String get databaseManagementDescription;

  /// No description provided for @resetTrackDatabase.
  ///
  /// In en, this message translates to:
  /// **'Reset Track Database'**
  String get resetTrackDatabase;

  /// No description provided for @resetTrackDatabaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all tracks from database and delete cached files. This action cannot be undone.'**
  String get resetTrackDatabaseDescription;

  /// No description provided for @errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings: {error}'**
  String errorLoadingSettings(String error);

  /// No description provided for @addedMusicLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added music library: {path}'**
  String addedMusicLibrary(String path);

  /// No description provided for @errorAddingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Error adding library: {error}'**
  String errorAddingLibrary(String error);

  /// No description provided for @librariesScannedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Libraries scanned successfully'**
  String get librariesScannedSuccessfully;

  /// No description provided for @errorScanningLibraries.
  ///
  /// In en, this message translates to:
  /// **'Error scanning libraries: {error}'**
  String errorScanningLibraries(String error);

  /// No description provided for @noActiveRemoteProviders.
  ///
  /// In en, this message translates to:
  /// **'No active remote providers to index'**
  String get noActiveRemoteProviders;

  /// No description provided for @indexedRemoteProviders.
  ///
  /// In en, this message translates to:
  /// **'Indexed {count} remote provider(s)'**
  String indexedRemoteProviders(int count);

  /// No description provided for @errorIndexingRemoteProviders.
  ///
  /// In en, this message translates to:
  /// **'Error indexing remote providers: {error}'**
  String errorIndexingRemoteProviders(String error);

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://your-jellyfin-server.com'**
  String get serverUrlHint;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get allFieldsRequired;

  /// No description provided for @addedRemoteProvider.
  ///
  /// In en, this message translates to:
  /// **'Added remote provider: {url}'**
  String addedRemoteProvider(String url);

  /// No description provided for @errorAddingProvider.
  ///
  /// In en, this message translates to:
  /// **'Error adding provider: {error}'**
  String errorAddingProvider(String error);

  /// No description provided for @confirmResetTrackDatabase.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all tracks from the database and remove all cached music files and album art. This action cannot be undone.\n\nAre you sure you want to continue?'**
  String get confirmResetTrackDatabase;

  /// No description provided for @trackDatabaseReset.
  ///
  /// In en, this message translates to:
  /// **'Track database has been reset'**
  String get trackDatabaseReset;

  /// No description provided for @errorResettingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Error resetting database: {error}'**
  String errorResettingDatabase(String error);

  /// No description provided for @noTracksInAlbum.
  ///
  /// In en, this message translates to:
  /// **'No tracks in this album'**
  String get noTracksInAlbum;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @noTracksInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No tracks in this playlist'**
  String get noTracksInPlaylist;

  /// No description provided for @noAlbumsFound.
  ///
  /// In en, this message translates to:
  /// **'No albums found'**
  String get noAlbumsFound;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create One'**
  String get createOne;

  /// No description provided for @addNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add a new playlist'**
  String get addNewPlaylist;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @appSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure app-wide settings and preferences.'**
  String get appSettingsDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get languageDescription;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
