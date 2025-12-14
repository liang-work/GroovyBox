import 'package:flutter/material.dart';
import 'screens/library_screen.dart';
import 'widgets/mini_player.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            child: LibraryScreen(),
            // Note: LibraryScreen might need padding at bottom to avoid occlusion by mini player
            // We can wrap LibraryScreen content or handle it there.
            // For now, let's just place it.
          ),

          // Mini Player
          Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}
