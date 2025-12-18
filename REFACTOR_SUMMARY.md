# GroovyBox Track Repository Refactor Summary

## Overview
Successfully refactored the `lib/data/track_repository.dart` to support more settings including in-place indexing and folder watching functionality.

## Key Changes Made

### 1. Database Schema Updates (`lib/data/db.dart`)
- Added `WatchFolders` table for managing watch folders
- Added `AppSettings` table for storing app preferences
- Updated database schema version to 6
- Added proper migrations for new tables

### 2. Settings Provider (`lib/providers/settings_provider.dart`)
- Created comprehensive settings management with Riverpod
- Added `ImportMode` enum (Copy vs In-place)
- Added auto-scan and watch-for-changes settings
- Added supported audio formats configuration
- Persistent storage using SharedPreferences

### 3. Watch Folder Provider (`lib/providers/watch_folder_provider.dart`)
- Created service for managing watch folders
- Added database operations for CRUD operations
- Simplified implementation avoiding complex watcher issues
- Added folder scanning functionality
- Added missing track cleanup

### 4. Track Repository Refactor (`lib/data/track_repository.dart`)
- **Major Changes:**
  - Split `importFiles` into mode-specific methods
  - `_importFilesWithCopy`: Original behavior (copies files to internal storage)
  - `_importFilesInPlace`: New behavior (indexes files in original location)
  - Added `scanDirectory` method for folder scanning
  - Added `scanWatchFolders` method for bulk scanning
  - Added file event handlers (`addFileFromWatch`, `removeFileFromWatch`, `updateFileFromWatch`)
  - Added `cleanupMissingTracks` for maintaining database integrity
  - Updated `deleteTrack` to handle in-place vs copied files correctly

### 5. Settings UI (`lib/ui/screens/settings_screen.dart`)
- Created comprehensive settings interface
- Import mode selection (Copy vs In-place)
- Auto-scan and watch-for-changes toggles
- Watch folders management section
- Supported formats display
- Integration with new providers

### 6. Dependencies (`pubspec.yaml`)
- Added `watcher: ^1.2.0` for file system monitoring
- Added `shared_preferences: ^2.3.5` for settings persistence

## New Functionality

### Import Modes
1. **Copy Mode (Default):**
   - Original behavior maintained
   - Files copied to internal music directory
   - Safe file management
   - Suitable for mobile devices

2. **In-place Mode:**
   - Files indexed in original location
   - No additional storage usage
   - Preserves original file organization
   - Suitable for desktop/storage-rich environments

### Watch Folder Features
- Add/remove watch folders
- Toggle active/inactive status
- Bulk scanning of all active folders
- Automatic cleanup of missing tracks
- Support for recursive scanning

### Settings Management
- Persistent storage of user preferences
- Auto-scan scheduling
- File change monitoring toggle
- Configurable audio formats

## Usage Examples

### Switch to In-place Indexing
```dart
// Update settings to use in-place indexing
ref.read(settingsProvider.notifier).setImportMode(ImportMode.inplace);
```

### Add Watch Folder
```dart
// Add a folder to watch list
final watchService = ref.read(watchFolderServiceProvider);
await watchService.addWatchFolder('/path/to/music', name: 'My Music');
```

### Scan Watch Folders
```dart
// Scan all active watch folders
final trackRepo = ref.read(trackRepositoryProvider);
await trackRepo.scanWatchFolders();
```

### Cleanup Missing Tracks
```dart
// Remove tracks that no longer exist
final trackRepo = ref.read(trackRepositoryProvider);
await trackRepo.cleanupMissingTracks();
```

## Benefits

### User Experience
- Flexible import options for different use cases
- Automatic library maintenance
- Real-time folder monitoring capabilities
- Preserved file organization when desired

### Performance
- Efficient database operations
- Selective file scanning
- Proper resource cleanup
- Minimal storage impact for in-place mode

### Maintainability
- Clear separation of concerns
- Modular provider architecture
- Comprehensive error handling
- Extensible design for future features

## Future Enhancements

### Potential Additions
1. Real-time file watching implementation
2. Advanced file format detection
3. Folder exclusion/inclusion patterns
4. Metadata caching for performance
5. Batch operations optimization
6. Conflict resolution for duplicate files

### UI Improvements
1. Watch folder management interface
2. Import progress indicators
3. Folder scanning status
4. Settings organization and search
5. Conflict resolution dialogs

## Migration Guide

### For Existing Users
- Current behavior preserved (copy mode by default)
- Manual switch to in-place mode available
- Existing copied files unaffected
- Gradual migration possible

### Recommended Workflow
1. Start with copy mode for testing
2. Add watch folders in in-place mode
3. Enable auto-scan when comfortable
4. Use cleanup to maintain library

## Technical Notes

### Database Considerations
- Unique path constraint ensures no duplicates
- Cascade deletion maintains referential integrity
- Proper indexing on path for performance
- Migration handles existing installations

### File System Safety
- Existence checks before operations
- Graceful error handling
- Safe disposal of file watchers
- Album art always stored internally

### Memory Management
- Lazy loading of watch folders
- Efficient streaming for large libraries
- Proper cleanup of resources
- Minimal memory footprint

## Testing Recommendations

### Unit Tests
- Test import mode switching
- Test watch folder operations
- Test file event handling
- Test cleanup functionality
- Test settings persistence

### Integration Tests
- Test full import workflows
- Test settings changes
- Test database migrations
- Test file system scenarios

### Edge Cases
- Large file collections
- Network storage scenarios
- Permission denials
- File system errors
- Corrupted metadata

This refactor provides a solid foundation for enhanced music library management while maintaining backward compatibility and enabling powerful new features.
