import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recording_provider.dart';
import 'recording_service.dart';

/// A large microphone button that shows recording status
///
/// This widget:
/// - Shows a mic icon when idle
/// - Pulses/animates when recording
/// - Shows a spinner when processing
/// - Changes color based on state
class MicButton extends ConsumerStatefulWidget {
  /// Called when recording is complete with the file path
  final void Function(String filePath)? onRecordingComplete;

  /// Called when there's an error
  final void Function(String error)? onError;

  const MicButton({super.key, this.onRecordingComplete, this.onError});

  @override
  ConsumerState<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends ConsumerState<MicButton>
    with SingleTickerProviderStateMixin {
  // Animation controller for the pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Set up the pulsing animation
    // This creates a smooth scale effect: 1.0 -> 1.15 -> 1.0
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this, // 'this' because we use SingleTickerProviderStateMixin
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Handle the button tap
  Future<void> _onTap() async {
    final recordingService = ref.read(recordingProvider.notifier);
    final currentState = ref.read(recordingProvider);

    // If currently recording, stop it
    if (currentState.status == RecordingStatus.recording) {
      _pulseController.stop();
      _pulseController.reset();

      final filePath = await recordingService.stopRecording();

      if (filePath != null) {
        widget.onRecordingComplete?.call(filePath);
      } else {
        widget.onError?.call('Failed to save recording');
      }
    }
    // If idle, start recording
    else if (currentState.status == RecordingStatus.idle) {
      final started = await recordingService.startRecording();

      if (started) {
        // Start the pulsing animation
        _pulseController.repeat(reverse: true);
      } else {
        widget.onError?.call(
          currentState.errorMessage ?? 'Failed to start recording',
        );
      }
    }
    // If processing, do nothing (button is disabled)
  }

  @override
  Widget build(BuildContext context) {
    // Watch the recording state to rebuild when it changes
    final recordingState = ref.watch(recordingProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The main button with animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final isRecording =
                recordingState.status == RecordingStatus.recording;

            return Transform.scale(
              // Only apply pulse animation when recording
              scale: isRecording ? _pulseAnimation.value : 1.0,
              child: child,
            );
          },
          child: _buildButton(recordingState),
        ),

        const SizedBox(height: 16),

        // Status text below the button
        _buildStatusText(recordingState),
      ],
    );
  }

  /// Build the actual button with appropriate styling
  Widget _buildButton(RecordingState state) {
    final isRecording = state.status == RecordingStatus.recording;
    final isProcessing = state.status == RecordingStatus.processing;
    final isError = state.status == RecordingStatus.error;

    // Choose colors based on state
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    if (isRecording) {
      backgroundColor = Colors.red;
      iconColor = Colors.white;
      icon = Icons.stop_rounded;
    } else if (isProcessing) {
      backgroundColor = Colors.orange;
      iconColor = Colors.white;
      icon = Icons.hourglass_top_rounded;
    } else if (isError) {
      backgroundColor = Colors.grey;
      iconColor = Colors.red;
      icon = Icons.mic_off_rounded;
    } else {
      // Idle state
      backgroundColor = Theme.of(context).primaryColor;
      iconColor = Colors.white;
      icon = Icons.mic_rounded;
    }

    return GestureDetector(
      onTap: isProcessing ? null : _onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: isRecording ? 8 : 2,
            ),
          ],
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(icon, size: 40, color: iconColor),
        ),
      ),
    );
  }

  /// Build the status text below the button
  Widget _buildStatusText(RecordingState state) {
    String text;
    Color color;

    switch (state.status) {
      case RecordingStatus.idle:
        text = 'Tap to record';
        color = Colors.grey;
        break;
      case RecordingStatus.recording:
        text = 'Recording... Tap to stop';
        color = Colors.red;
        break;
      case RecordingStatus.processing:
        text = 'Processing...';
        color = Colors.orange;
        break;
      case RecordingStatus.error:
        text = state.errorMessage ?? 'Error occurred';
        color = Colors.red;
        break;
    }

    return Text(
      text,
      style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
    );
  }
}
