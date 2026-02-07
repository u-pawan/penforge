import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recording_service.dart';

/// Provider for the RecordingService
///
/// This makes the RecordingService available throughout the app.
/// Any widget can access the recording functionality using:
///   ref.watch(recordingProvider)        - to get the current state
///   ref.read(recordingProvider.notifier) - to call methods like startRecording()
final recordingProvider = NotifierProvider<RecordingService, RecordingState>(
  () {
    return RecordingService();
  },
);

/// Convenience provider to check if currently recording
///
/// Usage: final isRecording = ref.watch(isRecordingProvider);
final isRecordingProvider = Provider<bool>((ref) {
  final state = ref.watch(recordingProvider);
  return state.status == RecordingStatus.recording;
});

/// Convenience provider to check if processing
///
/// Usage: final isProcessing = ref.watch(isProcessingProvider);
final isProcessingProvider = Provider<bool>((ref) {
  final state = ref.watch(recordingProvider);
  return state.status == RecordingStatus.processing;
});
