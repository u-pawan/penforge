import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// What the recording service is currently doing
enum RecordingStatus {
  idle, // Not doing anything
  recording, // Actively recording audio
  processing, // Uploading or processing
  error, // Something went wrong
}

/// State class to hold recording information
class RecordingState {
  final RecordingStatus status;
  final String? filePath;
  final String? errorMessage;
  final Duration duration;

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.filePath,
    this.errorMessage,
    this.duration = Duration.zero,
  });

  RecordingState copyWith({
    RecordingStatus? status,
    String? filePath,
    String? errorMessage,
    Duration? duration,
  }) {
    return RecordingState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
    );
  }
}

/// Service that handles all audio recording functionality
///
/// This class is like a helper that knows how to:
/// 1. Ask for microphone permission
/// 2. Start/stop recording
/// 3. Save the audio file
///
/// Uses Riverpod 3.x Notifier pattern
class RecordingService extends Notifier<RecordingState> {
  // The recorder object from the 'record' package
  late final AudioRecorder _recorder;

  @override
  RecordingState build() {
    // Initialize the recorder
    _recorder = AudioRecorder();

    // Clean up when the provider is disposed
    ref.onDispose(() {
      _recorder.dispose();
    });

    return const RecordingState();
  }

  /// Check if we have permission to use the microphone
  ///
  /// The record package handles permissions internally.
  /// This shows a popup asking "Allow microphone access?"
  Future<bool> requestPermission() async {
    // hasPermission() both checks and requests permission
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  ///
  /// Returns true if recording started successfully
  Future<bool> startRecording() async {
    try {
      // First, check permission (record package handles this internally)
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Microphone permission denied',
        );
        return false;
      }

      // Get the directory where we can save files
      final directory = await getApplicationDocumentsDirectory();

      // Create a unique filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/recording_$timestamp.m4a';

      // Configure recording settings
      // - AAC codec is widely supported
      // - m4a container works on both Android and iOS
      const config = RecordConfig(
        encoder:
            AudioEncoder.aacLc, // AAC Low Complexity - good quality, small size
        sampleRate: 44100, // CD quality
        bitRate: 128000, // 128 kbps - good for voice
      );

      // Start the actual recording
      await _recorder.start(config, path: filePath);

      // Update our state to show we're recording
      state = RecordingState(
        status: RecordingStatus.recording,
        filePath: filePath,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to start recording: $e',
      );
      return false;
    }
  }

  /// Stop recording and return the file path
  ///
  /// Returns the path to the saved audio file, or null if failed
  Future<String?> stopRecording() async {
    try {
      // Stop the recorder - this saves the file
      final path = await _recorder.stop();

      if (path != null) {
        // Verify the file exists
        final file = File(path);
        if (await file.exists()) {
          state = state.copyWith(status: RecordingStatus.idle, filePath: path);
          return path;
        }
      }

      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Recording file not found',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to stop recording: $e',
      );
      return null;
    }
  }

  /// Cancel the current recording without saving
  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
      state = const RecordingState(status: RecordingStatus.idle);
    } catch (e) {
      // Ignore errors when canceling
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Set status to processing (used when uploading)
  void setProcessing() {
    state = state.copyWith(status: RecordingStatus.processing);
  }

  /// Reset to idle state
  void reset() {
    state = const RecordingState(status: RecordingStatus.idle);
  }
}
