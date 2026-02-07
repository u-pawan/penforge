import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_prompt.dart';
import 'features/recording/mic_button.dart';

/// The main app widget
///
/// This is the entry point of the UI. It:
/// 1. Sets up the theme (colors, fonts)
/// 2. Handles authentication state
/// 3. Shows appropriate screen based on login status
class PenForgeApp extends ConsumerWidget {
  const PenForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // App title shown in task switcher
      title: 'PenForge',

      // Theme configuration - this sets up colors for the entire app
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo/purple color
          brightness: Brightness.light,
        ),
        // Nice rounded buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // Dark mode theme (optional - can enable later)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),

      // Use system setting for light/dark mode
      themeMode: ThemeMode.system,

      // Choose which screen to show based on auth state
      home: authState.when(
        loading: () => const SplashScreen(),
        error: (error, stackTrace) => const ErrorScreen(),
        data: (user) {
          if (user == null) {
            // No user yet, trigger anonymous sign in
            ref.read(authControllerProvider).signInAnonymously();
            return const SplashScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}

/// Shown while the app is loading/initializing
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "PenForge",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Setting up...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Shown when something goes wrong during initialization
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              "Something went wrong",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please restart the app",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main home screen with recording functionality
///
/// This screen shows:
/// - Welcome message
/// - Large microphone button for recording
/// - Sign-in prompt for anonymous users
/// - (Later) List of saved notes
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isAnonymous = user?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PenForge"),
        centerTitle: true,
        actions: [
          // Show sign-in badge for anonymous users
          if (isAnonymous)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const LoginPrompt(),
                );
              },
              icon: const Icon(Icons.person_outline),
              label: const Text("Sign in"),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Welcome section at the top
            const SizedBox(height: 20),
            Text(
              isAnonymous ? "Welcome to PenForge! 👋" : "Welcome back! 🎉",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Transform your voice into polished text",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            // Main recording area
            const Expanded(
              child: Center(
                child: MicButton(
                  onRecordingComplete: _onRecordingComplete,
                  onError: _onRecordingError,
                ),
              ),
            ),

            // Sign-in prompt at the bottom for anonymous users
            if (isAnonymous) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Sign in to save your notes across devices",
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const LoginPrompt(),
                        );
                      },
                      child: const Text("Sign in"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Called when a recording is successfully completed
void _onRecordingComplete(String filePath) {
  // TODO: Upload to Firebase Storage and process with AI
  debugPrint('Recording saved to: $filePath');
}

/// Called when there's an error during recording
void _onRecordingError(String error) {
  debugPrint('Recording error: $error');
}
