// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get noMediaSelected => '未选择媒体';

  @override
  String get noLyricsAvailable => '无歌词可用';

  @override
  String get fetchLyrics => '获取歌词';

  @override
  String searchLyricsWith(String searchTerm) {
    return '使用 $searchTerm 搜索歌词';
  }

  @override
  String get whereToSearchLyrics => '您想从哪里搜索歌词？';

  @override
  String get musixmatch => 'Musixmatch';

  @override
  String get netease => '网易云音乐';

  @override
  String get lrclib => 'Lrclib';

  @override
  String get manualImport => '手动导入';

  @override
  String get cancel => '取消';

  @override
  String get lyricsOptions => '歌词选项';

  @override
  String get refetch => '重新获取';

  @override
  String get clear => '清除';

  @override
  String get liveSyncLyrics => '实时同步歌词';

  @override
  String get manualOffset => '手动偏移';

  @override
  String get adjustLyricsTiming => '调整歌词时间';

  @override
  String get enterOffsetMs => '输入偏移量（毫秒）。\n正值延迟歌词显示，负值提前显示。';

  @override
  String get offsetMs => '偏移量（毫秒）';

  @override
  String get save => '保存';

  @override
  String get liveLyricsSync => '实时歌词同步';

  @override
  String offset(int value) {
    return '偏移量：$value毫秒';
  }

  @override
  String get minus100ms => '-100毫秒';

  @override
  String get plus10ms => '+10毫秒';

  @override
  String get reset => '重置';

  @override
  String get plus100ms => '+100毫秒';

  @override
  String get fineAdjustment => '精细调整';

  @override
  String get onlyTimedLyricsCanBeSynced => '只有带时间戳的歌词才能同步';

  @override
  String errorLoadingLyrics(String error) {
    return '加载歌词时出错：$error';
  }

  @override
  String errorParsingLyrics(String error) {
    return '解析歌词时出错：$error';
  }

  @override
  String get noTracksInQueue => '队列中没有曲目';

  @override
  String get unknownArtist => '未知艺术家';

  @override
  String get showLyrics => '显示歌词';

  @override
  String get showQueue => '显示队列';

  @override
  String get showCover => '显示封面';

  @override
  String importedLyricsLines(int count, String title) {
    return '为\"$title\"导入了 $count 行歌词';
  }

  @override
  String selected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get addToPlaylist => '添加到播放列表';

  @override
  String get delete => '删除';

  @override
  String get groovyBox => 'GroovyBox';

  @override
  String get library => '音乐库';

  @override
  String get importFiles => '导入文件';

  @override
  String get searchTracks => '搜索曲目...';

  @override
  String searchTracksWithCount(int total) {
    return '搜索曲目...（共 $total 首）';
  }

  @override
  String searchTracksFiltered(int filtered, int total) {
    return '搜索曲目...（$filtered / $total 首）';
  }

  @override
  String error(String message) {
    return '错误：$message';
  }

  @override
  String get noTracksYet => '还没有曲目，请添加一些！';

  @override
  String get noTracksMatchSearch => '没有匹配搜索的曲目。';

  @override
  String get deleteTrack => '删除曲目？';

  @override
  String confirmDeleteTrack(String title) {
    return '您确定要删除\"$title\"吗？此操作无法撤销。';
  }

  @override
  String deletedTrack(String title) {
    return '已删除\"$title\"';
  }

  @override
  String get viewDetails => '查看详情';

  @override
  String get editMetadata => '编辑元数据';

  @override
  String get importLyrics => '导入歌词';

  @override
  String get noPlaylistsAvailable => '没有可用的播放列表，请先创建一个！';

  @override
  String addedToPlaylist(String name) {
    return '已添加到 $name';
  }

  @override
  String get trackDetails => '曲目详情';

  @override
  String get close => '关闭';

  @override
  String get title => '标题';

  @override
  String get artist => '艺术家';

  @override
  String get album => '专辑';

  @override
  String get duration => '时长';

  @override
  String get fileSize => '文件大小';

  @override
  String get filePath => '文件路径';

  @override
  String get dateAdded => '添加日期';

  @override
  String get albumArt => '专辑封面';

  @override
  String get present => '存在';

  @override
  String get editTrack => '编辑曲目';

  @override
  String addedTracksToPlaylist(int count, String name) {
    return '已将 $count 首曲目添加到 $name';
  }

  @override
  String get deleteTracks => '删除曲目？';

  @override
  String confirmDeleteTracks(int count) {
    return '您确定要删除 $count 首曲目吗？这将从您的设备中移除它们。';
  }

  @override
  String deletedTracks(int count) {
    return '已删除 $count 首曲目';
  }

  @override
  String batchImportComplete(int matched, int notMatched) {
    return '批量导入完成：$matched 匹配，$notMatched 不匹配';
  }

  @override
  String get settings => '设置';

  @override
  String get autoScan => '自动扫描';

  @override
  String get autoScanMusicLibraries => '自动扫描音乐库';

  @override
  String get autoScanDescription => '自动扫描音乐库中的新音乐文件';

  @override
  String get watchForChanges => '监视更改';

  @override
  String get watchForChangesDescription => '监视音乐库的文件更改';

  @override
  String get musicLibraries => '音乐库';

  @override
  String get scanLibraries => '扫描库';

  @override
  String get addMusicLibrary => '添加音乐库';

  @override
  String get addMusicLibraryDescription => '添加文件夹库来索引音乐文件。文件将被复制到内部存储以供播放。';

  @override
  String get noMusicLibrariesAdded => '尚未添加音乐库。';

  @override
  String errorLoadingLibraries(String error) {
    return '加载库时出错：$error';
  }

  @override
  String get remoteProviders => '远程提供商';

  @override
  String get indexRemoteProviders => '索引远程提供商';

  @override
  String get addRemoteProvider => '添加远程提供商';

  @override
  String get remoteProvidersDescription => '连接到远程媒体服务器，如Jellyfin，来访问您的音乐库。';

  @override
  String get noRemoteProvidersAdded => '尚未添加远程提供商。';

  @override
  String errorLoadingProviders(String error) {
    return '加载提供商时出错：$error';
  }

  @override
  String get playerSettings => '播放器设置';

  @override
  String get playerSettingsDescription => '配置播放器行为和显示选项。';

  @override
  String get defaultPlayerScreen => '默认播放器屏幕';

  @override
  String get defaultPlayerScreenDescription => '选择打开播放器时显示的屏幕。';

  @override
  String get lyricsMode => '歌词模式';

  @override
  String get lyricsModeDescription => '选择歌词的显示方式。';

  @override
  String get continuePlaying => '继续播放';

  @override
  String get continuePlayingDescription => '队列为空后继续播放音乐';

  @override
  String get databaseManagement => '数据库管理';

  @override
  String get databaseManagementDescription => '管理您的音乐数据库和缓存文件。';

  @override
  String get resetTrackDatabase => '重置曲目数据库';

  @override
  String get resetTrackDatabaseDescription => '从数据库中移除所有曲目并删除缓存文件。此操作无法撤销。';

  @override
  String errorLoadingSettings(String error) {
    return '加载设置时出错：$error';
  }

  @override
  String addedMusicLibrary(String path) {
    return '已添加音乐库：$path';
  }

  @override
  String errorAddingLibrary(String error) {
    return '添加库时出错：$error';
  }

  @override
  String get librariesScannedSuccessfully => '库扫描成功';

  @override
  String errorScanningLibraries(String error) {
    return '扫描库时出错：$error';
  }

  @override
  String get noActiveRemoteProviders => '没有活动的远程提供商可索引';

  @override
  String indexedRemoteProviders(int count) {
    return '已索引 $count 个远程提供商';
  }

  @override
  String errorIndexingRemoteProviders(String error) {
    return '索引远程提供商时出错：$error';
  }

  @override
  String get serverUrl => '服务器URL';

  @override
  String get serverUrlHint => 'https://your-jellyfin-server.com';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get add => '添加';

  @override
  String get allFieldsRequired => '所有字段都是必填的';

  @override
  String addedRemoteProvider(String url) {
    return '已添加远程提供商：$url';
  }

  @override
  String errorAddingProvider(String error) {
    return '添加提供商时出错：$error';
  }

  @override
  String get confirmResetTrackDatabase =>
      '这将永久删除数据库中的所有曲目，并移除所有缓存的音乐文件和专辑封面。此操作无法撤销。\n\n您确定要继续吗？';

  @override
  String get trackDatabaseReset => '曲目数据库已重置';

  @override
  String errorResettingDatabase(String error) {
    return '重置数据库时出错：$error';
  }

  @override
  String get noTracksInAlbum => '此专辑中没有曲目';

  @override
  String get playAll => '播放全部';

  @override
  String get addToQueue => '添加到队列';

  @override
  String get noTracksInPlaylist => '此播放列表中没有曲目';

  @override
  String get noAlbumsFound => '未找到专辑';

  @override
  String get createOne => '创建一个';

  @override
  String get addNewPlaylist => '添加新播放列表';

  @override
  String get newPlaylist => '新播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get create => '创建';

  @override
  String get noPlaylistsYet => '还没有播放列表';

  @override
  String get queue => '队列';

  @override
  String get appSettings => '应用设置';

  @override
  String get appSettingsDescription => '配置应用范围的设置和偏好。';

  @override
  String get language => '语言';

  @override
  String get languageDescription => '选择应用语言。';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get settingsTitle => '设置';

  @override
  String get tracks => '曲目';

  @override
  String get albums => '专辑';

  @override
  String get playlists => '播放列表';

  @override
  String get addRemoteProviderDialog => '添加远程提供商';

  @override
  String get imported => '已导入';

  @override
  String get lyricsLines => '歌词';

  @override
  String get createdAt => '创建于';
}
