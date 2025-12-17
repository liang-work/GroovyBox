import 'dart:io';

import 'package:flutter/material.dart';
import 'package:groovybox/data/db.dart' as db;

class TrackTile extends StatelessWidget {
  final db.Track track;
  final VoidCallback? onTap;
  final bool isPlaying;
  final bool showTrailingIcon;
  final VoidCallback? onTrailingPressed;
  final Widget? leading;
  final EdgeInsets? padding;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.isPlaying = false,
    this.leading,
    this.padding,
    this.showTrailingIcon = false,
    this.onTrailingPressed,
  });

  String _formatDuration(int? durationMs) {
    if (durationMs == null) return '--:--';
    final d = Duration(milliseconds: durationMs);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isPlaying
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?leading,
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  image: track.artUri != null
                      ? DecorationImage(
                          image: FileImage(File(track.artUri!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: track.artUri == null
                    ? const Icon(Icons.music_note, color: Colors.white54)
                    : null,
              ),
            ),
          ],
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            color: isPlaying
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${track.artist ?? 'Unknown Artist'} • ${_formatDuration(track.duration)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: showTrailingIcon
            ? IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onTrailingPressed,
              )
            : isPlaying
            ? Icon(
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
