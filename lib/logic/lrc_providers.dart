import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';

/// Represents lyrics data
class Lyrics {
  final String? synced; // LRC format synced lyrics
  final String? plain; // Plain text lyrics

  Lyrics({this.synced, this.plain});

  Lyrics withSynced(String? s) => Lyrics(synced: s, plain: plain);
}

/// Abstract base class for LRC providers
abstract class LrcProvider {
  late final http.Client session;

  LrcProvider() {
    session = http.Client();
  }

  String get name;

  /// Search and retrieve lyrics by search term (usually title + artist)
  Future<Lyrics?> getLrc(String searchTerm);
}

/// Musixmatch LRC provider
class MusixmatchProvider extends LrcProvider {
  static const String rootUrl = "https://apic-desktop.musixmatch.com/ws/1.1/";

  final String? lang;
  final bool enhanced;
  String? token;

  MusixmatchProvider({this.lang, this.enhanced = false});

  @override
  String get name => 'Musixmatch';

  Future<http.Response> _get(
    String action,
    List<MapEntry<String, String>> query,
  ) async {
    if (action != "token.get" && token == null) {
      await _getToken();
    }
    query.add(MapEntry("app_id", "web-desktop-app-v1.0"));
    if (token != null) {
      query.add(MapEntry("usertoken", token!));
    }
    final t = DateTime.now().millisecondsSinceEpoch.toString();
    query.add(MapEntry("t", t));
    final url = rootUrl + action;
    return await session.get(Uri.parse(url), headers: Map.fromEntries(query));
  }

  Future<void> _getToken() async {
    final dir = await path_provider.getApplicationSupportDirectory();
    final tokenPath = path.join(
      dir.path,
      "syncedlyrics",
      "musixmatch_token.json",
    );
    final file = File(tokenPath);
    if (file.existsSync()) {
      final data = jsonDecode(file.readAsStringSync());
      final cachedToken = data['token'];
      final expirationTime = data['expiration_time'];
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (cachedToken != null &&
          expirationTime != null &&
          currentTime < expirationTime) {
        token = cachedToken;
        return;
      }
    }
    // Token not cached or expired, fetch new token
    final d = await _get("token.get", [MapEntry("user_language", "en")]);
    if (d.statusCode == 401) {
      await Future.delayed(Duration(seconds: 10));
      return await _getToken();
    }
    final newToken = jsonDecode(d.body)["message"]["body"]["user_token"];
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expirationTime = currentTime + 600; // 10 minutes
    token = newToken;
    final tokenData = {"token": newToken, "expiration_time": expirationTime};
    file.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(tokenData));
  }

  Future<Lyrics?> getLrcById(String trackId) async {
    var r = await _get("track.subtitle.get", [
      MapEntry("track_id", trackId),
      MapEntry("subtitle_format", "lrc"),
    ]);
    if (lang != null) {
      final rTr = await _get("crowd.track.translations.get", [
        MapEntry("track_id", trackId),
        MapEntry("subtitle_format", "lrc"),
        MapEntry("translation_fields_set", "minimal"),
        MapEntry("selected_language", lang!),
      ]);
      final bodyTr = jsonDecode(rTr.body)["message"]["body"];
      if (bodyTr["translations_list"] == null ||
          (bodyTr["translations_list"] as List).isEmpty) {
        throw Exception("Couldn't find translations");
      }
      // Translation handling would need full implementation
    }
    if (r.statusCode != 200) return null;
    final body = jsonDecode(r.body)["message"]["body"];
    if (body == null) return null;
    final lrcStr = body["subtitle"]["subtitle_body"];
    final lrc = Lyrics(synced: lrcStr);
    return lrc;
  }

  Future<Lyrics?> getLrcWordByWord(String trackId) async {
    var lrc = Lyrics();
    final r = await _get("track.richsync.get", [MapEntry("track_id", trackId)]);
    if (r.statusCode == 200 &&
        jsonDecode(r.body)["message"]["header"]["status_code"] == 200) {
      final lrcRaw = jsonDecode(
        r.body,
      )["message"]["body"]["richsync"]["richsync_body"];
      final data = jsonDecode(lrcRaw);
      String lrcStr = "";
      if (data is List) {
        for (final i in data) {
          lrcStr += "[${formatTime(i['ts'])}] ";
          if (i['l'] is List) {
            for (final l in i['l']) {
              final t = formatTime(
                double.parse(i['ts'].toString()) +
                    double.parse(l['o'].toString()),
              );
              lrcStr += "<$t> ${l['c']} ";
            }
          }
          lrcStr += "\n";
        }
      }
      lrc = lrc.withSynced(lrcStr);
    }
    return lrc;
  }

  @override
  Future<Lyrics?> getLrc(String searchTerm) async {
    final r = await _get("track.search", [
      MapEntry("q", searchTerm),
      MapEntry("page_size", "5"),
      MapEntry("page", "1"),
    ]);
    final statusCode = jsonDecode(r.body)["message"]["header"]["status_code"];
    if (statusCode != 200) return null;
    final body = jsonDecode(r.body)["message"]["body"];
    if (body == null || !(body is Map)) return null;
    final tracks = body["track_list"];
    if (tracks == null || !(tracks is List) || tracks.isEmpty) return null;

    // Simple "best match" - first track
    final track = tracks.firstWhere((t) => true, orElse: () => null);
    if (track == null) return null;
    final trackId = track["track"]["track_id"];
    if (enhanced) {
      final lrc = await getLrcWordByWord(trackId);
      if (lrc != null && lrc.synced != null) {
        return lrc;
      }
    }
    return await getLrcById(trackId);
  }
}

