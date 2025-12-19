import 'package:flutter/foundation.dart';
import 'package:groovybox/data/db.dart';
import 'package:groovybox/providers/db_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';

// Simple remote provider using Riverpod
final remoteProvidersProvider = FutureProvider<List<RemoteProvider>>((
  ref,
) async {
  final db = ref.read(databaseProvider);
  return await (db.select(
    db.remoteProviders,
  )..orderBy([(t) => OrderingTerm(expression: t.addedAt)])).get();
});

final activeRemoteProvidersProvider = Provider<List<RemoteProvider>>((ref) {
  final remoteProvidersAsync = ref.watch(remoteProvidersProvider);
  return remoteProvidersAsync.when(
    data: (providers) =>
        providers.where((provider) => provider.isActive).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

class RemoteProviderService {
  final Ref ref;

  RemoteProviderService(this.ref);

  Future<void> addRemoteProvider(
    String serverUrl,
    String username,
    String password, {
    String? name,
  }) async {
    final db = ref.read(databaseProvider);
    final providerName = name ?? Uri.parse(serverUrl).host;

    await db
        .into(db.remoteProviders)
        .insert(
          RemoteProvidersCompanion.insert(
            serverUrl: serverUrl,
            name: providerName,
            username: username,
            password: password,
          ),
        );

    // Invalidate the provider to refresh UI
    ref.invalidate(remoteProvidersProvider);
  }

  Future<void> removeRemoteProvider(int providerId) async {
    final db = ref.read(databaseProvider);

    await (db.delete(
      db.remoteProviders,
    )..where((t) => t.id.equals(providerId))).go();

    // Invalidate the provider to refresh UI
    ref.invalidate(remoteProvidersProvider);
  }

  Future<void> toggleRemoteProvider(int providerId, bool isActive) async {
    final db = ref.read(databaseProvider);

    await (db.update(db.remoteProviders)..where((t) => t.id.equals(providerId)))
        .write(RemoteProvidersCompanion(isActive: Value(isActive)));

    // Invalidate the provider to refresh UI
    ref.invalidate(remoteProvidersProvider);
  }

  Future<void> indexRemoteProvider(int providerId) async {
    final db = ref.read(databaseProvider);

    // Get provider details
    final provider = await (db.select(
      db.remoteProviders,
    )..where((t) => t.id.equals(providerId))).getSingleOrNull();

    if (provider == null) {
      throw Exception('Remote provider not found: $providerId');
    }

    if (!provider.isActive) {
      debugPrint('Provider $providerId is not active, skipping indexing');
      return;
    }

    try {
      // Create Jellyfin client
      final client = JellyfinDart(basePathOverride: provider.serverUrl);

      // Set device info
      client.setDeviceId('groovybox-${providerId}');
      client.setVersion('1.0.0');

      // Authenticate
      final userApi = client.getUserApi();
      final authResponse = await userApi.authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName(
          username: provider.username,
          pw: provider.password,
        ),
      );

      final token = authResponse.data?.accessToken;
      if (token == null) {
        throw Exception('Authentication failed for provider ${provider.name}');
      }

      client.setToken(token);

      // Fetch music items
      final itemsApi = client.getItemsApi();
      final musicItems = await itemsApi.getItems(
        includeItemTypes: [BaseItemKind.audio],
        recursive: true,
        fields: [
          ItemFields.path,
          ItemFields.mediaStreams,
          ItemFields.mediaSources,
          ItemFields.genres,
          ItemFields.tags,
          ItemFields.overview,
        ],
      );

      final items = musicItems.data?.items ?? [];

      // Convert to tracks and store
      for (final item in items) {
        await _addRemoteTrack(db, provider, item, token);
      }

      debugPrint('Indexed $items.length tracks from $provider.name');
    } catch (e) {
      debugPrint('Error indexing remote provider $provider.name: $e');
      rethrow;
    }
  }

  Future<void> _addRemoteTrack(
    AppDatabase db,
    RemoteProvider provider,
    BaseItemDto item,
    String token,
  ) async {
    // Generate streaming URL
    final streamUrl =
        '${provider.serverUrl}/Audio/${item.id}/stream.mp3?api_key=$token&static=true';

    // Extract metadata
    final title = item.name ?? 'Unknown Title';
    final artist =
        item.albumArtist ?? item.artists?.join(', ') ?? 'Unknown Artist';
    final album = item.album ?? 'Unknown Album';
    final duration =
        (item.runTimeTicks ?? 0) ~/ 10000; // Convert ticks to milliseconds

    // Check if track already exists
    final existingTrack = await (db.select(
      db.tracks,
    )..where((t) => t.path.equals(streamUrl))).getSingleOrNull();

    if (existingTrack != null) {
      // Update existing track
      await (db.update(
        db.tracks,
      )..where((t) => t.id.equals(existingTrack.id))).write(
        TracksCompanion(
          title: Value(title),
          artist: Value(artist),
          album: Value(album),
          duration: Value(duration),
          addedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // Insert new track
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              title: title,
              path: streamUrl, // Remote streaming URL
              artist: Value(artist),
              album: Value(album),
              duration: Value(duration),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }
}

// Provider for the service
final remoteProviderServiceProvider = Provider<RemoteProviderService>((ref) {
  return RemoteProviderService(ref);
});
