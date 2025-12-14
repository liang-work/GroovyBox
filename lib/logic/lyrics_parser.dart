import 'dart:convert';

/// Represents a single line of lyrics with optional timing.
class LyricsLine {
  final int? timeMs; // Time in milliseconds, null for plaintext
  final String text;

  LyricsLine({this.timeMs, required this.text});

  Map<String, dynamic> toJson() => {'time': timeMs, 'text': text};

  factory LyricsLine.fromJson(Map<String, dynamic> json) =>
      LyricsLine(timeMs: json['time'] as int?, text: json['text'] as String);
}

/// Represents parsed lyrics data.
class LyricsData {
  final String type; // 'timed' or 'plain'
  final List<LyricsLine> lines;

  LyricsData({required this.type, required this.lines});

  Map<String, dynamic> toJson() => {
    'type': type,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  factory LyricsData.fromJson(Map<String, dynamic> json) => LyricsData(
    type: json['type'] as String,
    lines: (json['lines'] as List)
        .map((l) => LyricsLine.fromJson(l as Map<String, dynamic>))
        .toList(),
  );

  String toJsonString() => jsonEncode(toJson());

  static LyricsData fromJsonString(String json) =>
      LyricsData.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

/// Parser for various lyrics file formats.
class LyricsParser {
  /// Parse LRC format lyrics.
  /// Format: [mm:ss.xx] Lyrics text
  static LyricsData parseLrc(String content) {
    final lines = <LyricsLine>[];
    final regex = RegExp(r'\[(\d+):(\d+)\.?(\d+)?\](.*)');

    for (final line in content.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.tryParse(match.group(3) ?? '0') ?? 0;
        final text = match.group(4)?.trim() ?? '';

        // Convert to milliseconds
        final timeMs =
            (minutes * 60 * 1000) +
            (seconds * 1000) +
            (centiseconds * 10); // centiseconds to ms

        if (text.isNotEmpty) {
          lines.add(LyricsLine(timeMs: timeMs, text: text));
        }
      }
    }

    // Sort by time
    lines.sort((a, b) => (a.timeMs ?? 0).compareTo(b.timeMs ?? 0));

    return LyricsData(type: 'timed', lines: lines);
  }

  /// Parse SRT (SubRip) format.
  /// Format:
  /// 1
  /// 00:00:12,500 --> 00:00:15,000
  /// Lyrics text
  static LyricsData parseSrt(String content) {
    final lines = <LyricsLine>[];
    final blocks = content.split(RegExp(r'\n\s*\n'));
    final timeRegex = RegExp(
      r'(\d+):(\d+):(\d+)[,.](\d+)\s*-->\s*\d+:\d+:\d+[,.]?\d*',
    );

    for (final block in blocks) {
      final blockLines = block.trim().split('\n');
      if (blockLines.length >= 2) {
        // Find timestamp line
        for (int i = 0; i < blockLines.length; i++) {
          final match = timeRegex.firstMatch(blockLines[i]);
          if (match != null) {
            final hours = int.parse(match.group(1)!);
            final minutes = int.parse(match.group(2)!);
            final seconds = int.parse(match.group(3)!);
            final millis = int.parse(match.group(4)!.padRight(3, '0'));

            final timeMs =
                (hours * 3600 * 1000) +
                (minutes * 60 * 1000) +
                (seconds * 1000) +
                millis;

            // Text is everything after the timestamp line
            final text = blockLines.sublist(i + 1).join(' ').trim();
            if (text.isNotEmpty) {
              lines.add(LyricsLine(timeMs: timeMs, text: text));
            }
            break;
          }
        }
      }
    }

    // Sort by time
    lines.sort((a, b) => (a.timeMs ?? 0).compareTo(b.timeMs ?? 0));

    return LyricsData(type: 'timed', lines: lines);
  }

  /// Parse plaintext lyrics (no timing).
  static LyricsData parsePlaintext(String content) {
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => LyricsLine(text: l))
        .toList();

    return LyricsData(type: 'plain', lines: lines);
  }

  /// Auto-detect format and parse.
  static LyricsData parse(String content, String filename) {
    final lowerFilename = filename.toLowerCase();

    if (lowerFilename.endsWith('.lrc')) {
      return parseLrc(content);
    } else if (lowerFilename.endsWith('.srt')) {
      return parseSrt(content);
    } else {
      // Check if content looks like LRC
      if (RegExp(r'\[\d+:\d+').hasMatch(content)) {
        return parseLrc(content);
      }
      // Check if content looks like SRT
      if (RegExp(r'\d+:\d+:\d+[,.]').hasMatch(content)) {
        return parseSrt(content);
      }
      // Default to plaintext
      return parsePlaintext(content);
    }
  }
}