/// NetEase provider
class NetEaseProvider extends LrcProvider {
  static const String apiEndpointMetadata =
      "https://music.163.com/api/search/pc";
  static const String apiEndpointLyrics =
      "https://music.163.com/api/song/lyric";

  static const String cookie =
      "NMTID=00OAVK3xqDG726ITU6jopU6jF2yMk0AAAGCO8l1BA; JSESSIONID-WYYY=8KQo11YK2GZP45RMlz8Kn80vHZ9%2FGvwzRKQXXy0iQoFKycWdBlQjbfT0MJrFa6hwRfmpfBYKeHliUPH287JC3hNW99WQjrh9b9RmKT%2Fg1Exc2VwHZcsqi7ITxQgfEiee50po28x5xTTZXKoP%2FRMctN2jpDeg57kdZrXz%2FD%2FWghb%5C4DuZ%3A1659124633932; _iuqxldmzr_=32; _ntes_nnid=0db6667097883aa9596ecfe7f188c3ec,1659122833973; _ntes_nuid=0db6667097883aa9596ecfe7f188c3ec; WNMCID=xygast.1659122837568.01.0; WEVNSM=1.0.0; WM_NI=CwbjWAFbcIzPX3dsLP%2F52VB%2Bxr572gmqAYwvN9KU5X5f1nRzBYl0SNf%2BV9FTmmYZy%2FoJLADaZS0Q8TrKfNSBNOt0HLB8rRJh9DsvMOT7%2BCGCQLbvlWAcJBJeXb1P8yZ3RHA%3D; WM_NIKE=9ca17ae2e6ffcda170e2e6ee90c65b85ae87b9aa5483ef8ab3d14a939e9a83c459959caeadce47e991fbaee82af0fea7c3b92a81a9ae8aabb64b86beadaaf95c9c437e2a3; WM_TID=AAkRFnl03RdABEBEQFOBWHCPOeMra4IL; playerid=94262567";

  @override
  String get name => 'NetEase';

  Future<Map<String, dynamic>?> searchTrack(String searchTerm) async {
    final params = {"limit": "10", "type": "1", "offset": "0", "s": searchTerm};
    final response = await session.get(
      Uri.parse(apiEndpointMetadata).replace(queryParameters: params),
      headers: {"cookie": cookie},
    );
    // Update the session cookies from the new sent cookies for the next request.
    // In http package, we can set it, but for simplicity, pass to next call
    final results = jsonDecode(response.body)["result"]["songs"];
    if (results == null || results.isEmpty) return null;
    // Simple best match - first track
    return results[0];
  }

  Future<Lyrics?> getLrcById(String trackId) async {
    final params = {"id": trackId, "lv": "1"};
    final response = await session.get(
      Uri.parse(apiEndpointLyrics).replace(queryParameters: params),
      headers: {"cookie": cookie},
    );
    final data = jsonDecode(response.body);
    final lrc = Lyrics(synced: data["lrc"]["lyric"]);
    return lrc;
  }

  @override
  Future<Lyrics?> getLrc(String searchTerm) async {
    final track = await searchTrack(searchTerm);
    if (track == null) return null;
    return await getLrcById(track["id"].toString());
  }
}

// Utility function
String formatTime(dynamic time) {
  final seconds = time.toInt();
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  final centiseconds = ((time - seconds) * 100).toInt();
  return '$minutes:$remainingSeconds.${centiseconds.toString().padLeft(2, '0')}';
}

// Extension for List<MapEntry>
extension MapEntryList on List<MapEntry<String, String>> {
  Map<String, String> toMap() {
    return Map.fromEntries(this);
  }
}
